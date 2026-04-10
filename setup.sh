#!/bin/bash
set -euo pipefail

ENV="silica-water-test-env"

echo "setting up env..."

# check conda
command -v conda >/dev/null || { echo "conda not found"; exit 1; }

# create env if needed
if ! conda env list | grep -q "^$ENV "; then
    conda create -y -n "$ENV" python=3.11
fi

eval "$(conda shell.bash hook)"
conda activate "$ENV"

# install toolchain + lammps (fixing UCX issue)
if [ ! -f "$CONDA_PREFIX/bin/lmp" ]; then
    conda install -y -c conda-forge compilers binutils cmake pkg-config openmpi lammps 'ucx=*=*_false' || \
    conda install -y -c conda-forge lammps --override-channels
fi

# python deps
pip install --upgrade pip

# Install PyTorch — GPU build if CUDA is available, CPU-only otherwise
if command -v nvcc &>/dev/null; then
    CUDA_VER=$(nvcc --version | grep -oP 'release \K[0-9]+\.[0-9]+' | tr -d '.')
    # Map e.g. 12.1 -> cu121, 11.8 -> cu118; fall back to cu121
    case "$CUDA_VER" in
        118) TORCH_CUDA="cu118" ;;
        121) TORCH_CUDA="cu121" ;;
        124) TORCH_CUDA="cu124" ;;
        126) TORCH_CUDA="cu126" ;;
        *)   TORCH_CUDA="cu121" ;;
    esac
    echo "Installing GPU PyTorch (${TORCH_CUDA})..."
    pip install torch --index-url "https://download.pytorch.org/whl/${TORCH_CUDA}"
else
    echo "No CUDA found — installing CPU PyTorch..."
    pip install torch --index-url https://download.pytorch.org/whl/cpu
fi

pip install mace-torch

# build mace-lammps if missing
if ! lmp -help 2>&1 | grep -q "ML-MACE"; then
    echo "ML-MACE not found in LAMMPS binary. Building custom LAMMPS with MACE support..."

    conda install -y -c conda-forge cmake cxx-compiler mkl-devel fftw pkg-config binutils_linux-64

    BUILD="/tmp/lammps-mace-$(date +%s)"
    rm -rf "$BUILD"
    git clone --depth=1 -b mace https://github.com/ACEsuit/lammps.git "$BUILD/src"

    TORCH_CMAKE=$(python -c "import torch, os; print(os.path.join(torch.__path__[0],'share','cmake'))")

    mkdir -p "$BUILD/build"
    cd "$BUILD/build"

    # Enable CUDA if nvcc is available; also pass the CUDA compiler path explicitly
    if command -v nvcc &>/dev/null; then
        echo "CUDA detected — building with GPU support (USE_CUDA=ON)"
        CUDA_COMPILER=$(which nvcc)
        CUDA_FLAG="-D USE_CUDA=ON -D CMAKE_CUDA_COMPILER=${CUDA_COMPILER}"
    else
        echo "nvcc not found — building CPU-only (USE_CUDA=OFF)"
        CUDA_FLAG="-D USE_CUDA=OFF"
    fi

    cmake ../src/cmake \
      -D PKG_REAXFF=ON \
      -D PKG_ML-MACE=ON \
      -D PKG_MANYBODY=ON \
      -D PKG_MOLECULE=ON \
      -D PKG_MC=ON \
      -D PKG_KSPACE=ON \
      -D PKG_RIGID=ON \
      -D PKG_QEQ=ON \
      -D CMAKE_PREFIX_PATH="$TORCH_CMAKE" \
      -D CMAKE_INSTALL_PREFIX="$CONDA_PREFIX" \
      $CUDA_FLAG

    make -j"$(nproc || echo 2)"
    make install
    
    echo "LAMMPS build complete."
fi

mkdir -p results/trajectories results/outputs

echo "done. activate with: conda activate $ENV"
