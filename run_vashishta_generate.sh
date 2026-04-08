#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")/Vashishta potential" && pwd)"
LOGS="$(cd "$(dirname "$0")" && pwd)/logs/vashishta"
mkdir -p "$LOGS"
cd "$DIR"
lmp -in generate.lmp 2>&1 | tee "$LOGS/generate.log"
