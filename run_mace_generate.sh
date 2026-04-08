#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")/MACE potential" && pwd)"
LOGS="$(cd "$(dirname "$0")" && pwd)/logs/mace"
mkdir -p "$LOGS"
cd "$DIR"
echo "=== MACE: generate ==="
lmp -in generate.lmp 2>&1 | tee "$LOGS/generate.log"
echo "done. output: generate.data"
