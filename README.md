# Silica-Water Benchmark

Benchmarking three interatomic potentials for amorphous SiO₂ fracture and water adsorption using LAMMPS.

## Potentials

| Potential | Units | Timestep | Charge Model |
|-----------|-------|----------|--------------|
| Vashishta | metal | 1 fs | Fixed |
| ReaxFF | real | 0.25 fs | QEq |
| MACE | metal | 1 fs | Learned |

## Setup

```bash
bash setup.sh
conda activate silica-water-test-env
```

## Pipeline

Each potential runs three stages. Run them one at a time — stage 2 produces `cracking.data` which must be edited into `cracking-mod.data` before stage 3.

### Stage 1: Generate (melt-quench amorphous SiO₂)

```bash
bash run_vashishta_generate.sh
bash run_reaxff_generate.sh
bash run_mace_generate.sh
```

### Stage 2: Cracking (uniaxial deformation)

```bash
bash run_vashishta_cracking.sh
bash run_reaxff_cracking.sh
bash run_mace_cracking.sh
```

After cracking, edit `cracking.data` → `cracking-mod.data` (add water atom types).
For MACE, `prepare_gcmc_data.py` handles this automatically in stage 3.

### Stage 3: GCMC (water insertion)

```bash
bash run_vashishta_gcmc.sh
bash run_reaxff_gcmc.sh
bash run_mace_gcmc.sh
```

Logs go to `logs/<potential>/`. Ovito trajectories (`.lammpstrj`) are in each potential's directory.

## References

- Vashishta: P. Vashishta et al., *J. Appl. Phys.* 68, 3262 (1990)
- ReaxFF: A.C.T. van Duin et al., *J. Phys. Chem. A* 105, 9396 (2001)
- MACE: I. Batatia et al., *NeurIPS* (2022)
- LAMMPS Tutorials: S. Gravelle et al., *LiveCoMS* 6(1), 3037 (2025)
