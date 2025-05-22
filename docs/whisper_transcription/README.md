# Whisper Transcription + Summarization + Diarization API

This project provides a high-performance pipeline for **audio/video transcription**, **speaker diarization**, and **summarization** using [Faster-Whisper](https://github.com/guillaumekln/faster-whisper), Hugging Face LLMs (e.g. Mistral), and [pyannote.audio](https://github.com/pyannote/pyannote-audio). It exposes a **FastAPI-based REST API** and supports CLI usage as well.

---

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



