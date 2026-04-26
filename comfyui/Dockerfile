# Use a more stable Python base image
FROM python:3.12-slim-bookworm

# Prevent interactive prompts and set Python behavior
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV ComfyUI_HOME=/app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    libgl1 \
    libglx-mesa0 \
    libglib2.0-0 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Argument to determine GPU platform during build
# Default to cpu if not provided
ARG GPU_PLATFORM=cpu

# Clone the repository
RUN git clone https://github.com/Comfy-Org/ComfyUI.git .

# Install Python dependencies
# We install them during build so the image is ready to go.
# Note: We use a single RUN command to keep the image size down.
RUN pip install --no-cache-dir --upgrade pip && \
    if [ "$GPU_PLATFORM" = "nvidia" ]; then \
        pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130; \
    elif [ "$GPU_PLATFORM" = "amd" ]; then \
        pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.0; \
    elif [ "$GPU_PLATFORM" = "intel" ]; then \
        pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/xpu; \
    else \
        pip install --no-cache-dir torch torchvision torchaudio; \
    fi && \
    pip install --no-cache-dir -r requirements.txt

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# App port
EXPOSE 8188

ENTRYPOINT ["/entrypoint.sh"]