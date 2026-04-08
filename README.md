# Silica-Water Benchmark

Benchmarking three interatomic potentials for amorphous SiO₂ fracture and water adsorption using LAMMPS.

## Potentials

| Potential | Units | Timestep | Charge Model |
|-----------|-------|----------|--------------|
| Vashishta | metal | 1 fs | Fixed |
| ReaxFF | real | 0.25 fs | QEq |
| MACE | metal | 1 fs | Learned |

## Pipeline

Each potential runs the same three-stage simulation:

1. **Generate** — melt-quench to create amorphous SiO₂
2. **Cracking** — uniaxial deformation to fracture the sample
3. **GCMC** — Grand Canonical Monte Carlo water insertion into the crack

## Setup

```bash
bash setup.sh
conda activate silica-water-test-env
```

This installs LAMMPS, PyTorch, and mace-torch into a conda environment.

## Running

```bash
bash run_vashishta.sh
bash run_reaxff.sh
bash run_mace.sh
```

Each script runs all three stages sequentially. Logs go to `logs/<potential>/` and Ovito-compatible `.lammpstrj` trajectories are written inside each potential's directory.

## Files

```
setup.sh              # environment setup
run_vashishta.sh      # run all 3 stages for Vashishta
run_reaxff.sh         # run all 3 stages for ReaxFF
run_mace.sh           # run all 3 stages for MACE
Vashishta potential/  # input scripts + force field
Reaxff potential/     # input scripts + force field
MACE potential/       # input scripts + model + data prep
```

## References

- Vashishta potential: P. Vashishta et al., *J. Appl. Phys.* 68, 3262 (1990)
- ReaxFF: A.C.T. van Duin et al., *J. Phys. Chem. A* 105, 9396 (2001)
- MACE: I. Batatia et al., *NeurIPS* (2022)
- LAMMPS Tutorials: S. Gravelle et al., *LiveCoMS* 6(1), 3037 (2025)
