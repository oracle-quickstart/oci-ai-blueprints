from datetime import datetime
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
from datetime import datetime
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
import threading
thread_local = threading.local()

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
    Converts any input audio or video to 16kHz mono 16-bit PCM WAV using ffmpeg.
    This is more robust than AudioSegment and supports a wider range of formats including video.
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

def assign_speakers_to_segments_from_global(chunk_path, segments, diarized_segments):
    from difflib import get_close_matches
    assigned_speakers = []
    for seg in segments:
        midpoint = (seg['start'] + seg['end']) / 2
        match = None
        for track, _, label in diarized_segments:
            normalized_label = str(label).strip().upper()  # Normalize case and spacing
            if track.start <= midpoint <= track.end:
                match = normalized_label
                break

        if not match:
            match = "Speaker_0"
        assigned_speakers.append(match)
    logging.info(f"Speaker assignment breakdown: {Counter(assigned_speakers)}")
    return assigned_speakers

# Applies noise reduction using noisereduce (conservative settings)

def denoise_audio(input_file, output_file, prop_decrease=0.7):
    """
    Strong two-step denoising:
    1. Use Demucs to extract vocals.
    2. Denoise vocals with librosa + noisereduce.
    Logs status using logging module.
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
        shutil.copy(input_file, output_file)  # ✅ FALLBACK
    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)



# Calculates duration (in seconds) of the audio file using wave or pydub
def get_audio_duration(path):
    """
    Returns audio duration in seconds using wave or pydub.
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
    Force-split audio into equal-sized chunks if silence-based fails or yields too long segments.
    """
    return make_chunks(audio, chunk_length_ms)

def smart_chunk_audio(input_path, min_silence_len=1000, silence_thresh=-40, chunk_padding=1000):
    audio = AudioSegment.from_file(input_path)
    os.makedirs(CHUNK_FOLDER, exist_ok=True)
    logging.info(f"Smart chunking using silence detection on: {input_path}")
    chunks = silence.split_on_silence(audio, min_silence_len=min_silence_len, silence_thresh=silence_thresh, keep_silence=chunk_padding)
    if not chunks or any(len(chunk) > 90000 for chunk in chunks):  # fallback if no chunks or too long
        logging.warning("Fallback to fixed chunking due to silence issues or long chunks.")
        chunks = fallback_fixed_chunks(audio)
    chunk_paths = []
    for idx, chunk in enumerate(chunks):
        chunk_path = os.path.join(CHUNK_FOLDER, f"chunk_{idx:03d}.wav")
        chunk.export(chunk_path, format="wav")
        chunk_paths.append(chunk_path)
        logging.info(f"Exported chunk: {chunk_path}")
    return chunk_paths

# Converts and transcribes an audio file using Whisper model

def transcribe_file(model, audio_path):
    """
    Converts and transcribes a file using faster-whisper with language detection.
    Returns: (text, language, segments)
    """
    try:
        wav_path = convert_to_wav(audio_path)

        segments_generator, info = model.transcribe(wav_path, beam_size=1, language=None)
        segments = []
        text = ""
        for seg in segments_generator:
            segments.append({
                "start": round(seg.start, 2),
                "end": round(seg.end, 2),
                "text": seg.text.strip()
            })
            text += seg.text.strip() + " "

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
    Summarizes a transcript chunk using Mistral or selected model.
    """
    prompt = f"<s>[INST] Summarize the following meeting transcript into a concise list of key points, decisions, and action items:\n\n{text} [/INST]"
    inputs = tokenizer(prompt, return_tensors="pt", truncation=True, max_length=4096).to(model.device)
    with torch.no_grad():
        output = model.generate(**inputs, max_new_tokens=512)
    return tokenizer.decode(output[0], skip_special_tokens=True)

# Main pipeline for one file: validate → denoise → chunk → transcribe → summarize → save outputs

def assign_speakers_to_segments(full_audio_path, segments, hf_token, max_speakers=None):
    """
    Assign speakers using PyAnnote diarization and match them to Whisper segments based on midpoint overlap.
    """
    logging.info(f"Running speaker diarization on: {full_audio_path}")
    try:
        pipeline = Pipeline.from_pretrained("pyannote/speaker-diarization-3.1", use_auth_token=hf_token)
        if torch.cuda.is_available():
            pipeline.to(torch.device("cuda"))
        # Run diarization once per full audio (global instead of per chunk)
        diarization = pipeline({"audio": converted_path})
        global_diarized_segments = list(diarization.itertracks(yield_label=True)) if diarization else []
        logging.info(f"Global diarization complete. {len(global_diarized_segments)} segments.")
    except Exception as e:
        logging.error(f"Chunk processing failed: {e}")
        return None
        logging.error(f"Could not load pyannote pipeline: {e}")
        return ["Speaker 1"] * len(segments)

    try:
        if max_speakers:
            diarization = pipeline({"audio": full_audio_path}, num_speakers=max_speakers)
        else:
            diarization = pipeline(full_audio_path)
    except Exception as e:
        logging.error(f"Chunk processing failed: {e}")
        return None
        logging.error(f"Diarization pipeline failed: {e}")
        return ["Speaker 1"] * len(segments)

    diarized_segments = list(diarization.itertracks(yield_label=True))
    if not diarized_segments:
        logging.warning("No diarized speaker segments were found.")
        return ["Speaker 1"] * len(segments)

    logging.info(f"Total diarized segments: {len(diarized_segments)}")
    for turn, _, speaker in diarized_segments:
        logging.info(f"Diarized: {speaker} | {turn.start:.2f} - {turn.end:.2f}")

    speaker_map = []
    for segment in segments:
        mid_point = (segment["start"] + segment["end"]) / 2.0
        assigned_speaker = "Speaker 1"
        for turn, _, speaker in diarized_segments:
            if turn.start <= mid_point <= turn.end:
                assigned_speaker = speaker
                break
        speaker_map.append(assigned_speaker)
        logging.info(f"Segment midpoint={mid_point:.2f} assigned to: {assigned_speaker} — {segment['text'][:30]}")

    logging.info(f"Speaker assignment breakdown: {Counter(speaker_map)}")
    return speaker_map

def transcribe_and_summarize(path, model_name="base", output_dir="outputs", summarized_model_id="mistralai/Mistral-7B-Instruct-v0.1", ground_truth_path=None, denoise=False, prop_decrease=0.7, summary=True, speaker=False, hf_token=None, session_timestamp=None, max_speakers=None, streaming=False, api_callback=None, model_instance=None):
    import torch
    from concurrent.futures import ThreadPoolExecutor, as_completed

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
            pipeline = Pipeline.from_pretrained("pyannote/speaker-diarization", use_auth_token=hf_token)
            if torch.cuda.is_available():
                pipeline.to(torch.device("cuda"))
            diarization = pipeline({"audio": converted_path})
            global_diarized_segments = list(diarization.itertracks(yield_label=True)) if diarization else []
            logging.info(f"Global diarization complete. {len(global_diarized_segments)} segments.")
        except Exception as e:
            logging.warning(f"Global diarization failed on {converted_path}: {e}")
            global_diarized_segments = []

    chunk_paths = smart_chunk_audio(converted_path)
    base = os.path.splitext(os.path.basename(path))[0]
    structured_chunks = {}
    temp_transcript_path = os.path.join(output_dir, f"{base}_partial_transcript.txt")
    if os.path.exists(temp_transcript_path):
        os.remove(temp_transcript_path)
    logging.info(f"Total chunks: {len(chunk_paths)}")

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

    
    failed_chunks = []

    def clean_audio_with_ffmpeg(input_path, cleaned_path):
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

    
    
    def transcribe_on_gpu(gpu_id, chunk_path, global_diarized_segments, model_name):
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

            logging.debug(f"Processing chunk: {chunk_path}")
            duration = get_audio_duration(chunk_path)
            if not duration or duration < 1.0:
                logging.warning(f"Skipping chunk {chunk_path}: invalid or too short ({duration}s)")
                return None

            result = transcribe_file(model, chunk_path)

            if not result or not isinstance(result, tuple) or len(result) != 3:
                raise ValueError("Invalid result returned from transcribe_file()")

            chunk_text, lang, segments = result

            # Speaker assignment
            if speaker:
                try:
                    speakers = assign_speakers_to_segments_from_global(chunk_path, segments, global_diarized_segments)
                except Exception as e:
                    logging.warning(f"Diarization failed for {chunk_path}: {e}")
                    speakers = ["Speaker 1"] * len(segments)
            else:
                speakers = ["Speaker 1"] * len(segments)

            for i, s in enumerate(segments):
                s["speaker"] = speakers[i] if i < len(speakers) else "Speaker 1"

            # Format output
            text_with_speakers = ""
            for seg in segments:
                raw_speaker = str(seg.get("speaker", "Speaker 1"))
                if raw_speaker.lower().startswith("speaker_"):
                    speaker_number = int(raw_speaker.split("_")[1])
                    speaker_label = f"Speaker {speaker_number + 1}"
                else:
                    speaker_label = raw_speaker

                timestamp_full = (
                    base_time + timedelta(seconds=seg["start"])
                ).strftime("%Y-%m-%d %H:%M:%S")

                text_with_speakers += f"[{timestamp_full}] {speaker_label}: {seg['text'].strip()}\n"

            chunk_filename = os.path.basename(chunk_path)
            return chunk_filename, text_with_speakers, lang, segments

        except Exception as e:
            logging.error(f"Chunk processing failed on {chunk_path}: {e}")
            failed_chunks.append(chunk_path)
            return None



            if speaker:
                try:
                    speakers = assign_speakers_to_segments_from_global(chunk_path, segments, global_diarized_segments)
                except Exception as e:
                    logging.warning(f"Diarization failed for chunk file {chunk_path}: {e}")
                    speakers = ["Speaker 1"] * len(segments)
            else:
                speakers = ["Speaker 1"] * len(segments)

            for i, s in enumerate(segments):
                s["speaker"] = speakers[i] if i < len(speakers) else "Speaker 1"

            text_with_speakers = ""
            for seg in segments:
                raw_speaker = str(seg.get("speaker", "Speaker 1"))
                if raw_speaker.lower().startswith("speaker_"):
                    speaker_number = int(raw_speaker.split("_")[1])
                    speaker_label = f"Speaker {speaker_number + 1}"
                else:
                    speaker_label = raw_speaker

                timestamp_full = (
                    base_time + timedelta(seconds=seg["start"])
                ).strftime("%Y-%m-%d %H:%M:%S")
                text_with_speakers += f"[{timestamp_full}] {speaker_label}: {seg['text'].strip()}\n"

            chunk_filename = os.path.basename(chunk_path)
            return chunk_filename, text_with_speakers, lang, segments

        except Exception as e:
            logging.error(f"Chunk processing failed: {e}")
            failed_chunks.append(chunk_path)
            return None


        
    structured_chunks = OrderedDict()
    full_transcript = ""

    with ThreadPoolExecutor(max_workers=len(gpus)) as executor:
        future_to_idx = {}
        for i, chunk in enumerate(chunk_paths):
            gpu_id = gpus[i % len(gpus)]
            future = executor.submit(transcribe_on_gpu, gpu_id, chunk, global_diarized_segments, model_name)
            future_to_idx[future] = (i, chunk)

        for future in as_completed(future_to_idx):
            idx, chunk = future_to_idx[future]
            result = future.result()
            if result is None:
                continue

            chunk_filename, text_with_speakers, lang, segments = result
            chunk_id = f"{idx+1:03d}"

            # this is new — gather full transcript across all chunks
            full_transcript += text_with_speakers.strip() + "\n"

            structured_chunks[chunk_filename] = {
                "chunk_id": chunk_id,
                "transcript": text_with_speakers.strip(),
                "segments": [
                    {
                        "text": seg["text"].strip(),
                        "timestamp": (
                            datetime.strptime(session_timestamp, "%Y-%m-%d %H:%M:%S") + timedelta(seconds=seg["start"])
                        ).strftime("%Y-%m-%d %H:%M:%S"),
                        "speaker": seg["speaker"]
                    }
                    for seg in segments
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
    Validates and runs pipeline on folder or single audio file.
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