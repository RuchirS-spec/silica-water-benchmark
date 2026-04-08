"""
Prepare GCMC Data File for MACE
================================
Converts cracking.data (atom_style atomic, 2 types: Si, O)
into cracking-mod.data (atom_style full, 4 types: Si, O, OW, HW)
so that the GCMC script can insert water molecules as types 3 and 4.

Usage:
    python prepare_gcmc_data.py
"""

import sys
import os


def convert_data_file(input_file="cracking.data", output_file="cracking-mod.data"):
    if not os.path.exists(input_file):
        print(f"ERROR: {input_file} not found. Run generate.lmp and cracking.lmp first.")
        sys.exit(1)

    with open(input_file, "r") as f:
        lines = f.readlines()

    new_lines = []
    in_atoms = False
    in_masses = False
    atoms_done = False
    masses_done = False

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Update atom types count: 2 → 4
        if "atom types" in stripped and not atoms_done:
            parts = stripped.split()
            new_lines.append(f"4 atom types\n")
            atoms_done = True
            i += 1
            continue

        # Expand Masses section to include OW and HW
        if stripped == "Masses":
            in_masses = True
            new_lines.append(line)
            i += 1
            # skip blank line
            new_lines.append(lines[i])
            i += 1
            # Read existing masses (2 lines for Si and O)
            while i < len(lines) and lines[i].strip():
                new_lines.append(lines[i])
                i += 1
            # Add water masses
            new_lines.append("3 15.9994\n")   # OW — same mass as O
            new_lines.append("4 1.0080\n")    # HW
            new_lines.append("\n")
            masses_done = True
            i += 1
            continue

        # Convert Atoms section from atomic → full format
        if stripped == "Atoms":
            in_atoms = True
            new_lines.append("Atoms  # full\n")
            i += 1
            # skip blank/comment line
            new_lines.append(lines[i])
            i += 1
            while i < len(lines) and lines[i].strip():
                parts = lines[i].split()
                # atomic format: atom-ID type x y z [ix iy iz]
                # full format:   atom-ID mol-ID type charge x y z [ix iy iz]
                atom_id = parts[0]
                atom_type = parts[1]
                coords = parts[2:5]
                image_flags = parts[5:] if len(parts) > 5 else []

                # mol-ID = 0 (no molecule for silica), charge = 0.0
                full_line = f"{atom_id} 0 {atom_type} 0.0 {' '.join(coords)}"
                if image_flags:
                    full_line += f" {' '.join(image_flags)}"
                new_lines.append(full_line + "\n")
                i += 1
            in_atoms = False
            if i < len(lines):
                new_lines.append(lines[i])  # blank line
            i += 1
            continue

        # Convert Velocities section (same format in atomic and full)
        new_lines.append(line)
        i += 1

    # Write output
    with open(output_file, "w") as f:
        f.writelines(new_lines)

    print(f"✓ Converted {input_file} → {output_file}")
    print(f"  - Expanded atom types: 2 → 4 (added OW, HW)")
    print(f"  - Converted atom format: atomic → full")
    print(f"  - Added masses for types 3 (OW=15.9994) and 4 (HW=1.0080)")


if __name__ == "__main__":
    convert_data_file()
