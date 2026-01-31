#!/bin/bash


#WARNING this script has been written mostly by Gemini and corrected by an IT student, may not properly work


set -e

install_torch() {
    echo "-- Installing PyTorch for ${GPU_TYPE}--"

    case "${GPU_TYPE}" in
        "nvidia")
            # Nvidia works fine
            if command -v nvidia-smi &> /dev/null && nvidia-smi -L &> /dev/null; then
                echo "Nvidia card found. Installing CUDA version..."
                local nv_ver=$(nvidia-smi | grep -oP 'CUDA Version: \K[0-9]+\.[0-9]+' | sed 's/\.//' 2>/dev/null)
                custom_install "cu" "$CUDA_LATEST" "CUDA" "$nv_ver"
                return
            fi
            ;;
        "amd")
            if [ -c /dev/kfd ] && [ -d /sys/class/kfd ]; then
                echo "AMD card found. Installing ROCm version..."
                local am_ver=$(cat /opt/rocm/.info/version 2>/dev/null | cut -d'.' -f1,2)
                custom_install "rocm" "$ROCM_LATEST" "ROCm" "$am_ver"
                return
            fi
            ;;
        "intel")
            if [ -d /sys/class/drm/renderD128 ]; then
                echo "Intel Arc detected. Installing XPU version..."
                pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/xpu
                return
            fi
            ;;
        "cpu")
            pip install torch torchvision torchaudio
            ;;
    esac
    
    return 1
}

custom_install() {
    local COMPLEMENT=$1
    local LIB_DEFAULT_VERSION=$2
    local REQUIREMENT=$3
    local VERSION=$4

    # Falling back to default if version did not worked
    [ -z "$VERSION" ] && VERSION=$LIB_DEFAULT_VERSION

    local BASE_WHL_URL="https://download.pytorch.org/whl/"
    echo "--- Checking PyTorch Repository: ${REQUIREMENT} ${VERSION} ---"

    # Verify url
    if python3 -c "import urllib.request; urllib.request.urlopen('${BASE_WHL_URL}${COMPLEMENT}${VERSION}', timeout=5)" 2>/dev/null; then
        local FINAL_VERSION="${COMPLEMENT}${VERSION}"
        echo "Success: Found repository for ${REQUIREMENT} ${VERSION}"
    # Installs default version
    else
        local FINAL_VERSION="${COMPLEMENT}${LIB_DEFAULT_VERSION}"
        echo "Warning: ${COMPLEMENT}${VERSION} not found. Falling back to ${REQUIREMENT} ${LIB_DEFAULT_VERSION}"
    fi

    pip install torch torchvision torchaudio --index-url "${BASE_WHL_URL}${FINAL_VERSION}"
}

# ATOMIC SETUP: Only runs if the code is not yet present
if [ ! -d ".git" ]; then
    echo "--- FIRST BOOT DETECTED: STARTING SETUP ---"
    
    # clone the repository
    # if it fails, we remove the .git folder (if created) to allow a clean retry
    if ! git clone https://github.com/Comfy-Org/ComfyUI.git .; then
        echo "ERROR: Git clone failed. Cleaning up..."
        rm -rf .git
        exit 1
    fi

    # create Virtual Environment
    if python13 -m venv venv;then
        echo "-- Creating virtual environment --"
    else
        echo "ERROR: Failed to create virtual environment. Cleaning up..."
        rm -rf .git
        exit 1
    fi
    
    # activate and install dependencies
    source venv/bin/activate
    
    #update pip
    pip install --upgrade pip
    
    
    #install torch
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
exec python main.py --listen 0.0.0.0 --port 8188