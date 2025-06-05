# Whisper Transcription API

### Transcription + Summarization + Diarization Pipeline (FastAPI-powered)

This blueprint provides a complete solution for running **audio/video transcription**, **speaker diarization**, and **summarization** via a RESTful API. It integrates [Faster-Whisper](https://github.com/guillaumekln/faster-whisper) for efficient transcription, [pyannote.audio](https://github.com/pyannote/pyannote-audio) for diarization, and Hugging Face instruction-tuned LLMs (e.g., Mistral-7B) for summarization. It supports multi-GPU acceleration, real-time streaming logs, and JSON/text output formats.

---

## Key Features

| Capability              | Description                                                                                   |
|------------------------|-----------------------------------------------------------------------------------------------|
| Transcription          | Fast, multi-GPU inference with Faster-Whisper                                                  |
| Summarization          | Uses Mistral-7B (or other HF models) to create summaries of long transcripts                  |
| Speaker Diarization    | Global speaker labeling via pyannote.audio                                                     |
| Denoising              | Hybrid removal of background noise using Demucs and noisereduce                               |
| Real-Time Streaming    | Logs stream live via HTTP if enabled                                                           |
| Format Compatibility   | Supports `.mp3`, `.wav`, `.flac`, `.aac`, `.m4a`, `.mp4`, `.webm`, `.mov`, `.mkv`, `.avi`, etc. |

---

## Deployment on OCI Blueprint

### Sample Recipe (Service Mode)
```json
{
  "recipe_id": "whisper_transcription",
  "recipe_mode": "service",
  "deployment_name": "whisper-transcription-a10",
  "recipe_image_uri": "iad.ocir.io/iduyx1qnmway/corrino-devops-repository:whisper_transcription_v8",
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

### Endpoint
```
POST https://<YOUR_DEPLOYMENT>.nip.io/transcribe
```
**Example:**  
`https://whisper-transcription-a10-6666.130-162-199-33.nip.io/transcribe`

---

## API Parameters

| Name              | Type      | Description                                                                                                           |
|-------------------|-----------|-----------------------------------------------------------------------------------------------------------------------|
| `audio_url`       | string    | URL to audio file in OCI Object Storage (requires PAR)                                                               |
| `model`           | string    | Whisper model to use: `base`, `medium`, `large`, `turbo`, etc.                                                      |
| `summary`         | bool      | Whether to generate a summary (default: false). Requires `hf_token` if model path not provided                      |
| `speaker`         | bool      | Whether to run diarization (default: false). Requires `hf_token`                                                    |
| `max_speakers`    | int       | (Optional) Maximum number of speakers expected for diarization                                                       |
| `denoise`         | bool      | Whether to apply noise reduction                                                                                     |
| `streaming`       | bool      | Enables real-time logs via /stream_log endpoint                                                                      |
| `hf_token`        | string    | Hugging Face access token (required for diarization or HF-hosted summarizers)                                       |
| `prop_decrease`   | float     | (Optional) Controls level of noise suppression. Range: 0.0–1.0 (default: 0.7)                                        |
| `summarized_model`| string    | (Optional) Path or HF model ID for summarizer. Default: `mistralai/Mistral-7B-Instruct-v0.1`                         |
| `ground_truth`    | string    | (Optional) Path to reference transcript file to compute WER                                                          |

---

## Example cURL Command
```bash
curl -k -N -L -X POST https://<YOUR_DEPLOYMENT>.nip.io/transcribe \
  -F "audio_url=<YOUR_PAR_URL>" \
  -F "model=turbo" \
  -F "summary=true" \
  -F "speaker=true" \
  -F "streaming=true" \
  -F "denoise=false" \
  -F "hf_token=hf_xxxxxxx" \
  -F "max_speakers=2"
```

---

## Output Files

Each processed audio generates the following:

- `*.txt` – Human-readable transcript with speaker turns and timestamps
- `*.json` – Full structured metadata: transcript, summary, diarization
- `*.log` – Detailed processing log (useful for debugging or auditing)

---

## Streaming Logs

If `streaming=true`, the response will contain a log filename:
```json
{
  "meta": "logfile_name",
  "logfile": "transcription_log_remote_audio_<timestamp>.log"
}
```
To stream logs in real-time:
```bash
curl -N https://<YOUR_DEPLOYMENT>.nip.io/stream_log/<log_filename>
```

---

## Hugging Face Access

To enable diarization, accept model terms at:  
https://huggingface.co/pyannote/segmentation

Generate token at:  
https://huggingface.co/settings/tokens

---

## Dependencies

| Package             | Purpose                          |
|---------------------|----------------------------------|
| `faster-whisper`    | Core transcription engine        |
| `transformers`      | Summarization via Hugging Face   |
| `pyannote.audio`    | Speaker diarization              |
| `pydub`, `librosa`  | Audio chunking and processing    |
| `demucs`            | Vocal separation / denoising     |
| `fastapi`, `uvicorn`| REST API server                  |
| `jiwer`             | WER evaluation                   |

---

## Final Notes

- Whisper model is GPU-cached per thread for performance.
- Diarization runs globally, not chunk-by-chunk.
- Denoising is optional but improves quality on noisy files.
