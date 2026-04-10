#!/bin/bash
set -euo pipefail
DIR="$(cd "$(dirname "$0")/MACE potential" && pwd)"
LOGS="$(cd "$(dirname "$0")" && pwd)/logs/mace"
mkdir -p "$LOGS"

# lmp is linked against libtorch.so at build time; add PyTorch's lib dir so
# the dynamic linker can find it at runtime.
TORCH_LIB=$(python3 -c "import torch, os; print(os.path.join(torch.__path__[0], 'lib'))")
export LD_LIBRARY_PATH="${TORCH_LIB}:${LD_LIBRARY_PATH:-}"

cd "$DIR"
lmp -in generate.lmp 2>&1 | tee "$LOGS/generate.log"
