"""
Quick diagnostic: does the MACE model complete a forward pass at all?
Run this before trying LAMMPS to isolate model vs LAMMPS interface issues.

Usage: python test_mace_forward.py
"""
import torch
import time

print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available:  {torch.cuda.is_available()}")
device = torch.device("cpu")  # test on CPU first
print(f"Testing on:      {device}\n")

print("Loading model...", flush=True)
t0 = time.time()
model = torch.jit.load("MACE potential/MACE_SiOH.pt", map_location=device)
model.eval()
print(f"Loaded in {time.time()-t0:.1f}s")

# Derive the number of elements from the model itself
z_table = model.atomic_numbers.tolist()   # e.g. [1,2,...,83,89,...,94]
n_elements = len(z_table)
z_to_idx = {z: i for i, z in enumerate(z_table)}
print(f"Model covers {n_elements} elements (Z={z_table[0]}..{z_table[-1]})")
print(f"Si index: {z_to_idx[14]}, O index: {z_to_idx[8]}\n")

# Minimal fake system: 4 atoms (2 Si + 2 O) in a small box
n = 4
print(f"Building dummy input ({n} atoms: 2 Si + 2 O)...", flush=True)

data = {
    "positions":    torch.tensor([[0.0,0.0,0.0],[2.0,0.0,0.0],
                                  [1.0,1.0,0.0],[3.0,1.0,0.0]],
                                 dtype=torch.float64, device=device),
    "node_attrs":   torch.zeros(n, n_elements, dtype=torch.float64, device=device),
    "batch":        torch.zeros(n, dtype=torch.long, device=device),
    "ptr":          torch.tensor([0, n], dtype=torch.long, device=device),
    "edge_index":   torch.tensor([[0,1,2,3],[1,0,3,2]],
                                 dtype=torch.long, device=device),
    "shifts":       torch.zeros(2, 3, dtype=torch.float64, device=device),
    "unit_shifts":  torch.zeros(2, 3, dtype=torch.float64, device=device),
    "cell":         torch.eye(3, dtype=torch.float64, device=device).unsqueeze(0)*10,
    "head":         torch.tensor([0], dtype=torch.long, device=device),
}
# One-hot encode using the model's own element index table
data["node_attrs"][0, z_to_idx[14]] = 1.0  # Si
data["node_attrs"][1, z_to_idx[8]]  = 1.0  # O
data["node_attrs"][2, z_to_idx[14]] = 1.0  # Si
data["node_attrs"][3, z_to_idx[8]]  = 1.0  # O

local_or_ghost = torch.ones(n, dtype=torch.bool, device=device)

print("Running forward pass (timeout: 60s) ...", flush=True)
t0 = time.time()
try:
    with torch.no_grad():
        out = model(data, local_or_ghost)
    print(f"\nForward pass completed in {time.time()-t0:.1f}s")
    print("Energy output:", out.get("energy", out.get("total_energy", "key not found")))
    print("\nModel is working correctly.")
except Exception as e:
    print(f"\nForward pass FAILED after {time.time()-t0:.1f}s: {e}")
