# Base image with Python and CUDA (for H100/A100 GPUs with CUDA 12.1)
FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04


# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TRANSFORMERS_CACHE=/root/.cache/huggingface/transformers

# Install system packages and cuDNN 9.10.1 manually (for CUDA 12)
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv python3-dev \
    ffmpeg git curl wget ca-certificates gnupg libsndfile1 && \
    mkdir -p /tmp/cudnn && cd /tmp/cudnn && \
    wget https://developer.download.nvidia.com/compute/cudnn/9.10.1/local_installers/cudnn-local-repo-ubuntu2204-9.10.1_1.0-1_amd64.deb && \
    dpkg -i cudnn-local-repo-ubuntu2204-9.10.1_1.0-1_amd64.deb && \
    cp /var/cudnn-local-repo-ubuntu2204-9.10.1/cudnn-*-keyring.gpg /usr/share/keyrings/ && \
    apt-get update && \
    apt-get -y install cudnn-cuda-12 && \
    rm -rf /var/lib/apt/lists/* /tmp/cudnn

# Upgrade pip and install torch separately for CUDA 12.1
RUN python3 -m pip install --upgrade pip && \
    pip install torch==2.2.2+cu121 torchaudio==2.2.2+cu121 -f https://download.pytorch.org/whl/torch_stable.html

# Copy requirements and install them
COPY requirements.txt /app/requirements.txt
WORKDIR /app
RUN pip install -r requirements.txt

# Copy application code
COPY whisper_code.py whisper_code.py
COPY whisper_api_server.py whisper_api_server.py

# Expose port
EXPOSE 8000

# Run API
CMD ["uvicorn", "whisper_api_server:app", "--host", "0.0.0.0", "--port", "8000"]
