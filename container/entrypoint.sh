#!/bin/bash


#WARNING this script has been written mostly by Gemini and corrected by an IT student, may not properly work


set -e

install_torch() {
    # Eliminamos lspci si no lo usas, nvidia-smi es más confiable aquí
    
    # 1. NVIDIA
    if command -v nvidia-smi &> /dev/null && nvidia-smi -L &> /dev/null; then
        # Extraemos versión de CUDA (ej: 12.1 -> 121)
        local nv_ver=$(nvidia-smi | grep -oP 'CUDA Version: \K[0-9]+\.[0-9]+' | sed 's/\.//' 2>/dev/null)
        dynamic_torch "nvidia-smi" "cu" "130" "CUDA" "$nv_ver"
        return
    fi

    # 2. AMD Radeon
    if [ -c /dev/kfd ] && [ -d /sys/class/kfd ]; then
        local am_ver=$(cat /opt/rocm/.info/version 2>/dev/null | cut -d'.' -f1,2)
        dynamic_torch "rocminfo" "rocm" "6.4" "ROCm" "$am_ver"
        return
    fi

    # 3. Intel ARC (Usualmente usa una URL fija /xpu)
    if [ -d /sys/class/drm/renderD128 ]; then
        echo "Intel Arc detected. Installing XPU version..."
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/xpu
        return
    fi

    echo "No high-performance GPU detected. Installing Default version..."
    pip install torch torchvision torchaudio
}

dynamic_torch() {
    local LIB_NAME=$1
    local COMPLEMENT=$2
    local LIB_DEFAULT_VERSION=$3
    local REQUIREMENT=$4
    local VERSION=$5

    # Fallback si VERSION está vacío
    [ -z "$VERSION" ] && VERSION=$LIB_DEFAULT_VERSION

    local BASE_WHL_URL="https://download.pytorch.org/whl/"
    echo "--- Checking PyTorch Repository: ${REQUIREMENT} ${VERSION} ---"

    # Verificación purista con Python (Sintaxis corregida en una sola línea)
    if python3 -c "import urllib.request; urllib.request.urlopen('${BASE_WHL_URL}${COMPLEMENT}${VERSION}', timeout=5)" 2>/dev/null; then
        local FINAL_VERSION="${COMPLEMENT}${VERSION}"
        echo "Success: Found repository for ${REQUIREMENT} ${VERSION}"
    else
        local FINAL_VERSION="${COMPLEMENT}${LIB_DEFAULT_VERSION}"
        echo "Warning: ${COMPLEMENT}${VERSION} not found. Falling back to ${REQUIREMENT} ${LIB_DEFAULT_VERSION}"
    fi

    pip install torch torchvision torchaudio --index-url "${BASE_WHL_URL}${FINAL_VERSION}"
}

# ATOMIC SETUP: Only runs if the code is not yet present
if [ ! -d ".git" ]; then
    echo "--- FIRST BOOT DETECTED: STARTING SETUP ---"
    
    # 1. Clone the repository
    # If it fails, we remove the .git folder (if created) to allow a clean retry
    if ! git clone https://github.com/Comfy-Org/ComfyUI.git .; then
        echo "ERROR: Git clone failed. Cleaning up..."
        rm -rf .git
        exit 1
    fi

    # 2. Create Virtual Environment
    python13 -m venv venv
    
    # 3. Activate and Install dependencies
    source venv/bin/activate
    
    #Update pip
    pip install --upgrade pip
    
    
    #install_torch
    if install_torch; then

    
        if [ -f "requirements.txt" ]; then
            echo "Installing requirements.txt..."
            pip install -r requirements.txt
        fi
        echo "--- SETUP COMPLETED SUCCESSFULLY ---"

    else 
        echo "FATAL: Installation failed. Cleaning up to allow retry..."
        # Erase git to make a first boot again
        rm -rf .git
        exit 1
    fi
else
    # SUBSEQUENT BOOTS: Just activate the existing environment
    source venv/bin/activate
fi

# Launch the application
echo "Starting application on port 8188..."
exec python main.py --listen 0.0.0.0 --port 8188