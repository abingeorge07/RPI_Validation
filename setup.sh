#!/usr/bin/env bash
# Create the absolute path that MPC_controller and ConstVel_controller binaries
# reference at runtime for obstacle.json (compile-time MODEL_DIR is baked in).
# Loading obstacle.json is non-fatal — without this symlink the binaries warn
# and continue with empty obstacle data, which still produces valid timing.
set -e
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="/home/abg309/PhD/RCL/DSE_Quadruped/quadruped_dse/mechanical_properties"
sudo mkdir -p "$TARGET_DIR"
sudo ln -sfn "$REPO_DIR/models" "$TARGET_DIR/models"
echo "Linked $TARGET_DIR/models -> $REPO_DIR/models"