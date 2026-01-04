FROM python:3.12-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /app/ComfyUI

# Install ComfyUI dependencies
WORKDIR /app/ComfyUI
RUN pip install --no-cache-dir -r requirements.txt

# Install ComfyUI GGUF custom node for Qwen-Image-2512 support
WORKDIR /app/ComfyUI/custom_nodes
RUN git clone https://github.com/city96/ComfyUI-GGUF.git
WORKDIR /app/ComfyUI/custom_nodes/ComfyUI-GGUF
RUN pip install --no-cache-dir -r requirements.txt

# Install ComfyUI Manager (optional but recommended)
WORKDIR /app/ComfyUI/custom_nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# Create model directories
WORKDIR /app/ComfyUI
RUN mkdir -p models/diffusion_models models/clip models/vae

# Download Qwen-Image-2512 models (GGUF quantized versions for efficiency)
WORKDIR /app/ComfyUI/models/diffusion_models
RUN wget -q https://huggingface.co/unsloth/Qwen-Image-2512-GGUF/resolve/main/qwen-image-2512-Q4_K_M.gguf

WORKDIR /app/ComfyUI/models/clip
RUN wget -q https://huggingface.co/unsloth/Qwen-Image-2512-GGUF/resolve/main/Qwen2.5-VL-7B-Instruct-UD-Q4_K_XL.gguf

WORKDIR /app/ComfyUI/models/vae
RUN wget -q https://huggingface.co/unsloth/Qwen-Image-2512-GGUF/resolve/main/qwen_image_vae.safetensors

# Set working directory back to ComfyUI
WORKDIR /app/ComfyUI

# Expose port for ComfyUI web interface
EXPOSE 8188

# Start ComfyUI with listen on all interfaces
CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
