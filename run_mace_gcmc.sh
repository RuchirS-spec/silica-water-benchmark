#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")/MACE potential" && pwd)"
LOGS="$(cd "$(dirname "$0")" && pwd)/logs/mace"
mkdir -p "$LOGS"
cd "$DIR"
python prepare_gcmc_data.py 2>&1 | tee "$LOGS/prepare_gcmc.log"
if [ ! -f cracking-mod.data ]; then
    echo "ERROR: cracking-mod.data not created."
    exit 1
fi
lmp -in gcmc.lmp 2>&1 | tee "$LOGS/gcmc.log"
