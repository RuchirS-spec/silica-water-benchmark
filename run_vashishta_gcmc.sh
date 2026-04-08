#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")/Vashishta potential" && pwd)"
LOGS="$(cd "$(dirname "$0")" && pwd)/logs/vashishta"
mkdir -p "$LOGS"
cd "$DIR"
if [ ! -f cracking-mod.data ]; then
    echo "ERROR: cracking-mod.data not found. edit cracking.data first."
    exit 1
fi
lmp -in gcmc.lmp 2>&1 | tee "$LOGS/gcmc.log"
