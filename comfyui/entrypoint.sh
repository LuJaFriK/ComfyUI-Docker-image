#!/bin/bash

set -e

# Check if we are in a directory with a git repo
if [ -d ".git" ]; then
    echo "-- Checking for ComfyUI updates --"
    # Use 'git pull' to update the repository if there are changes.
    # We use 'git pull origin main' (or master) but since we don't know 
    # for sure which branch is active, we'll try to pull the current branch.
    # This is useful when the /app directory is a persistent volume.
    git fetch origin
    git merge origin/$(git rev-parse --abbrev-ref HEAD) || echo "-- Could not auto-merge updates, skipping --"
fi

echo "-- Starting ComfyUI --"

# Launch the application
# We use --listen 0.0.0.0 to allow connections from outside the container.
exec python main.py --listen 0.0.0.0 --port 8188