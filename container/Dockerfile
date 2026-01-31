#WARNING this dockerfile has been written mostly by Gemini and corrected by an IT student, may not properly work

# Debian 13 (Trixie)
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

# Symbolic link for the script
RUN ln -s /usr/bin/python3.13 /usr/bin/python13

WORKDIR /app

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# App port
EXPOSE 8188

ENTRYPOINT ["/entrypoint.sh"]