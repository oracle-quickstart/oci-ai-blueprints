import os
import tempfile
import json
import threading
import glob
from queue import Queue
from threading import Lock
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import StreamingResponse, JSONResponse, FileResponse
from whisper_code import transcribe_and_summarize, load_whisper_model_faster
import logging
import time

app = FastAPI()

# Global model cache and lock
model_cache = {}
model_lock = Lock()

@app.post("/transcribe")
async def transcribe_audio_api(
    audio_file: UploadFile = File(...),
    model: str = Form("base"),
    summarized_model: str = Form("mistralai/Mistral-7B-Instruct-v0.1"),
    denoise: bool = Form(False),
    prop_decrease: float = Form(0.7),
    summary: bool = Form(True),
    speaker: bool = Form(False),
    hf_token: str = Form(None),
    max_speakers: int = Form(None),
    streaming: bool = Form(False)
):
    
    # ✅ Setup dynamic logging per request
    from datetime import datetime
    basename = os.path.splitext(os.path.basename(audio_file.filename))[0]
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    log_file = f"transcription_log_{basename}_{timestamp}.log"

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
        filename=log_file,
        filemode="w",
        force=True  # ensures logging resets each request
    )

    temp_audio_path = tempfile.mktemp(suffix=f"_{audio_file.filename}")
    with open(temp_audio_path, "wb") as f:
        f.write(await audio_file.read())

    output_dir = tempfile.mkdtemp()

    # Ensure model is loaded once
    if model not in model_cache:
        model_cache[model] = load_whisper_model_faster(model)

    whisper_model = model_cache[model]

    if streaming:
        def generator():
            q = Queue()
            q.put(f"data: {json.dumps({'meta': 'logfile_name', 'logfile': log_file})}\n\n")


            def api_callback(result):
                if result.get("chunk_id", "").startswith("chunk_"):
                    logging.info(f"\n====== Streaming {result['chunk_id']} ======\n{result.get('text', '').strip()}\n")
                elif result.get("chunk_id") == "summary":
                    logging.info("\n====== Final Summary ======\n")
                    logging.info(result.get("summary", "").strip())
                    result["logfile"] = log_file

                q.put(f"data: {json.dumps(result)}\n\n")

            def run_pipeline():
                try:
                    with model_lock:
                        transcribe_and_summarize(
                            path=temp_audio_path,
                            model_name=model,
                            output_dir=output_dir,
                            summarized_model_id=summarized_model,
                            denoise=denoise,
                            prop_decrease=prop_decrease,
                            summary=summary,
                            speaker=speaker,
                            hf_token=hf_token,
                            max_speakers=max_speakers,
                            streaming=True,
                            api_callback=api_callback,
                            model_instance=whisper_model
                        )
                except Exception as e:
                    import traceback
                    traceback.print_exc()
                    q.put(json.dumps({"error": f"Streaming transcription failed: {str(e)}"}))
                finally:
                    q.put(None)

            threading.Thread(target=run_pipeline).start()

            while True:
                chunk = q.get()
                if chunk is None:
                    break
                yield chunk

        return StreamingResponse(generator(), media_type="text/event-stream")

    else:
        try:
            with model_lock:
                transcribe_and_summarize(
                    path=temp_audio_path,
                    model_name=model,
                    output_dir=output_dir,
                    summarized_model_id=summarized_model,
                    denoise=denoise,
                    prop_decrease=prop_decrease,
                    summary=summary,
                    speaker=speaker,
                    hf_token=hf_token,
                    max_speakers=max_speakers,
                    streaming=False,
                    api_callback=None,
                    model_instance=whisper_model
                )
        except Exception as e:
            import traceback
            traceback.print_exc()
            return JSONResponse(
                content={"error": f"Transcription failed: {str(e)}"},
                status_code=500
            )

        try:
            json_files = sorted(
                glob.glob(os.path.join(output_dir, "*.json")),
                key=os.path.getmtime,
                reverse=True
            )
            if not json_files:
                raise FileNotFoundError("No output JSON file found.")

            with open(json_files[0]) as f:
                return JSONResponse(content=json.load(f))
            
        except Exception as e:
            import traceback
            traceback.print_exc()
            return JSONResponse(
                content={"error": f"Failed to read output JSON: {str(e)}"},
                status_code=500
            )

@app.get("/stream_log/{filename}")
def stream_log(filename: str):
    log_path = os.path.join(".", filename)
    if not os.path.exists(log_path):
        return JSONResponse(content={"error": "Log file not found."}, status_code=404)

    def stream_lines():
        with open(log_path, "r") as f:
            f.seek(0, 2)  # Move to end of file
            while True:
                line = f.readline()
                if line:
                    yield f"data: {line.strip()}\n\n"
                else:
                    time.sleep(0.2)  # Poll every 200ms

    return StreamingResponse(stream_lines(), media_type="text/event-stream")