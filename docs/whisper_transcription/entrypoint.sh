#!/bin/bash
echo "Checking for available GPU..."

for i in {1..30}; do
    if nvidia-smi &>/dev/null; then
        echo "GPU detected. Starting application..."
        break
    else
        echo "Waiting for GPU to be ready... ($i/30)"
        sleep 2
    fi
done

# Optionally fail if GPU never appears
if ! nvidia-smi &>/dev/null; then
    echo "GPU not detected after waiting. Exiting."
    exit 1
fi

exec uvicorn whisper_api_server:app \
    --host 0.0.0.0 \
    --port 8000 \
    --timeout-keep-alive 900 \
    --limit-max-requests 500000000
