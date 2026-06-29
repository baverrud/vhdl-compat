# User Guide

This guide assumes you have never used this project before. It walks through every step from installation to reading reports.

---

## 1. What you need

- **Python 3.9 or newer** — [Download from python.org](https://www.python.org/downloads/)
- **Git** (optional, for cloning) — [Download from git-scm.com](https://git-scm.com/downloads)
- **An EDA tool** — Vivado, Questa, or ModelSim installed on your system

To check if Python is installed, open a terminal (Command Prompt, PowerShell, or Terminal) and run:

```bash
python --version
```

You should see something like `Python 3.11.0`. If you get an error, install Python first.

---

## 2. Get the project

### Option A: Clone with Git (recommended)

```bash
git clone https://github.com/baverrud/vhdl-compat.git
cd vhdl-compat
```

### Option B: Download ZIP

Download the ZIP from the GitHub page, extract it, then open a terminal in the extracted folder.

---

## 3. Set up the Python environment

A virtual environment keeps this project's dependencies separate from your system Python. Run these commands in the project folder:

**Windows (Command Prompt or PowerShell):**
```bash
python -m venv .venv
.venv\Scripts\activate
```

**Linux / macOS:**
```bash
python3 -m venv .venv
source .venv/bin/activate
```

You should see `(.venv)` appear at the beginning of your terminal prompt. This means the virtual environment is active.

Now install the project:

```bash
pip install -e .
```

After installation, use the `python scripts/` commands to run tests:

```bash
python scripts/run_tests.py --help
python scripts/generate_matrix.py --help
```

> **Note:** Always run these from the project root while the virtual environment is active. If you close your terminal, run the `activate` command again first.

---

## 4. Tell the project where your tools are

The project needs to know where your EDA tools are installed. You do this **once** by creating a small config file.

### Step 1: Copy the template

```bash
# Windows
copy tools\installed.example.toml tools\installed.toml

# Linux / macOS
cp tools/installed.example.toml tools/installed.toml
```

### Step 2: Edit the file

Open `tools/installed.toml` in any text editor (Notepad, VS Code, vim, etc.). It looks like this:

```toml
# Everything is commented out by default. Uncomment the sections you need
# and replace the paths with the actual locations on your system.

# [vivado."2024.1"]
# path = "C:/Xilinx/Vivado/2024.1/bin"
```

Uncomment the lines for your tool by removing the `#` at the start, and change the path to where the tool is actually installed.

**Example — Vivado 2024.1 on Windows:**

```toml
[vivado."2024.1"]
path = "C:/Xilinx/Vivado/2024.1/bin"
```

**Example — Vivado 2023.2 on Linux:**

```toml
[vivado."2023.2"]
path = "/opt/Xilinx/Vivado/2023.2/bin"
```

**Example — Questa 2024.1 on Windows:**

```toml
[questa."2024.1"]
path = "C:/questasim64_2024.1/win64"
```

**Finding the right path:** The path you enter must contain the tool's executable:
- For Vivado: the folder that contains `vivado` (or `vivado.exe` on Windows)
- For Questa/ModelSim: the folder that contains `vcom` and `vsim`

### Step 3: Verify

```bash
python scripts/run_tests.py --detect
```

You should see your tools listed:

```
Tool discovery:
  Manual config: FOUND

Tool            Version        Path
----------------------------------------------------------------------
Vivado          2024.1         C:/Xilinx/Vivado/2024.1/bin
```

If you see warnings about paths not found, double-check the paths in `tools/installed.toml`.

---

## 5. See what tests are available

```bash
python scripts/run_tests.py --list
```

This shows all 16 test files (and growing). Each test checks one specific VHDL feature.

```
Found 16 test(s):

Standard     Category                 Feature                                   Type
----------------------------------------------------------------------------------------------
VHDL-2008    expressions              ?? (condition operator)                   sim
VHDL-2008    processes                process(all) — automatic sensitivity list  sim
VHDL-2019    syntax                   Optional trailing semicolon               sim
...
```

- **Standard** — which VHDL version introduced this feature
- **Category** — what kind of feature (processes, generics, expressions, etc.)
- **Type** — `sim` (simulation test), `synth` (synthesis test), or `backcompat` (backwards compatibility)

---

## 6. Run tests

### Basic simulation test

```bash
vhdl-compat --tool vivado --version 2024.1 --std 2008 --mode sim
```

This runs all VHDL-2008 simulation tests using Vivado 2024.1. You will see output like:

```
============================================================
Running: Vivado 2024.1 | VHDL-2008 | modes=['sim']
============================================================
  [8/16] vhdl2008/processes/processes_process_all.vhd (sim)... ✓ PASS
  [9/16] vhdl2008/expressions/expressions_condition_operator.vhd (sim)... ✗ FAIL

Results: 5 pass, 0 partial, 1 fail (6 total)
Report saved: results/vivado-2024.1/vhdl2008-sim/report.json
```

### Using aliases (short names)

You can define an `alias` in `installed.toml` to save typing:

```toml
[["Vivado"]]
version = "2026.1"
alias = "v26"
path = "C:/Xilinx/2026.1/Vivado/bin"
```

Then run with the alias instead of the version number:

```bash
python scripts/run_tests.py --tool vivado --version v26 --std 2008 --mode sim
```

Aliases from `installed.toml`:
- `--tool vivado --version v26` → Vivado 2026.1
- `--tool vivado --version v25` → Vivado 2025.2
- `--tool vivado --version v23` → Vivado 2023.2
- `--tool questa --version questa` → Altera Questa Starter 2025.3
- `--tool modelsim --version modelsim` → Altera ModelSim Starter 2020.1

### Run with the latest detected version (omit --version)

```bash
vhdl-compat --tool vivado --std 2008 --mode sim
```

### Run only a specific category

```bash
python scripts/run_tests.py --tool vivado --version 2026.1 --std 2008 --mode sim --category processes
```

### Quick compile check (no simulation)

```bash
python scripts/run_tests.py --tool vivado --version 2026.1 --std 2008 --mode sim
```

This is faster — it only checks if the VHDL compiles, without running the simulation. Useful for quick sanity checks.

### Synthesis test

```bash
python scripts/run_tests.py --tool vivado --version 2026.1 --std 2008 --mode synth
```

This runs the VHDL through Vivado synthesis. Only works with tools that support synthesis (Vivado). Questa and ModelSim will report synthesis as N/A.

### Test multiple standards

```bash
python scripts/run_tests.py --tool vivado --version 2026.1 --std 2008 --std 2019 --mode sim
```

---

## 7. Understanding results

Each test has one of four outcomes:

| Symbol | Status | Meaning |
|---|---|---|
| ✓ PASS | `pass` | The feature works correctly |
| ⚠ PARTIAL | `partial` | The VHDL compiles but behaves incorrectly in simulation |
| ✗ FAIL | `fail` | The tool rejects the code (compile error) |
| ⬜ UNTESTED | `untested` | The test was not run (e.g., tool adapter not yet implemented) |

### Reading the report

Reports are saved in `results/{tool}-{version}/{standard}-{mode}/`:

```
results/
└── vivado-2024.1/
    └── vhdl2008-sim/
        ├── report.json    # Machine-readable (for scripts)
        └── report.md      # Human-readable (open in any text editor)
```

Open `report.md` to see a formatted summary with per-category breakdowns and details on any failing tests.

---

## 8. The comparison matrix

After running tests with multiple tools or versions, generate a combined comparison:

```bash
vhdl-compat-matrix --results-dir results/
```

This creates `MATRIX.md` — a table where each row is a VHDL feature and each column is a tool/version. You can open this in any Markdown viewer or on GitHub to see at a glance which tools support which features.

```
| Feature | Standard | Category | Vivado-2024.1 | Questa-2024.1 |
|---------|----------|----------|---------------|---------------|
| process(all) | 2008 | processes | ✅ | ✅ |
| Empty records | 2019 | types_2019 | ❌ | ✅ |
```

---

## 9. Testing backwards compatibility

Backwards-compatibility tests check that a tool correctly enforces standard boundaries. For example: a signal named `context` should compile in VHDL-2002 mode but be rejected in VHDL-2008 mode (because `context` became a reserved keyword).

```bash
# Run backcompat tests for VHDL-2008 mode
vhdl-compat --tool vivado --version 2024.1 --std 2008 --mode sim
```

The runner automatically includes backcompat tests. They appear with type `backcompat` in `--list`.

---

## 10. Common scenarios

### "I just installed Vivado and want to check what VHDL-2008 features it supports"

```bash
vhdl-compat --tool vivado --std 2008 --mode sim
```

### "I'm upgrading from Vivado 2023.2 to 2024.1 — did anything break?"

```bash
python scripts/run_tests.py --tool vivado --version v23 --std 2008 --mode sim
python scripts/run_tests.py --tool vivado --version v26 --std 2008 --mode sim
python scripts/generate_matrix.py
```

Compare the matrix — any feature that changed from ✅ to ❌ is a regression.

### "I want to check if Questa supports VHDL-2019"

```bash
python scripts/run_tests.py --tool questa --std 2019 --mode sim
```

### "I'm writing a paper comparing tool support"

```bash
# Run all tools you have configured
python scripts/run_tests.py --tool vivado --std 2008 --std 2019 --mode sim
python scripts/run_tests.py --tool questa --std 2008 --std 2019 --mode sim

# Generate the combined matrix
vhdl-compat-matrix

# MATRIX.md is your live comparison table
```

---

## Troubleshooting

### "python is not recognized"

The virtual environment is not active. Run:

**Windows:**
```bash
.venv\Scripts\activate
```

**Linux / macOS:**
```bash
source .venv/bin/activate
```

### "No EDA tools detected"

You haven't created `tools/installed.toml` yet. See section 4.

### "Tool adapter not yet implemented"

The project is in development. The actual tool runners (Vivado, Questa, ModelSim) are being built. Currently the framework is complete but tool-specific adapters are placeholders. All tests will show UNTESTED until the adapters are implemented.

### "pip install -e . fails"

Make sure you're in the project folder and the virtual environment is active. If you see errors about `tomli`, install it manually:

```bash
pip install tomli
pip install -e .
```
