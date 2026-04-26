# ComfyUI Docker Project - Improvements & Fixes

This documentation outlines the recent architectural improvements and fixes applied to the ComfyUI Docker implementation. The goal of these changes was to transform the project from a "runtime-install" model (which was slow and fragile) to a "build-time-ready" model (which is fast, stable, and follows Docker best practices).

## 🚀 Overview

This project provides a highly optimized, multi-platform Docker environment for running **ComfyUI**. It supports various hardware accelerators, including **NVIDIA (CUDA)**, **AMD (ROCm)**, **Intel (XPU)**, and standard **CPU** execution, using Docker Compose profiles.

---

## 🛠️ Recent Major Fixes & Optimizations

The recent update addressed several critical bottlenecks and stability issues:

### 1. Build-Time Dependency Injection (Performance Optimization)
*   **Old Way:** The `entrypoint.sh` script attempted to install PyTorch and all requirements every time a container started. This caused massive delays (minutes of waiting) and made the container'unusable without a perfect internet connection at every boot.
*   **New Way:** All heavy dependencies (PyTorch, torchvision, torchaudio, and ComfyUI requirements) are now installed during the `docker build` phase. 
*   **Result:** Containers now start almost instantaneously.

### 2. Multi-Platform Hardware Support
The `Dockerfile` now utilizes `ARG GPU_PLATFORM` to allow the build engine to select the correct PyTorch binaries for your specific hardware during the build process:
*   **NVIDIA:** Installs `cu130` (CUDA 13) optimized binaries.
*   **AMD:** Installs `rocm6.0` optimized binaries.
*   **Intel:** Installs `xpu` optimized binaries.
*   **CPU:** Installs the standard CPU-only PyTorch binaries.

### 3. Enhanced Volume Management (Data Persistence)
We moved away from a single monolithic `data` volume to a decoupled structure. This prevents the "all-or-nothing" risk and makes managing large AI models much easier:
*   `comfy_models`: Dedicated volume for weights (Checkpoints, LoRAs, etc.).
*   `comfy_input`: For your input images/videos.
*   `comfy_output`: For generated results.
*   `comfy_data`: For the core ComfyUI application state and custom nodes.

### 4. Improved Base Image Stability
*   **Old Way:** Used `debian:trixie-slim` (Debian 13 - Testing/Unstable).
*   **New Way:** Switched to `python:3.12-slim-bookbre`. This provides a much more predictable and stable runtime environment for Python-based AI workloads.

---

## 📖 How to Use

### Prerequisites
*   Docker and Docker Compose installed.
*   **For NVIDIA:** [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) installed.
*   **For AMD:** Appropriate ROCm drivers installed on the host.

### Building and Running

You must specify a **profile** to tell Docker which hardware configuration to use.

#### 1. NVIDIA GPU Profile
```bash
docker compose --profile nvidia up --build
```

#### 2. AMD GPU Profile
```bash
docker compose --profile amd up --build
```

#### 3. Intel GPU Profile
```bash
docker compose --profile intel up --build
```

#### 4. CPU Only Profile
```bash
docker compose --profile cpu up --build
```

### Accessing the UI
Once the container is running, open your browser and navigate to:
`http://localhost:8188`

---

## 🔄 Maintenance & Updates

### Updating ComfyUI
Because the application directory is mapped to a persistent volume, the `entrypoint.sh` script will automatically attempt to `git fetch` and `git merge` the latest changes from the official ComfyUI repository every time the container starts. This ensures you always have the latest nodes and features without rebuilding the image.

### Adding New Models
You can place your models directly into the `comfy_models` volume on your host or via the `docker compose` volume mapping. The easiest way is to map a local folder in your `docker-compose.yml` if you want to manage them manually.

---

**Note:** *This project is designed for high-performance AI workflows. Ensure your host hardware has sufficient VRAM/RAM for the models you intend to run.*