#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")/MACE potential" && pwd)"
LOGS="$(cd "$(dirname "$0")" && pwd)/logs/mace"
mkdir -p "$LOGS"
cd "$DIR"
echo "=== MACE: cracking ==="
lmp -in cracking.lmp 2>&1 | tee "$LOGS/cracking.log"
echo "done. output: cracking.data"
echo "NOTE: run prepare_gcmc_data.py to create cracking-mod.data before gcmc"
