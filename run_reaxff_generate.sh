#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")/Reaxff potential" && pwd)"
LOGS="$(cd "$(dirname "$0")" && pwd)/logs/reaxff"
mkdir -p "$LOGS"
cd "$DIR"
echo "=== ReaxFF: generate ==="
lmp -in generate.lmp 2>&1 | tee "$LOGS/generate.log"
echo "done. output: generate.data"
