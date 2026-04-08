#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")/Reaxff potential" && pwd)"
LOGS="$(cd "$(dirname "$0")" && pwd)/logs/reaxff"
mkdir -p "$LOGS"
cd "$DIR"
echo "=== ReaxFF: cracking ==="
lmp -in cracking.lmp 2>&1 | tee "$LOGS/cracking.log"
echo "done. output: cracking.data"
echo "NOTE: create cracking-mod.data before running gcmc"
