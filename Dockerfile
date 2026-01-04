FROM python:3.12

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /app/ComfyUI

# Install ComfyUI dependencies
WORKDIR /app/ComfyUI
RUN pip install --no-cache-dir -r requirements.txt torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install ComfyUI-GGUF custom node
WORKDIR /app/ComfyUI/custom_nodes
RUN git clone https://github.com/city96/ComfyUI-GGUF.git
WORKDIR /app/ComfyUI/custom_nodes/ComfyUI-GGUF
RUN pip install --no-cache-dir -r requirements.txt

# Install ComfyUI Manager
WORKDIR /app/ComfyUI/custom_nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# Create model directories
WORKDIR /app/ComfyUI
RUN mkdir -p models/diffusion_models models/clip models/vae

# Create startup script that downloads models on first run
RUN echo '#!/bin/bash\n\
set -e\n\
echo "Checking for Qwen-Image-2512 models..."\n\
if [ ! -f /app/ComfyUI/models/diffusion_models/qwen-image-2512-Q4_K_M.gguf ]; then\n\
    echo "Downloading UNet model..."\n\
    wget -q --show-progress https://huggingface.co/unsloth/Qwen-Image-2512-GGUF/resolve/main/qwen-image-2512-Q4_K_M.gguf \\\n\
        -O /app/ComfyUI/models/diffusion_models/qwen-image-2512-Q4_K_M.gguf\n\
fi\n\
if [ ! -f /app/ComfyUI/models/clip/Qwen2.5-VL-7B-Instruct-UD-Q4_K_XL.gguf ]; then\n\
    echo "Downloading CLIP model..."\n\
    wget -q --show-progress https://huggingface.co/unsloth/Qwen-Image-2512-GGUF/resolve/main/Qwen2.5-VL-7B-Instruct-UD-Q4_K_XL.gguf \\\n\
        -O /app/ComfyUI/models/clip/Qwen2.5-VL-7B-Instruct-UD-Q4_K_XL.gguf\n\
fi\n\
if [ ! -f /app/ComfyUI/models/vae/qwen_image_vae.safetensors ]; then\n\
    echo "Downloading VAE model..."\n\
    wget -q --show-progress https://huggingface.co/unsloth/Qwen-Image-2512-GGUF/resolve/main/qwen_image_vae.safetensors \\\n\
        -O /app/ComfyUI/models/vae/qwen_image_vae.safetensors\n\
fi\n\
echo "All models ready. Starting ComfyUI..."\n\
exec python main.py --listen 0.0.0.0 --port 8188' > /app/start.sh

RUN chmod +x /app/start.sh

# Expose port
EXPOSE 8188

# Start ComfyUI
CMD ["/bin/bash", "/app/start.sh"]
