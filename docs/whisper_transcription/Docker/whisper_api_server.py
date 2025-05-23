import os
import tempfile
import json
import threading
import glob
from queue import Queue
from threading import Lock
from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import StreamingResponse, JSONResponse
from whisper_code import transcribe_and_summarize, load_whisper_model_faster

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

            def api_callback(result):
                q.put(json.dumps(result) + "\n")

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

        return StreamingResponse(generator(), media_type="application/json")

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