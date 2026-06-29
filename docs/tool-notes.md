# Tool-Specific Notes

Notes from testing each EDA tool. Not user documentation — internal reference for adapter development.

---

## Quick Reference: Running Tests

All commands run from project root:

```bash
# Questa simulation
python scripts/run_tests.py --tool questa --std 2008 --mode sim

# ModelSim simulation
python scripts/run_tests.py --tool modelsim --std 2008 --mode sim

# Vivado simulation (xvhdl + xelab + xsim)
python scripts/run_tests.py --tool vivado --std 2008 --mode sim

# Vivado synthesis (vivado -mode batch Tcl)
python scripts/run_tests.py --tool vivado --std 2008 --mode synth

# Run all standards for one tool
python scripts/run_tests.py --tool questa --std 2008 --std 2019 --mode sim

# Regenerate MATRIX.md from results/
python scripts/generate_matrix.py

# Discover installed tools
python scripts/run_tests.py --detect

# Direct xvhdl analysis (fast, no simulation)
xvhdl.bat -work work -2008 --nolog tests/vhdl2008/.../file.vhd
```

## Tool Configuration (`tools/installed.toml`)

TOML sections: `[section]` for single-instance tools, `[[section]]` for multi-version.

```toml
["Altera Questa Starter"]
version = "2025.3"
path = "C:/altera_pro/26.1/questa_fse/win64"

["Altera ModelSim Starter"]
version = "2020.1"
path = "C:/intelFPGA_pro/21.1/modelsim_ase/win32aloem"

[["Vivado"]]
version = "2026.1"
path = "C:/Xilinx/2026.1/Vivado/bin"

[["Vivado"]]
version = "2023.2"
path = "C:/Xilinx/Vivado/2023.2/bin"
```

---

## Questa Advanced Simulator (Siemens EDA)

### Command patterns

| Action | Command | Notes |
|---|---|---|
| Compile | `vcom -work work -2008 file.vhd` | Creates `work/` library if absent |
| Simulate | `vsim -c -do "run -all; quit" work.tb_name` | `-c` = console mode |
| Version | `vcom -version` | Output: "Questa ... vcom 2025.3 Compiler ..." |

### Quirks

- **Lockfile spam:** Questa Starter Edition outputs `". Lockfile is "C:/...work/_lock".` for every file in the work library on every compile. This floods stdout. Filter these out when parsing.
- **Non-zero exit on success:** Some editions return exit code 1 even for successful compilations with notes/warnings. Check for `** Error:` in output, not just exit code.
- **Work library must be clean on first run:** If `work/` exists from a previous run, delete `work/_lock` first or use `vdel -all`.
- **Starter Edition limits:** Some advanced features (code coverage, PSL) are restricted.

### Cleanup
- Delete `work/_lock` before each run
- `vdel -all` to clear the work library between runs
- Kill stuck `vsim` processes: `taskkill /F /IM vsimk.exe` (Windows)

### Test Results

| Standard | Sim | Key limitations |
|----------|-----|-----------------|
| VHDL-2000 | 1/1 | — |
| VHDL-2002 | 1/1 | — |
| VHDL-2008 | 35/38 | open in aggregates, default generic types, numeric_std_signed |
| VHDL-2019 | 28/52 | Limited 2019 support (many features not yet implemented) |

**Quirk:** Questa does NOT inherit library/use clauses across design units in the same file. Each entity/architecture needs its own `library ieee; use ...` block.

---

## ModelSim DE/PE (Siemens EDA)

Same CLI as Questa (`vcom`, `vsim`), same quirks. The only difference is licensing and feature set.

### Intel FPGA Edition note
The ModelSim bundled with Intel Quartus (e.g., "ModelSim 2020.1" = Quartus 21.1) is actually a newer build than the version number suggests. The vcom banner shows the actual build date (e.g., "Compiler 2021.02"). These Intel editions may include VHDL-2019 features backported from newer Siemens releases. **Verified:** ModelSim Intel FPGA Edition (vcom 2021.1) correctly handles both `-2008` and `-2019` flags and enforces standard boundaries:
- `-2008`: correctly rejects VHDL-2019 features (empty records, conditional analysis)
- `-2019`: correctly accepts VHDL-2019 features

### Test Results

| Standard | Sim | Key limitations |
|----------|-----|-----------------|
| VHDL-2008 | 30/38 | 5 extra failures vs Questa: generic types, generic subprograms, generic packages, enhanced port maps (OPEN), predefined vectors |
| VHDL-2019 | 0/52 | No VHDL-2019 support (version too old) |

---

## Vivado (AMD/Xilinx)

### Command patterns

| Action | Command | Notes |
|---|---|---|
| Compile | `xvhdl -2008 file.vhd` | No work library needed |
| Elaborate | `xelab -debug typical tb_name` | Creates `xsim.dir/` |
| Simulate | `xsim -R tb_name` | `-R` = run immediately |
| Synthesize | `vivado -mode batch -source script.tcl` | Tcl-driven |
| Version | `vivado -version` | Output: "Vivado v2024.1 (64-bit)" |

### Quirks

- **Journal files:** Vivado creates `vivado.jou` and `vivado.log` in the working directory. Clean these up after runs.
- **xsim.dir/:** Elaboration creates an `xsim.dir/` directory. Delete between runs.
- **License check:** `vivado -mode batch` needs a valid license. If none available, exits with error.
- **Slow startup:** Vivado batch mode takes 10-30 seconds just to initialize. Budget 120s timeout for synthesis.

### Cleanup
- Delete `vivado.jou`, `vivado.log`, `xsim.dir/` between runs
- `vivado -mode batch -source cleanup.tcl` to reset project state

### Synthesis Adapter Bugs (6 found & fixed)

All bugs in `scripts/vivado_adapter.py`, method `synthesize()`. Fixed in v1.0.

#### Bug 1: Wrong Part Number (P0)
**Symptom:** `ERROR: [Common 17-162] Invalid option value specified for '-part'`
**Fix:** Changed `xc7k70tfbg676-1` → `xc7a35tcsg324-1` (widely available Artix-7).

#### Bug 2: Missing Project (P0)
**Symptom:** `File '.../proj' does not exist`
**Fix:** Added `create_project -in_memory -part xc7a35tcsg324-1` at top of Tcl script.

#### Bug 3: Tcl Path Double-Nesting (P0)
**Symptom:** `couldn't read file "tmp\vivado-2026.1\synth_xxx.tcl"`
**Fix:** Resolve `tcl_path` to absolute, set `cwd` to tmp work directory.

#### Bug 4: Missing VHDL Standard Flag (P0)
**Symptom:** `this construct is only supported in VHDL 1076-2008`
**Fix:** Added `-vhdl2008` / `-vhdl2019` flag to `read_vhdl`.

#### Bug 5: std.env in Synthesis (P1)
**Symptom:** `'stop' is not declared`
**Fix:** Strip `use std.env.all;` from synthesis temp copy.

#### Bug 6: TB Entity Errors Blocking Synth (P1)
**Symptom:** `synth_design` says FAIL even though the RTL entity synthesizes cleanly.
**Fix:** Cut the synthesis temp copy at the TB_IMPORT marker.

#### Bonus: Error Capture (P2)
**Symptom:** Error messages showed Tcl echo lines (`# puts "ERROR: $err"`) instead of actual errors.
**Fix:** Skip lines starting with `#` and Vivado copyright lines when extracting errors.

### Test Results

#### Vivado 2026.1
| Standard | Compile (xvhdl) | Synth |
|----------|-----------------|-------|
| VHDL-2008 | 34/38 | ~27/35* |
| VHDL-2019 | 35/52 | 33/40 |

*estimated from sampling

**xvhdl compile failures (4):** open in aggregates, default generic types, context declarations, numeric_std_signed.

**Synth failures (7 VHDL-2019):** interface_views, subprogram_generics, declaration_regions, sequential_block, anonymous_types, inferred_constraints, closely_related — all cutting-edge 2019 features.

#### Vivado 2023.2
| Standard | Compile (xvhdl) | Synth |
|----------|-----------------|-------|
| VHDL-2008 | ~32/38 | ~21/35* |
| VHDL-2019 | ~25/52 | ~12/40* |

*estimated from sampling

**Notable difference vs 2026.1:** 2023.2 lacks synthesis support for generic types, numeric_std_unsigned, matching case, predefined vectors, unconstrained elements, fixed/floating-point packages.

---

## Process Management

### Timeout handling
- Compile: 30s timeout (vcom/xvhdl are fast)
- Simulate: 60s timeout (simple testbenches don't run long)
- Synthesize: 120s timeout (Vivado init is slow)

### Killing stuck processes

**Windows:**
```powershell
# Questa/ModelSim
taskkill /F /IM vsimk.exe
taskkill /F /IM vcom.exe

# Vivado
taskkill /F /IM vivado.exe
taskkill /F /IM xsim.exe
taskkill /F /IM xelab.exe
```

**Linux:**
```bash
pkill -9 vsimk
pkill -9 vivado
```

### Work directory cleanup

Before each run:
1. Delete `work/_lock` (Questa/ModelSim lock file)
2. Delete `vivado.jou`, `vivado.log`, `xsim.dir/` (Vivado artifacts)

After a run (optional, keep for debugging):
3. Delete `work/` library
4. Delete `tmp/{tool}-{version}/` entirely

The runner should:
- Create `tmp/{tool}-{version}/` if absent
- Delete lock files before starting
- Allow `--keep-tmp` flag to preserve artifacts for debugging

---

## Exit Code Interpretation

| Tool | Exit 0 | Exit 1 | Exit 2+ |
|---|---|---|---|
| Questa vcom | Success | Warning/note (sometimes success!) | Error |
| Questa vsim | Success | Simulation assertion failure | Fatal error |
| Vivado xvhdl | Success | Compile error | Fatal |
| Vivado vivado | Success | Tcl error | Fatal |

**Rule:** Never trust exit codes alone. Always grep output for error patterns.

---

## Test Infrastructure Architecture

```
tests/
  _TEMPLATE.vhd          Template with metadata header format
  vhdl2000/              1 test
  vhdl2002/              1 test
  vhdl2008/              38 tests (aggregates, expressions, generate, generics, misc, packages, ports, processes, types, verification)
  vhdl2019/              52 tests (assert_api, attributes, conditional_analysis, env, file_io, generics_2019, interfaces, protected_types, psl, sequential, syntax, types_2019, vectors)

scripts/
  run_tests.py           CLI entry point
  generate_matrix.py     MATRIX.md generator
  test_discovery.py      Parses VHD headers for TestInfo
  tool_discovery.py      Reads installed.toml, detects tools
  tool_runner.py         Abstract ToolRunner base class
  result_store.py        TestResult/TestStatus dataclasses
  questa_adapter.py      Questa/ModelSim (vcom + vsim)
  vivado_adapter.py      Vivado (xvhdl + xelab + xsim / vivado batch)
  _add_rtl.py            RTL entity injection script
```

## VHDL Test File Structure

Each test file has:
1. **Header** with metadata: `-- STD:`, `-- FEATURE:`, `-- CATEGORY:`, `-- SYNTH_ENTITY:`, `-- TEST_TYPE:`, `-- XREF:`
2. **RTL entity** (if `TEST_TYPE: both`): synthesizable entity demonstrating the feature
3. **TB entity** (suffix `_tb`): simulation testbench with assertions

### Key Conventions
- RTL entity = bare name (e.g., `condition_operator`)
- TB entity = name + `_tb` (e.g., `condition_operator_tb`)
- `SYNTH_ENTITY:` tag = RTL entity name (used by Vivado synth for `synth_design -top`)
- `TEST_TYPE: sim` = simulation-only, no RTL entity needed
- `TEST_TYPE: both` = has both RTL and TB
- Each entity must re-import its own `library ieee; use ...` (Questa cross-unit limitation)

## Known Issues / Improvements

1. **Vivado synth full suite:** VHDL-2008 synth only sampled (12/35). Full suite takes ~22 min.
2. **Vivado sim hangs via run_tests.py:** The `simulate` method (xelab + xsim) sometimes hangs. Workaround: use `xvhdl` analysis-only for compile checks.
3. **`_add_rtl.py` RTL_CODE outdated:** Some RTL entities in the dict are simpler than what's actually in test files. Re-running `_add_rtl.py` may downgrade some RTL.
4. **Vivado 2000/2002:** Protected types and buffer ports not supported by Vivado tools (expected — these are simulation-focused standards).
