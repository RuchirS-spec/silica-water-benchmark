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

    # Enable CUDA if nvcc is available.
    # We must add CUDA_ROOT to CMAKE_PREFIX_PATH so PyTorch's own Caffe2Config.cmake
    # can run find_package(CUDA) successfully — setting CUDA_TOOLKIT_ROOT_DIR alone
    # is not enough because Caffe2 uses its own cmake search path.
    # libcudart lives in lib64 for system CUDA installs and lib for conda CUDA.
    if command -v nvcc &>/dev/null; then
        echo "CUDA detected — building with GPU support (USE_CUDA=ON)"
        CUDA_COMPILER=$(which nvcc)
        CUDA_ROOT=$(dirname $(dirname "$CUDA_COMPILER"))
        # Find libcudart.so — skip the stubs directory
        CUDART=$(find "$CUDA_ROOT" -maxdepth 4 \
            \( -name "libcudart.so" -o -name "libcudart.so.12" -o -name "libcudart.so.11.0" \) \
            ! -path "*/stubs/*" 2>/dev/null | head -1)
        export CUDA_HOME="$CUDA_ROOT"
        export LD_LIBRARY_PATH="${CUDA_ROOT}/lib64:${CUDA_ROOT}/lib:${LD_LIBRARY_PATH:-}"
        echo "  nvcc:   $CUDA_COMPILER"
        echo "  root:   $CUDA_ROOT"
        echo "  cudart: ${CUDART:-not found, cmake will search}"
        CUDA_FLAG="-D USE_CUDA=ON \
          -D CMAKE_CUDA_COMPILER=${CUDA_COMPILER} \
          -D CUDA_TOOLKIT_ROOT_DIR=${CUDA_ROOT}"
        [ -n "$CUDART" ] && CUDA_FLAG="$CUDA_FLAG -D CUDA_CUDART_LIBRARY=${CUDART}"
        CMAKE_PREFIX="${TORCH_CMAKE};${CUDA_ROOT}"
    else
        echo "nvcc not found — building CPU-only (USE_CUDA=OFF)"
        CUDA_FLAG="-D USE_CUDA=OFF"
        CMAKE_PREFIX="${TORCH_CMAKE}"
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
      -D CMAKE_PREFIX_PATH="$CMAKE_PREFIX" \
      -D CMAKE_INSTALL_PREFIX="$CONDA_PREFIX" \
      -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
      $CUDA_FLAG

    make -j"$(nproc || echo 2)"
    make install
    
    echo "LAMMPS build complete."
fi

mkdir -p results/trajectories results/outputs

echo "done. activate with: conda activate $ENV"
