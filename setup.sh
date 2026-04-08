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
pip install torch --index-url https://download.pytorch.org/whl/cpu
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

    cmake ../src/cmake \
      -D PKG_REAXFF=ON \
      -D PKG_ML-MACE=ON \
      -D CMAKE_PREFIX_PATH="$TORCH_CMAKE" \
      -D CMAKE_INSTALL_PREFIX="$CONDA_PREFIX" \
      -D USE_CUDA=OFF

    make -j"$(nproc || echo 2)"
    make install
    
    echo "LAMMPS build complete."
fi

mkdir -p results/trajectories results/outputs

echo "done. activate with: conda activate $ENV"
