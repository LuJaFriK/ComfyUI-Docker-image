# Debian 13
FROM debian:trixie-slim

# Prevent interactive prompts and set Python behavior
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install Python 13, venv, git, and AI-related system dependencies
RUN apt-get update && apt-get install -y \
    python3.13 \
    python3.13-venv \
    git \
    libgl1 \
    libglx-mesa0 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# clone comfyui repository
RUN git clone https://github.com/Comfy-Org/ComfyUI.git .

# App port
EXPOSE 8188

ENTRYPOINT ["/entrypoint.sh"]