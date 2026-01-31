#!/bin/bash


#WARNING this script has been written mostly by Gemini and corrected by an IT student, may not properly work


set -e

install_torch() {

    local gpu_info=$(lspci | grep -Ei 'vga|3d|display')
    
    # 1. NVIDIA
    if echo "$gpu_info" | grep -qi 'nvidia'; then
        local nv_ver=$(nvidia-smi | grep -oP 'CUDA Version: \K[0-9]+\.[0-9]+' | tr -d '.' 2>/dev/null)
        install_torch_dynamic "nvidia-smi" "cu" "130" "CUDA" "$nv_ver"
        return
    fi

    # 2. AMD
    if echo "$gpu_info" | grep -qiE 'amd|radeon'; then
        local am_ver=$(cat /opt/rocm/.info/version 2>/dev/null | cut -d'.' -f1,2)
        install_torch_dynamic "rocminfo" "rocm" "6.4" "ROCm" "$am_ver"
        return
    fi

    # 3. Intel Arc
    if echo "$gpu_info" | grep -qi 'intel' && echo "$gpu_info" | grep -qiE 'arc|dg1|dg2|alchemist'; then
        echo "Intel Arc detected. Installing XPU version..."
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/xpu
        return
    fi

    echo "No high-performance GPU detected. Installing CPU version..."
    pip install torch torchvision torchaudio
}

install_torch_dynamic() {
    local LIB_NAME=$1
    local COMPLEMENT=$2
    local LIB_DEFAULT_VERSION=$3
    local REQUIREMENT=$4
    local VERSION=$5

    # Check if the tool exists before proceeding
    if ! command -v "$LIB_NAME" &> /dev/null; then
        echo "Error: ${LIB_NAME} not found. Using default ${REQUIREMENT} ${LIB_DEFAULT_VERSION}"
        VERSION=$LIB_DEFAULT_VERSION
    fi

    # Fallback if VERSION is empty
    if [ -z "$VERSION" ]; then VERSION=$LIB_DEFAULT_VERSION; fi

    local BASE_WHL_URL="https://download.pytorch.org/whl/"
    echo "--- Checking PyTorch Repository Compatibility ---"

    # Check URL availability
    if curl --output /dev/null --silent --head --fail "${BASE_WHL_URL}${COMPLEMENT}${VERSION}"; then
        local FINAL_URL="${BASE_WHL_URL}${COMPLEMENT}${VERSION}"
        echo "Success: Found repository for ${REQUIREMENT} ${VERSION}"
    else
        local FINAL_URL="${BASE_WHL_URL}${COMPLEMENT}${LIB_DEFAULT_VERSION}"
        echo "Warning: Version ${VERSION} not found. Falling back to: ${LIB_DEFAULT_VERSION}"
    fi

    pip install torch torchvision torchaudio --index-url "$FINAL_URL"
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
    
    
    install_torch
    
    if [ -f "requirements.txt" ]; then
        echo "Installing requirements.txt..."
        pip install -r requirements.txt
    fi
    
    echo "--- SETUP COMPLETED SUCCESSFULLY ---"
else
    # SUBSEQUENT BOOTS: Just activate the existing environment
    source venv/bin/activate
fi

# Launch the application
echo "Starting application on port 8188..."
exec python main.py --port 8188