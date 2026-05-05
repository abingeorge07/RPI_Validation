#!/usr/bin/env bash
# Run every (binary × matching dataset) combination on the RPi.
# Output is written by each binary to <dataset_dir>/gem5_results.bin (default)
# unless overridden with output=<path>. We override per-run so the binary
# variants don't clobber each other.
#
# Mapping mirrors gem5_runner.py's _DATASET_BINARY_MAP and resolve_binary_path.
set -e
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$REPO_DIR/bin"
DATA="$REPO_DIR/datasets"
CFG="$REPO_DIR/config.yaml"
OUT="$REPO_DIR/results"
mkdir -p "$OUT"

run() {
    local binary="$1"; local dataset="$2"
    local tag="${binary}__${dataset}"
    local out_bin="$OUT/${tag}.bin"
    local log="$OUT/${tag}.log"
    echo ">>> $tag"
    "$BIN/$binary" "$DATA/$dataset" "$CFG" "output=$out_bin" 2>&1 | tee "$log"
}

# NMPC: per-N7/N12 binary × NMPC datasets
for h in N7 N12; do
    for ds in NMPC_origami NMPC_aliengo; do
        run "NMPC_controller_$h" "$ds"
    done
    for ds in NMPCGaitFreq_origami NMPCGaitFreq_aliengo; do
        run "NMPCGaitFreq_controller_$h" "$ds"
    done
done

# Default 8-DOF / 12-DOF (horizon-independent)
run Default8_controller  Default8_origami
run Default12_controller Default12_aliengo

# Constant velocity (horizon-independent)
run ConstVel_controller ConstVel_origami
run ConstVel_controller ConstVel_aliengo

# MPC high-level: per-MPC6/MPC10 binary × MPC datasets
for h in MPC6 MPC10; do
    for ds in MPC_origami MPC_aliengo; do
        run "MPC_controller_$h" "$ds"
    done
done

echo
echo "All runs complete. Results in $OUT/"
ls -la "$OUT/"
