import re
import os
import torch
#import whisper
import tempfile
import wave
import json
import librosa
import noisereduce as nr
import argparse
from pydub import AudioSegment, silence
from transformers import AutoTokenizer, AutoModelForCausalLM
import logging
from collections import OrderedDict
from jiwer import wer
from pyannote.audio import Pipeline
import soundfile as sf
import shutil
import subprocess
from datetime import datetime, timedelta
from collections import Counter
from faster_whisper import WhisperModel
from pydub.utils import make_chunks
from concurrent.futures import ThreadPoolExecutor, as_completed
from difflib import get_close_matches
import threading
thread_local = threading.local()
import traceback


SUPPORTED_EXTENSIONS = ('.flac', '.wav', '.mp3', '.m4a', '.aac', '.ogg', '.webm', '.opus', '.mp4', '.mov', '.mkv', '.avi')
CHUNK_FOLDER = "chunks"

# Detects GPU type and suggests best Whisper model and token limit accordingly
def detect_gpu_and_optimize():
    """
    Detect the current GPU and return Whisper model + token limit.
    Returns: (gpu_name, whisper_model, token_limit)
    """
    if not torch.cuda.is_available():
        return "cpu", "small", 30
    device = torch.cuda.current_device()
    name = torch.cuda.get_device_name(device).lower()
    if "a10" in name:
        return "a10", "medium", 60
    elif "a100" in name:
        return "a100", "large", 120
    elif "h100" in name:
        return "h100", "turbo", 180
    return "unknown_gpu", "base", 60

def load_whisper_model_faster(model_name, gpu_id=0):
    """
    Loads a WhisperModel from faster-whisper for a specified GPU.

    Args:
        model_name (str): Name of the Whisper model to load.
        gpu_id (int): The GPU index to load the model on.

    Returns:
        WhisperModel: An instance of the loaded WhisperModel ready for transcription.
    """
    logging.info(f"[load_whisper_model_faster] Loading WhisperModel '{model_name}' on GPU {gpu_id}")
    return WhisperModel(
        model_name,
        device="cuda",
        device_index=gpu_id,
        compute_type="float16",
        cpu_threads=8
    )


# Converts input audio/video file to 16kHz, mono WAV format (Whisper compatible)
def convert_to_wav(input_path):
    """
    Converts any audio/video file into 16kHz, mono-channel WAV format using ffmpeg.

    Args:
        input_path (str): Path to the input file.

    Returns:
        str: Path to the converted WAV file or None on failure.
    """
    output_path = tempfile.mktemp(suffix=".wav")
    try:
        cmd = [
            "ffmpeg", "-y", "-threads", "4",
            "-i", input_path,
            "-ac", "1",
            "-ar", "16000",
            "-sample_fmt", "s16",
            output_path
        ]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    except Exception as e:
        logging.error(f"Chunk processing failed: {e}")
        return None
        logging.error(f"ffmpeg conversion failed on {input_path}: {e}")
        raise
    return output_path





def run_diarization(full_audio_path, hf_token, max_speakers=None):
    """
    Runs speaker diarization on the full audio file using PyAnnote's pre-trained pipeline.

    This function loads a HuggingFace diarization pipeline and applies it to the audio,
    optionally constraining the number of speakers. It logs and saves the diarization
    results to a debug JSON file for inspection.

    Args:
        full_audio_path (str): Path to the input audio file (must be supported by PyAnnote).
        hf_token (str): HuggingFace access token for loading the diarization model.
        max_speakers (int, optional): If provided, constrains diarization to a fixed number of speakers.

    Returns:
        list[Tuple[Segment, None, str]]: A list of diarized segments, each represented as a tuple:
            - track (Segment): Start and end time of the segment.
            - _: Reserved (not used, always None).
            - label (str): Speaker label (e.g., "SPEAKER_00", "SPEAKER_01").
    """

    logging.info(f"Running speaker diarization on: {full_audio_path}")
    try:
        pipeline = Pipeline.from_pretrained("pyannote/speaker-diarization-3.1", use_auth_token=hf_token)
        if torch.cuda.is_available():
            pipeline.to(torch.device("cuda"))

        if max_speakers:
            diarization = pipeline({"audio": full_audio_path}, num_speakers=max_speakers)
        else:
            diarization = pipeline({"audio": full_audio_path})

        global_segments = list(diarization.itertracks(yield_label=True))

        if not global_segments:
            logging.warning("Diarization returned an empty result.")
        else:
            output_dir = os.path.dirname(full_audio_path)
            debug_path = os.path.join(output_dir, "diarization_debug.json")
            debug_dump = [
                {"start": float(track.start), "end": float(track.end), "label": str(label)}
                for track, _, label in global_segments
            ]
            with open(debug_path, "w") as df:
                json.dump(debug_dump, df, indent=2)
            logging.info(f"Diarization returned {len(global_segments)} segments. Dumped to {debug_path}.")
            for track, _, label in global_segments:
                logging.info(f"Diarized segment: {track.start:.2f}s - {track.end:.2f}s -> {label}")

        return global_segments
    except Exception as e:
        logging.error(f"Diarization failed: {e}")
        return []




def assign_speakers_to_segments_from_global(chunk_path, segments, diarized_segments, chunk_offset_seconds):
    """
    Assign speaker labels to each Whisper segment by comparing midpoints to global diarization tracks.

    Args:
        chunk_path (str): Path to the audio chunk (not used directly but kept for interface consistency).
        segments (list): List of Whisper segments (dict or Segment object with 'start'/'end' or .start/.end).
        diarized_segments (list): List of (track, _, label) from pyannote speaker diarization.
        chunk_offset_seconds (float): Offset of this chunk in full audio timeline.

    Returns:
        list[str]: List of speaker labels (e.g., "Speaker 1", "Speaker 2", ...)
    """
    assigned_speakers = []

    for seg in segments:
        # Support both dict-style and object-style segments
        try:
            seg_start = seg['start']
            seg_end = seg['end']
        except TypeError:
            seg_start = seg.start
            seg_end = seg.end

        midpoint = float((seg_start + seg_end) / 2 + chunk_offset_seconds)
        match = None

        # Match midpoint against global diarized tracks
        for track, _, label in diarized_segments:
            if not (float(track.end) < seg_start + chunk_offset_seconds or float(track.start) > seg_end + chunk_offset_seconds):
                match = label
                break

        if not match:
            match = "SPEAKER_00"

        # Convert SPEAKER_00 → Speaker 1, etc.
        if match.startswith("SPEAKER_"):
            try:
                spk_number = int(match.split("_")[1])
                assigned_speakers.append(f"Speaker {spk_number + 1}")
            except (IndexError, ValueError):
                assigned_speakers.append("Speaker 1")
        else:
            assigned_speakers.append(match)

    logging.info(f"Speaker assignment breakdown: {Counter(assigned_speakers)}")
    return assigned_speakers



# Applies noise reduction using noisereduce (conservative settings)
def denoise_audio(input_file, output_file, prop_decrease=0.7):
    """
    Applies denoising using Demucs and noise reduction techniques.

    Args:
        input_file (str): Path to the input noisy audio.
        output_file (str): Output path for the denoised audio.
        prop_decrease (float): Aggressiveness of denoising.

    Returns:
        None
    """
    temp_dir = tempfile.mkdtemp()
    try:
        logging.info(f"Running Demucs on: {input_file}")
        demucs_cmd = f"python3 -m demucs.separate -d cuda -n htdemucs --two-stems=vocals -o \"{temp_dir}\" \"{input_file}\""
        subprocess.run(demucs_cmd, shell=True, check=True)

        base = os.path.splitext(os.path.basename(input_file))[0]
        vocals_path = os.path.join(temp_dir, "htdemucs", base, "vocals.wav")

        if not os.path.exists(vocals_path):
            raise FileNotFoundError(f"Demucs output not found: {vocals_path}")

        y, sr = librosa.load(vocals_path, sr=None)
        y_denoised = nr.reduce_noise(y=y, sr=sr, prop_decrease=prop_decrease, stationary=False)
        sf.write(output_file, y_denoised, sr)
        logging.info(f"Denoised file saved to: {output_file}")
    except Exception as e:
        logging.error(f"Denoising failed on {input_file}: {e}. Falling back to original.")
        shutil.copy(input_file, output_file)  # FALLBACK
    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)



# Calculates duration (in seconds) of the audio file using wave or pydub
def get_audio_duration(path):
    """
    Calculates duration of a WAV or general audio file.

    Args:
        path (str): File path to audio.

    Returns:
        float: Duration in seconds.
    """
    try:
        if path.endswith('.wav'):
            with wave.open(path, 'r') as f:
                frames = f.getnframes()
                rate = f.getframerate()
                return frames / float(rate)
        else:
            audio = AudioSegment.from_file(path)
            return len(audio) / 1000.0  # seconds
    except Exception as e:
        logging.error(f"Chunk processing failed: {e}")
        return None
        logging.warning(f"Failed to get duration of {path}: {e}")
        return 0
 

def fallback_fixed_chunks(audio, chunk_length_ms=30000):
    """
    Splits audio into fixed-length chunks (30s default).

    Args:
        audio (AudioSegment): Loaded audio object.
        chunk_length_ms (int): Length in milliseconds.

    Returns:
        list[AudioSegment]: List of chunks.
    """
    return make_chunks(audio, chunk_length_ms)


def smart_chunk_audio(audio_path, output_dir, model, language="en"):
    """
    Performs intelligent audio chunking based on speech segments detected by a transcription model.

    This function uses a transcription model (e.g., Whisper or faster-whisper) to identify
    speech segments in the audio file. Each segment is then extracted as a separate audio chunk
    and saved to the specified output directory.

    Args:
        audio_path (str): Path to the input audio file (any format supported by pydub/ffmpeg).
        output_dir (str): Directory where chunked audio files will be saved.
        model: Transcription model object with a `.transcribe()` method (must yield segments with `.start` and `.end` attributes).
        language (str, optional): Language code to guide transcription. Defaults to "en".

    Returns:
        list[Tuple[str, float]]: List of tuples containing:
            - chunk_path (str): Path to the exported audio chunk.
            - start_offset (float): Start time of the chunk in seconds.
    """
    logging.info("Running smart chunking...")

    segments_generator, _ = model.transcribe(audio_path, language=language, beam_size=5, word_timestamps=True)
    segments = list(segments_generator)
    audio = AudioSegment.from_file(audio_path)

    chunk_infos = []  # List of (chunk_path, start_offset)
    for i, seg in enumerate(segments):
        start = seg.start
        end = seg.end
        chunk_audio = audio[start * 1000:end * 1000]  # Convert to ms
        chunk_path = os.path.join(output_dir, f"chunk_{i:03d}.wav")
        chunk_audio.export(chunk_path, format="wav")
        chunk_infos.append((chunk_path, start))
        logging.info(f"Exported chunk: {chunk_path} ({start:.2f}s → {end:.2f}s)")

    return chunk_infos



# Converts and transcribes an audio file using Whisper model
def transcribe_file(model, audio_path):
    """
    Transcribes a WAV file using a Whisper model.

    Args:
        model (WhisperModel): Loaded Whisper model.
        audio_path (str): Path to WAV file.
        beam_size (int): Beam size for decoding.
        language (str): Optional forced language.

    Returns:
        tuple[list[dict], str]: List of segments and detected language.
    """
    try:
        wav_path = convert_to_wav(audio_path)

        segments_generator, info = model.transcribe(wav_path, beam_size=1, language=None)
        segments = list(segments_generator)
        text = " ".join([seg.text.strip() for seg in segments])
        os.remove(wav_path)

        detected_lang = info.language
        return text.strip(), detected_lang, segments
    except Exception as e:
        logging.error(f"Chunk processing failed: {e}")
        return None
        logging.error(f"Failed: {audio_path} — {e}")
        return "", "unknown", []


# Loads the summarization model (default: Mistral) from HuggingFace
def load_mistral_model(model_id, hf_token):
    """
    Loads a HuggingFace LLM model and tokenizer.

    Args:
        model_name (str): Name of model.

    Returns:
        tuple: (model, tokenizer)
    """
    if os.path.isdir(model_id):
        logging.info(f"Loading summarizer model from local path: {model_id}")
        tokenizer = AutoTokenizer.from_pretrained(model_id, use_auth_token=hf_token)
        model = AutoModelForCausalLM.from_pretrained(
            model_id,
            torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
            device_map="auto",
            use_auth_token=hf_token
        )
    else:
        logging.info(f"Loading summarizer model from HuggingFace: {model_id}")
        tokenizer = AutoTokenizer.from_pretrained(model_id, use_auth_token=hf_token)
        model = AutoModelForCausalLM.from_pretrained(
            model_id,
            torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
            device_map="auto",
            use_auth_token=hf_token
        )
    return model, tokenizer


# Splits long transcript into smaller LLM-compatible chunks based on token count
def split_into_chunks(text, tokenizer, max_tokens=3000):
    """
    Splits long text into overlapping token-aware chunks.

    Args:
        text (str): Input string.
        tokenizer: HuggingFace tokenizer.
        max_tokens (int): Max tokens per chunk.
        stride (int): Overlap for continuity.

    Returns:
        list[str]: List of text chunks.
    """
    words = text.split()
    chunks = []
    current = []
    for word in words:
        current.append(word)
        if len(tokenizer.encode(" ".join(current))) > max_tokens:
            chunks.append(" ".join(current[:-1]))
            current = [word]
    if current:
        chunks.append(" ".join(current))
    return chunks


# Summarizes a chunk of transcript using the loaded summarizer model
def summarize_with_mistral(model, tokenizer, text):
    """
    Summarizes text using an LLM like Mistral.

    Args:
        model: HuggingFace model.
        tokenizer: Corresponding tokenizer.
        text (str): Text to summarize.

    Returns:
        str: Summary string.
    """
    prompt = f"<s>[INST] Summarize the following meeting transcript into a concise list of key points, decisions, and action items:\n\n{text} [/INST]"
    inputs = tokenizer(prompt, return_tensors="pt", truncation=True, max_length=4096).to(model.device)
    with torch.no_grad():
        output = model.generate(**inputs, max_new_tokens=512)
    
    result = tokenizer.decode(output[0], skip_special_tokens=True)

    # Strip echoed prompt (everything before [/INST])
    if "[/INST]" in result:
        result = result.split("[/INST]", 1)[-1].strip()

    return result


# Main pipeline for one file: validate → denoise → chunk → transcribe → summarize → save outputs

def assign_speakers_to_segments(converted_path, segments, hf_token, max_speakers=None):
    """
    Runs full-audio diarization and assigns speakers to Whisper segments using midpoint matching.

    Args:
        converted_path (str): Path to audio file.
        segments (list): List of Whisper segments.
        hf_token (str): HuggingFace access token.
        max_speakers (int): Optional number of speakers to constrain diarization.

    Returns:
        list[str]: Speaker label per segment, normalized as "Speaker 1", "Speaker 2", etc.
    """
    logging.info(f"Running speaker diarization on: {converted_path}")
    
    try:
        pipeline = Pipeline.from_pretrained("pyannote/speaker-diarization-3.1", use_auth_token=hf_token)
        if torch.cuda.is_available():
            pipeline.to(torch.device("cuda"))

        global_diarized_segments = run_diarization(converted_path, hf_token, max_speakers, output_dir)

        diarized_segments = list(diarization.itertracks(yield_label=True))
        logging.info(f"First 5 diarized segments:")
        for i, (track, _, label) in enumerate(diarized_segments[:5]):
            logging.info(f"  {i}: {track.start:.2f} - {track.end:.2f} --> {label}")
        if not diarized_segments:
            logging.warning("No diarized speaker segments were found.")
            return ["Speaker 1"] * len(segments)

    except Exception as e:
        logging.error(f"Diarization pipeline failed: {e}")
        return ["Speaker 1"] * len(segments)

    logging.info(f"Total diarized segments: {len(diarized_segments)}")

    speaker_mapping = {}
    next_speaker_id = 1
    speaker_map = []

    for segment in segments:
        mid_point = (segment["start"] + segment["end"]) / 2.0
        assigned_speaker = "Speaker 1"
        for turn, _, label in diarized_segments:
            if turn.start <= mid_point <= turn.end:
                if label not in speaker_mapping:
                    speaker_mapping[label] = f"Speaker {next_speaker_id}"
                    next_speaker_id += 1
                assigned_speaker = speaker_mapping[label]
                break
        speaker_map.append(assigned_speaker)
        logging.info(f"Segment midpoint={mid_point:.2f} assigned to: {assigned_speaker} — {segment['text'][:30]}")

    logging.info(f"Speaker assignment breakdown: {Counter(speaker_map)}")
    return speaker_map



def transcribe_and_summarize(
    path,
    model_name="base",
    output_dir="outputs",
    summarized_model_id="mistralai/Mistral-7B-Instruct-v0.1",
    ground_truth_path=None,
    denoise=False,
    prop_decrease=0.7,
    summary=True,
    speaker=False,
    hf_token=None,
    session_timestamp=None,
    max_speakers=None,
    streaming=False,
    api_callback=None,
    model_instance=None):
    """
        Args:
        path (str): Path to input audio file.
        model_name (str): Whisper model name.
        output_dir (str): Directory to save outputs.
        denoise (bool): Whether to apply denoising.
        summary (bool): Whether to generate summaries.
        speaker (bool): Whether to run speaker diarization.
        streaming (bool): Whether to stream results.
        hf_token (str): HuggingFace token.
        max_speakers (int): Max speakers for diarization.

    Returns:
        None

    """
    os.makedirs(output_dir, exist_ok=True)

    if not isinstance(session_timestamp, str) or not re.match(r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$", session_timestamp):
        session_timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    base_time = datetime.strptime(session_timestamp, "%Y-%m-%d %H:%M:%S")

    if denoise:
        denoised_path = tempfile.mktemp(suffix=".wav")
        logging.info(f"Applying noise reduction to: {path}")
        denoise_audio(path, denoised_path, prop_decrease=prop_decrease)
        path = denoised_path

    converted_path = convert_to_wav(path)
    if not converted_path or not os.path.exists(converted_path):
        logging.error("Conversion failed — aborting transcription.")
        return

    global_diarized_segments = []
    if speaker:
        try:
            logging.info("Running global speaker diarization...")
            global_diarized_segments = run_diarization(converted_path, hf_token, max_speakers)

            for i, (track, _, label) in enumerate(global_diarized_segments):
                logging.info(f"[DIAR] {i}: {track.start:.2f}s - {track.end:.2f}s --> {label}")
            logging.info(f"Global diarization complete. {len(global_diarized_segments)} segments.")
        except Exception as e:
            logging.warning(f"Global diarization failed on {converted_path}: {e}")
            global_diarized_segments = []

    chunks_dir = os.path.join(output_dir, "chunks")
    os.makedirs(chunks_dir, exist_ok=True)

    language = "en"  # Default fallback; optionally auto-detect later

    # FIXED: Build whisper_models BEFORE calling smart_chunk_audio
    num_gpus = torch.cuda.device_count()
    if num_gpus == 0:
        raise RuntimeError("No CUDA devices available")
    gpus = list(range(num_gpus))

    if model_instance is not None:
        whisper_models = {0: model_instance}
    else:
        whisper_models = {
            gpu_id: WhisperModel(
                model_name,
                device="cuda",
                device_index=gpu_id,
                compute_type="float16",
                cpu_threads=4
            ) for gpu_id in gpus
        }

    model = whisper_models[0]
    chunk_infos = smart_chunk_audio(converted_path, chunks_dir, model, language)

    base = os.path.splitext(os.path.basename(path))[0]
    structured_chunks = {}
    temp_transcript_path = os.path.join(output_dir, f"{base}_partial_transcript.txt")
    if os.path.exists(temp_transcript_path):
        os.remove(temp_transcript_path)
    logging.info(f"Total chunks: {len(chunk_infos)}")

    failed_chunks = []


    def clean_audio_with_ffmpeg(input_path, cleaned_path):
        """
        Cleans audio using ffmpeg (mono, 16-bit PCM, 16kHz).

        Args:
            input_path (str): Path to input audio.
            cleaned_path (str): Output path for cleaned audio.

        Returns:
            None
        """
        try:
            cmd = [
                "ffmpeg", "-y", "-i", input_path,
                "-ar", "16000", "-ac", "1", "-c:a", "pcm_s16le",
                cleaned_path
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return cleaned_path
        except subprocess.CalledProcessError:
            logging.error(f"FFmpeg failed to clean {input_path}")
            return None

    
    
    def transcribe_on_gpu(gpu_id, chunk_path, chunk_offset_seconds, global_diarized_segments, model_name):
        """
        Transcribes a single chunk using a specified GPU, optionally performing speaker diarization.

        Args:
            gpu_id (int): GPU index to use for transcription.
            chunk_path (str): Path to audio chunk file.
            chunk_offset_seconds (float): Offset of chunk in original audio.
            global_diarized_segments (list): List of diarized segments (start, end, label).
            model_name (str): Name of Whisper model to load.

        Returns:
            dict: Dictionary containing transcription, chunk path, and speaker labels.
        """
        try:
            torch.cuda.set_device(gpu_id)

            # Lazily initialize model per thread
            if not hasattr(thread_local, "model"):
                thread_local.model = WhisperModel(
                    model_name,
                    device="cuda",
                    device_index=gpu_id,
                    compute_type="float16"
                )
                logging.info(f"WhisperModel '{model_name}' loaded on GPU {gpu_id} for thread {threading.get_ident()}")

            model = thread_local.model

            logging.info(f"Processing audio with duration {AudioSegment.from_file(chunk_path).duration_seconds:.3f} seconds")
            result = transcribe_file(model, chunk_path)

            if not result or not isinstance(result, tuple) or len(result) != 3:
                logging.error(f"Invalid result returned by transcribe_file() for chunk {chunk_path}: {result}")
                return None

            chunk_text, lang, segments = result

            if not isinstance(segments, list):
                logging.error(f"Expected segments to be a list, got {type(segments)} in chunk {chunk_path}")
                return None

            assigned_speakers = assign_speakers_to_segments_from_global(
                chunk_path,
                segments,
                global_diarized_segments,
                chunk_offset_seconds
            )

        

            text_with_speakers = []
            for seg, speaker in zip(segments, assigned_speakers):
                seg_text = seg.text.strip()
                raw_speaker = str(speaker)

                try:
                    start_time = float(seg.start)
                except (ValueError, TypeError):
                    logging.error(f"Invalid seg.start: {seg.start} ({type(seg.start)})")
                    start_time = 0.0

                try:
                    base_time = datetime.strptime(session_timestamp, "%Y-%m-%d %H:%M:%S")
                except (ValueError, TypeError) as e:
                    logging.error(f"Invalid session_timestamp: {session_timestamp} ({type(session_timestamp)}): {e}")
                    base_time = datetime.fromtimestamp(0)

                timestamp = base_time + timedelta(seconds=start_time)
                timestamp_str = timestamp.strftime("%Y-%m-%d %H:%M:%S")

                text_with_speakers.append(f"[{timestamp_str}] {raw_speaker}: {seg_text}")



            final_chunk_transcript = "\n".join(text_with_speakers)

            return {
                "chunk_path": chunk_path,
                "offset_seconds": chunk_offset_seconds,
                "language": lang,
                "segments": segments,
                "speaker_labels": assigned_speakers,
                "transcript": final_chunk_transcript
            }

        except Exception as e:
            logging.error(f"Chunk {chunk_path} failed on GPU {gpu_id}: {e}")
            return None

        
    structured_chunks = OrderedDict()
    full_transcript = ""

    with ThreadPoolExecutor(max_workers=len(gpus)) as executor:
        future_to_idx = {}
        
        for i, (chunk_path, chunk_offset_seconds) in enumerate(chunk_infos):
            gpu_id = gpus[i % len(gpus)]
            future = executor.submit(
                transcribe_on_gpu,
                gpu_id,
                chunk_path,
                chunk_offset_seconds,
                global_diarized_segments,
                model_name
            )


            future_to_idx[future] = (i, chunk_path)

        for future in as_completed(future_to_idx):
            idx, chunk = future_to_idx[future]
            result = future.result()
            if result:
                logging.info(f"Got result for chunk: {result['chunk_path']}")
            else:
                logging.warning('Future returned None (likely failed transcription)')
            if result is None:
                continue

            
            chunk_filename = os.path.basename(result["chunk_path"])
            text_with_speakers = result["transcript"]
            lang = result["language"]
            segments = result["segments"]

            
            chunk_id = f"{idx+1:03d}"

            # this is new — gather full transcript across all chunks
            full_transcript += text_with_speakers.strip() + "\n"

            structured_chunks[chunk_filename] = {
                "chunk_id": chunk_id,
                "transcript": text_with_speakers.strip(),
                
                "segments": [
                    {
                        "text": seg.text.strip(),
                        "timestamp": (
                            datetime.strptime(session_timestamp, "%Y-%m-%d %H:%M:%S") + timedelta(seconds=seg.start)
                        ).strftime("%Y-%m-%d %H:%M:%S"),
                        "speaker": speaker
                    }
                    for seg, speaker in zip(segments, result["speaker_labels"])
                ],
                
                "language": lang
            }

            if streaming:
                logging.info(f"\n====== Streaming Chunk {chunk_id} ======\n{text_with_speakers.strip()}\n")


    # Save transcript to temp file
    try:
        with open(temp_transcript_path, "w") as f:
            f.write(full_transcript.strip())
    except Exception as e:
        logging.error(f"Failed to write temp transcript: {e}")
        return

    # Ensure temp transcript file exists and re-read
    if not os.path.exists(temp_transcript_path):
        logging.error(f"Transcript file not found: {temp_transcript_path}")
        return

    with open(temp_transcript_path, "r") as tf:
        full_transcript = tf.read()

    if not full_transcript.strip():
        logging.warning(" Skipping save: empty transcript detected.")
        return

    # Define final output paths
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    txt_path = os.path.join(output_dir, f"{base}_all_transcripts_{timestamp}.txt")
    json_path = os.path.join(output_dir, f"{base}_all_transcripts_{timestamp}.json")

    # Write transcript to final TXT file
    with open(txt_path, "w") as f:
        f.write(full_transcript)
    logging.info(f"Transcript saved to: {txt_path}")

    try:
        logging.info(f"CUDA available before summarization: {torch.cuda.is_available()}")
        model_llm, tokenizer = load_mistral_model(summarized_model_id, hf_token=hf_token)
    except Exception as e:
        logging.error(f"Failed to load summarization model: {e}")
        model_llm = tokenizer = None

    # Generate summary if requested
    if not model_llm:
        combined_summary = "(Summarization failed due to model load issue.)"
    elif len(full_transcript.split()) < 50:
        logging.info("Skipping summarization: transcript too short.")
        combined_summary = "(Transcript too short for meaningful summarization.)"
    else:
        summary_chunks = split_into_chunks(full_transcript, tokenizer)
        summaries = []
        for i, chunk in enumerate(summary_chunks):
            logging.info(f"Summarizing chunk {i+1}/{len(summary_chunks)}")
            summary = summarize_with_mistral(model_llm, tokenizer, chunk)
            summary = summary.replace(chunk.strip(), '').strip()
            summaries.append(summary)
        combined_summary = "\n\n---\n\n".join(summaries)
    # Safeguard against None summary
    if not isinstance(combined_summary, str) or not combined_summary.strip():
        combined_summary = "(Summary generation failed or was skipped.)"

    # Write summary to TXT file
    try:
        with open(txt_path, "a") as f:
            f.write("\n\n====== Summary ======\n\n")
            f.write(combined_summary.strip())
        logging.info(" Summary successfully appended to transcript TXT.")
    except Exception as e:
        logging.error(f" Failed to write summary to TXT: {e}")

    # Write final JSON
    try:
        ordered_output = OrderedDict()
        ordered_output["chunks"] = structured_chunks
        ordered_output["transcript"] = full_transcript.strip()
        ordered_output["summary"] = combined_summary.strip()
        with open(json_path, "w") as f:
            json.dump(ordered_output, f, indent=2)
        logging.info(f"Final JSON saved to: {json_path}")
    except Exception as e:
        logging.error(f" Failed to save JSON: {e}")

    if streaming and api_callback:
        logging.info(f"\n====== Streaming Chunk {chunk_id} ======\n{text_with_speakers.strip()}\n")
        api_callback({
            "chunk_id": "summary",
            "transcript": full_transcript.strip(),
            "summary": combined_summary.strip(),
        })

    if ground_truth_path and os.path.isfile(ground_truth_path):
        with open(ground_truth_path, 'r') as gt:
            reference = gt.read().strip()
        error = wer(reference, full_transcript.strip())
        logging.info(f"WER (Word Error Rate) against ground truth: {error:.2%}")
    elif ground_truth_path:
        logging.warning(f"Ground truth file not found at: {ground_truth_path}")

    if failed_chunks:
        failed_path = os.path.join(output_dir, f"{base}_failed_chunks.txt")
        with open(failed_path, "w") as f:
            for path in failed_chunks:
                f.write(path + "\n")
        logging.warning(f"{len(failed_chunks)} chunks failed. Paths saved to: {failed_path}")

    
    
    
local_session_timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

# Handles single file or directory input, validates each audio, and runs full pipeline
def process_audio_batch(input_path, model_name, output_dir, summarized_model_id, ground_truth_path=None, denoise=False, prop_decrease=0.7, summary=True, speaker=False, hf_token=None, max_speakers=None, streaming=False, api_callback=None):
    """
    Processes a file or a folder of audio through the full pipeline.

    Args:
        input_path (str): File or directory path.
        model (str): Whisper model name.
        output_dir (str): Where to write output.
        summary (bool): Enable summarization.
        speaker (bool): Enable speaker diarization.
        denoise (bool): Enable denoising.
        streaming (bool): Enable chunk-wise streaming.
        hf_token (str): HuggingFace token.
        max_speakers (int): Maximum number of speakers.

    Returns:
        None
    """
    session_timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')

    if not output_dir:
        output_dir = os.path.join("outputs", f"run_{timestamp}")
    os.makedirs(output_dir, exist_ok=True)

    # Initialize logging
    log_file = os.path.join(output_dir, f"transcription_log_{timestamp}.log")
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
        handlers=[
            logging.FileHandler(log_file),
            logging.StreamHandler()
        ]
    )

    # Get list of files
    if os.path.isdir(input_path):
        audio_files = [
            os.path.join(dp, f)
            for dp, dn, filenames in os.walk(input_path)
            for f in filenames if f.endswith(SUPPORTED_EXTENSIONS)
        ]
    else:
        audio_files = [input_path] if input_path.endswith(SUPPORTED_EXTENSIONS) else []

    if not audio_files:
        logging.warning(f"No valid audio files found in input: {input_path}")
        return

    logging.info(f"Total audio files to process: {len(audio_files)}")

    for audio_file in audio_files:
        logging.info(f"Validating: {audio_file}")
        if not os.path.exists(audio_file):
            logging.warning(f"File does not exist: {audio_file}")
            continue

        duration = get_audio_duration(audio_file)
        logging.info(f"Duration of {audio_file}: {duration:.2f}s")
        if duration < 1:
            logging.warning(f"Skipping {audio_file}: too short (<1s)")
            continue
        elif duration > 3600:
            logging.warning(f"{audio_file} is too long (>60 min), may require chunking")

        logging.info(f"Processing: {audio_file}")
        temp_transcript_path = os.path.join(output_dir, f"{os.path.splitext(os.path.basename(audio_file))[0]}_partial_transcript.txt")
        try:
            transcribe_and_summarize(
                audio_file,
                model_name,
                output_dir,
                summarized_model_id,
                model_instance=None,
                ground_truth_path=ground_truth_path,
                denoise=denoise,
                prop_decrease=prop_decrease,
                summary=summary,
                speaker=speaker,
                hf_token=hf_token,
                session_timestamp=session_timestamp,
                max_speakers=max_speakers,
                streaming=streaming, 
                api_callback=api_callback
            )

        except Exception as e:
            logging.error(f"Failed on {audio_file}: {e}")
            logging.error(traceback.format_exc())
            continue  # or pass if this is not inside a loop


# Script entry: parse CLI args and run processing pipeline
if __name__ == "__main__":
    # Entry point: parse args and run batch
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="Path to audio file or directory")
    parser.add_argument("--model", help="Override model selection", default=None)
    parser.add_argument("--output-dir", help="Directory to store outputs", default=None)
    parser.add_argument("--summarized-model", help="HuggingFace model for summarization or provide the path of you own model", default="mistralai/Mistral-7B-Instruct-v0.1")
    parser.add_argument("--ground-truth", help="Path to ground truth transcript file for WER evaluation", default=None)
    parser.add_argument("--denoise", action="store_true", help="Apply noise reduction to audio before transcription")
    parser.add_argument("--prop-decrease", type=float, default=0.7, help="Noise reduction aggressiveness (0.0 to 1.0)")
    parser.add_argument("--summary", action="store_true", help="Include summarization after transcription")
    parser.add_argument("--speaker", action="store_true", help="Enable speaker diarization using pyannote.audio")
    parser.add_argument("--hf-token", help="Hugging Face token for diarization", default=None)
    parser.add_argument("--max-speakers", type=int, help="Maximum number of speakers to force diarization into", default=None)
    parser.add_argument("--streaming", action="store_true", help="Stream transcript results chunk by chunk")


    args = parser.parse_args()

    gpu, suggested_model, _ = detect_gpu_and_optimize()
    model_name = args.model if args.model else suggested_model
    print(f"GPU Detected: {gpu.upper()} — Using model: {model_name}")
    process_audio_batch(
    args.input, model_name, args.output_dir, args.summarized_model,
    args.ground_truth, args.denoise, args.prop_decrease, args.summary,
    args.speaker, args.hf_token , args.max_speakers ,args.streaming, api_callback=None
)

