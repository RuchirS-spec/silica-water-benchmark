#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")/MACE potential" && pwd)"
LOGS="$(cd "$(dirname "$0")" && pwd)/logs/mace"
mkdir -p "$LOGS"

cd "$DIR"

echo "=== MACE: generate ==="
lmp -in generate.lmp | tee "$LOGS/generate.log"

echo "=== MACE: cracking ==="
lmp -in cracking.lmp | tee "$LOGS/cracking.log"

echo "=== MACE: prepare gcmc data ==="
python prepare_gcmc_data.py | tee "$LOGS/prepare_gcmc.log"

echo "=== MACE: gcmc ==="
lmp -in gcmc.lmp | tee "$LOGS/gcmc.log"

echo "done. logs in $LOGS"
echo "trajectories in $DIR/*.lammpstrj"
