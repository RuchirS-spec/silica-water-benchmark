#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")/Vashishta potential" && pwd)"
LOGS="$(cd "$(dirname "$0")" && pwd)/logs/vashishta"
mkdir -p "$LOGS"

cd "$DIR"

echo "=== Vashishta: generate ==="
lmp -in generate.lmp | tee "$LOGS/generate.log"

echo "=== Vashishta: cracking ==="
lmp -in cracking.lmp | tee "$LOGS/cracking.log"

echo "=== Vashishta: gcmc ==="
lmp -in gcmc.lmp | tee "$LOGS/gcmc.log"

echo "done. logs in $LOGS"
echo "trajectories in $DIR/*.lammpstrj"
