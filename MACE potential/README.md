# MACE Potential — Silica-Water Benchmark

This folder contains LAMMPS input scripts to run the same three-stage silica-water
simulation pipeline as the Vashishta and ReaxFF benchmarks, but using the
**MACE-MP-0** machine learning interatomic potential.

## Prerequisites

### 1. LAMMPS with MACE support
Your LAMMPS build must include the MACE pair style. This requires compiling
LAMMPS from source with either:
- **`PKG_ML-MACE`** (original interface) — uses `pair_style mace`
- **`PKG_ML-IAP`** (unified ML interface) — uses `pair_style mliap`

This guide assumes the original `pair_style mace` interface.

### 2. MACE Model File (`.pt` format)
The LAMMPS MACE pair style requires a TorchScript (`.pt`) model file.
If you have a `.model` file, convert it first:

```bash
# Install MACE
pip install mace-torch

# Convert an existing .model file to the LAMMPS-compatible .pt format
python -m mace.cli.create_lammps_model \
    MACE_SiOH.model \
    --output MACE_SiOH.pt
```

Place `MACE_SiOH.pt` in this directory. All three scripts reference this filename.

## Pipeline

### Stage 1: Structure Generation (`generate.lmp`)
Creates amorphous SiO₂ via melt-quench:
- 240 Si + 480 O atoms in a 36×18×18 Å box
- Melt at 6000 K (10 ps) → Cool to 300 K (30 ps) → NPT equilibrate (10 ps)
- **Units:** metal (eV, ps, Å), **Timestep:** 1 fs
- **Output:** `generate.data`

```bash
lmp -in generate.lmp
```

### Stage 2: Uniaxial Deformation (`cracking.lmp`)
Strains the silica box to create fracture surfaces:
- Strain rate: 0.005 /ps along x-axis
- 50 ps of NVT deformation at 300 K
- **Output:** `cracking.data`

```bash
lmp -in cracking.lmp
```

### Stage 3: Data Preparation → GCMC (`gcmc.lmp`)
First, convert the cracking data file to support water atom types:

```bash
python prepare_gcmc_data.py
```

Then run GCMC water insertion:
- Chemical potential μ = -0.5 eV
- 25 ps of GCMC with 100 insertion attempts every 100 steps
- Flexible water (no SHAKE — MACE handles intramolecular interactions)
- 3 seed water molecules pre-inserted
- **Output:** `gcmc_mace_traj.lammpstrj`

```bash
lmp -in gcmc.lmp
```

## Key Differences from Other Potentials

| Feature | Vashishta | ReaxFF | **MACE** |
|---|---|---|---|
| Units | metal | real | **metal** |
| Timestep | 1 fs | 0.25 fs | **1 fs** |
| Charge model | Fixed | QEq (every step) | **Implicit (learned)** |
| Bond breaking | No | Yes | **Yes (learned)** |
| Extra fixes | None | `fix qeq/reaxff` | **None** |
| Memory | ~15 MB/rank | ~617 MB/rank | **Depends on model** |
| `atom_style` (gen/crack) | full | full | **atomic** |
| `atom_style` (gcmc) | full | full | **full** |

## File Listing

| File | Purpose |
|---|---|
| `generate.lmp` | Stage 1: Melt-quench SiO₂ generation |
| `cracking.lmp` | Stage 2: Uniaxial deformation |
| `gcmc.lmp` | Stage 3: GCMC water adsorption |
| `H2O.mol` | Water molecule template (OW + 2×HW) |
| `prepare_gcmc_data.py` | Converts `cracking.data` → `cracking-mod.data` |
| `MACE_SiOH.pt` | MACE model file (**you must provide this** — convert from `.model` with `create_lammps_model`) |
| `README.md` | This file |

## Notes

- **No charge equilibration**: Unlike ReaxFF, MACE does not require `fix qeq`.
  Electrostatics are captured implicitly in the learned potential energy surface.
- **`no_domain_decomposition`**: Used in `pair_style mace` to build a proper
  periodic graph. Recommended for single-node runs.
- **GPU acceleration**: All three scripts pass `device cuda` in `pair_coeff`,
  which routes the PyTorch MACE computation to the GPU. This requires LAMMPS
  to be built with `USE_CUDA=ON` (see `setup.sh` — it auto-detects `nvcc`).
  No Kokkos flags are needed; the GPU is managed by PyTorch directly.
- **Model file format**: LAMMPS requires a TorchScript `.pt` file, not a raw
  `.model` file. Use `mace.cli.create_lammps_model` to convert if needed.
- **`atom_modify map yes`**: Required for MACE to correctly map atomic indices.
