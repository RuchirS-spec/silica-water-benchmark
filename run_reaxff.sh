#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")/Reaxff potential" && pwd)"
LOGS="$(cd "$(dirname "$0")" && pwd)/logs/reaxff"
mkdir -p "$LOGS"

cd "$DIR"

echo "=== ReaxFF: generate ==="
lmp -in generate.lmp | tee "$LOGS/generate.log"

echo "=== ReaxFF: cracking ==="
lmp -in cracking.lmp | tee "$LOGS/cracking.log"

echo "=== ReaxFF: gcmc ==="
lmp -in gcmc.lmp | tee "$LOGS/gcmc.log"

echo "done. logs in $LOGS"
echo "trajectories in $DIR/*.lammpstrj"
