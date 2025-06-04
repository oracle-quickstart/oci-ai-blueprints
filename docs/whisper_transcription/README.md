# Whisper Transcription + Summarization + Diarization API

This project provides a high-performance pipeline for **audio/video transcription**, **speaker diarization**, and **summarization** using [Faster-Whisper](https://github.com/guillaumekln/faster-whisper), Hugging Face LLMs (e.g. Mistral), and [pyannote.audio](https://github.com/pyannote/pyannote-audio). It exposes a **FastAPI-based REST API** and supports CLI usage as well.

---
## System Architecture

The overall architecture consists of several key stages. First, audio is converted using ffmpeg and optionally denoised using a hybrid method combining Demucs (for structured background removal) and either noisereduce or DeepFilterNet (for static noise). Next, silence-aware chunking is applied using pydub to segment speech cleanly without breaking mid-sentence. The Whisper model then transcribes each chunk, optionally followed by speaker diarization using pyannote-audio. Finally, if summarization is enabled, an instruction-tuned LLM such as Mistral-7B generates concise and structured summaries. Outputs are written to .txt ,log and .json files, optionally embedded with speaker turns and summaries.
![image](https://github.com/user-attachments/assets/6a8b55f0-9de5-46e9-9ef0-80e904f61a7d)

## Features

- Transcribes audio using **Faster-Whisper** (multi-GPU support)
- Summarizes long transcripts using **Mistral-7B** as a default
- Performs speaker diarization via **PyAnnote**
- Optional denoising using **Demucs + Noisereduce**
- Supports real-time **streaming API responses**
- Works on common formats: `.flac`, `.wav`, `.mp3`, `.m4a`, `.aac`, `.ogg`, `.webm`, `.opus` `.mp4`, `.mp3`, `.mov`, `.mkv`, `.avi`, etc. 

---

## Installation

### 1. Create virtual environment
```bash
python3 -m venv whisper_env
source whisper_env/bin/activate
```

### 2. Install PyTorch (with CUDA 12.1 for H100/A100)
```bash
pip install torch==2.2.2+cu121 torchaudio==2.2.2+cu121 -f https://download.pytorch.org/whl/torch_stable.html
```

### 3. Install requirements
```bash
pip install -r requirements.txt
```

> Make sure to have `ffmpeg` installed on your system:
```bash
sudo apt install ffmpeg
```

---

## Usage

### CLI Transcription & Summarization

```bash
python faster_code_week1_v28.py \
  --input /path/to/audio_or_folder \
  --model medium \
  --output-dir output/ \
  --summarized-model mistralai/Mistral-7B-Instruct-v0.1 \
  --summary \
  --speaker \
  --denoise \
  --prop-decrease 0.7 \
  --hf-token YOUR_HUGGINGFACE_TOKEN \
  --streaming \
  --max-speakers 2 \
  --ground-truth ground_truth.txt
```

**Optional flags:**

| Argument            | Description                                                                 |
|---------------------|-----------------------------------------------------------------------------|
| `--input`           | **Required.** Path to input file or directory of audio/video.               |
| `--model`           | Whisper model to use (`base`, `small`, `medium`, `large`, `turbo`). Auto-detects if not specified. |
| `--output-dir`      | Directory to store output files. Defaults to a timestamped folder.          |
| `--summarized-model`| Hugging Face or local LLM for summarization. Default: `Mistral-7B`.         |
| `--denoise`         | Enable two-stage denoising (Demucs + noisereduce).                          |
| `--prop-decrease`   | Float [0.0–1.0]. Controls noise suppression. Default = 0.7                  |
| `--summary`         | Enable summarization after transcription.                                   |
| `--speaker`         | Enable speaker diarization using PyAnnote.                                  |
| `--streaming`       | Stream results in real-time chunk-by-chunk.                                 |
| `--hf-token`        | Hugging Face token for gated model access.                                  |
| `--max-speakers`    | Limit the number of identified speakers. Optional.                          |
| `--ground-truth`    | Path to ground truth `.txt` for WER evaluation. Optional.                   |

---

### Start API Server

```bash
uvicorn whisper_api_server:app --host 0.0.0.0 --port 8000
```

### Example API Call

```bash
curl -X POST http://<YOUR_IP>:8000/transcribe \
  -F "audio_file=@test.wav" \
  -F "model=medium" \
  -F "summary=true" \
  -F "speaker=true" \
  -F "denoise=false" \
  -F "streaming=true" \
  -F "hf_token=hf_xxx" \
  -F "max_speakers=2"
```


### Start Blueprint Deployment
in the deploymen part of Blueprint, add a recipe suchas the following
```bash
{
  "recipe_id": "whisper  transcription",
  "recipe_mode": "service",
  "deployment_name": "whisper-transcription-a10",
  "recipe_image_uri": "iad.ocir.io/iduyx1qnmway/corrino-devops-repository:whisper_transcription_v6",
  "recipe_node_shape": "VM.GPU.A10.2",
  "recipe_replica_count": 1,
  "recipe_container_port": "8000",
 "recipe_nvidia_gpu_count": 2,
  "recipe_node_pool_size": 1,
  "recipe_node_boot_volume_size_in_gbs": 200,
  "recipe_ephemeral_storage_size": 100,
  "recipe_shared_memory_volume_size_limit_in_mb": 200
}

```
#### Endpoint

```
POST https://<YOUR_DEPLOYMENT>.nip.io/transcribe
```

**Example:**
```
https://whisper-transcription-a10-6666.130-162-199-33.nip.io/transcribe
```

---

#### Parameters

| Parameter       | Type      | Description                                                                                                                                               |
|----------------|-----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| `audio_url`     | `string`  | URL to a Pre-Authenticated Request (PAR) of the audio file stored in OCI Object Storage.                                                                  |
| `model`         | `string`  | Whisper model name to use (`base`, `medium`, `turbo`, etc.).                                                                                              |
| `summary`       | `bool`    | Whether to generate a summary at the end. If `true` and no custom model path is provided, `mistralai/Mistral-7B-Instruct-v0.1` will be loaded from Hugging Face. Requires `hf_token`. |
| `speaker`       | `bool`    | Whether to enable speaker diarization. Requires `hf_token`. If `false`, all segments will be labeled as "Speaker 1".                                      |
| `max_speakers`  | `int`     | (Optional) Helps improve diarization accuracy by specifying the expected number of speakers.                                                              |
| `denoise`       | `bool`    | (Optional) Apply basic denoising to improve quality in noisy recordings.                                                                                  |
| `streaming`     | `bool`    | (Optional) Enable real-time log streaming for transcription chunks and progress updates.                                                                  |
| `hf_token`      | `string`  | Hugging Face token, required for loading models like Mistral or enabling speaker diarization.                                                             |
| `prop-decrease`     | `Float`  | Controls noise suppression. Default = 0.7                                                           |
| `summarized-model`      | `path`  | Hugging Face or local LLM path for summarization. Default: Mistral-7B.                                                             |
| `ground-truth`      | `path`  | Path to ground truth `.txt` file for WER evaluation.                                                           |


---

#### Example `curl` Command

```bash
curl -k -N -L -X POST https://<YOUR_DEPLOYMENT>.nip.io/transcribe \
  -F "audio_url=<YOUR_PAR_URL>" \
  -F "model=turbo" \
  -F "summary=true" \
  -F "speaker=true" \
  -F "streaming=true" \
  -F "denoise=false" \
  -F "hf_token=hf_xxxxxxxxxxxxxxx" \
  -F "max_speakers=2"
```

---

#### Real-Time Log Streaming

If `streaming=true`, the API will return:

```json
{
  "meta": "logfile_name",
  "logfile": "transcription_log_remote_audio_<timestamp>.log"
}
```

To stream logs in real-time (in another terminal):

```bash
curl -N https://<YOUR_DEPLOYMENT>.nip.io/stream_log/transcription_log_remote_audio_<timestamp>.log
```

**Example:**

```bash
curl -N https://whisper-transcription-a10-6666.130-162-199-33.nip.io/stream_log/transcription_log_remote_audio_20250604_020250.log
```

This shows chunk-wise transcription output live, followed by the summary at the end.

---

#### Non-Streaming Mode

If `streaming=false`, the API will return the entire transcription (and summary if requested) in a single JSON response when processing is complete.

---

## Outputs

For each input file, the pipeline generates:

- `*.txt` — Transcript with speaker labels and timestamps
- `*.json` — Transcript + speaker segments + summary
- `transcription_log_*.log` — Full debug log for reproducibility

---

## Hugging Face Token

To enable **speaker diarization**, accept the model terms at:
[https://huggingface.co/pyannote/segmentation](https://huggingface.co/pyannote/segmentation)

Then generate a token at:
[https://huggingface.co/settings/tokens](https://huggingface.co/settings/tokens)

---

## Dependencies

Key Python packages:

- `faster-whisper`
- `transformers`
- `pyannote.audio`
- `librosa`, `pydub`, `noisereduce`
- `ffmpeg-python`, `demucs`
- `fastapi`, `uvicorn`, `jiwer`

---

## Notes

- The API uses a **cached Whisper model per variant** for faster performance.
- **Diarization is performed globally** over the entire audio, not per chunk.
- **Denoising uses Demucs to isolate vocals**, which may be GPU-intensive.

---



