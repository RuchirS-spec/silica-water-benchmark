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
print(f"Loaded in {time.time()-t0:.1f}s\n")

# Minimal fake system: 4 atoms (2 Si + 2 O) in a small box
# Matches what LAMMPS passes to MACE's forward()
n = 4
print(f"Building dummy input ({n} atoms: 2 Si + 2 O)...", flush=True)

data = {
    "positions":        torch.tensor([[0.0,0.0,0.0],[2.0,0.0,0.0],
                                      [1.0,1.0,0.0],[3.0,1.0,0.0]],
                                     dtype=torch.float64, device=device),
    "node_attrs":       torch.zeros(n, 95, dtype=torch.float64, device=device),
    "batch":            torch.zeros(n, dtype=torch.long, device=device),
    "edge_index":       torch.tensor([[0,1,2,3],[1,0,3,2]],
                                     dtype=torch.long, device=device),
    "shifts":           torch.zeros(2, 3, dtype=torch.float64, device=device),
    "unit_shifts":      torch.zeros(2, 3, dtype=torch.float64, device=device),
    "cell":             torch.eye(3, dtype=torch.float64, device=device).unsqueeze(0)*10,
}
# Set node features for Si (Z=14) and O (Z=8)
data["node_attrs"][0, 14] = 1.0  # Si
data["node_attrs"][1, 8]  = 1.0  # O
data["node_attrs"][2, 14] = 1.0  # Si
data["node_attrs"][3, 8]  = 1.0  # O

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
