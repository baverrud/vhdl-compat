# Tool-Specific Notes

Notes from testing each EDA tool. Not user documentation — internal reference for adapter development.

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

---

## ModelSim DE/PE (Siemens EDA)

Same CLI as Questa (`vcom`, `vsim`), same quirks. The only difference is licensing and feature set.

### Intel FPGA Edition note
The ModelSim bundled with Intel Quartus (e.g., "ModelSim 2020.1" = Quartus 21.1) is actually a newer build than the version number suggests. The vcom banner shows the actual build date (e.g., "Compiler 2021.02"). These Intel editions may include VHDL-2019 features backported from newer Siemens releases. **Verified:** ModelSim Intel FPGA Edition (vcom 2021.1) correctly handles both `-2008` and `-2019` flags and enforces standard boundaries:
- `-2008`: correctly rejects VHDL-2019 features (empty records, conditional analysis)
- `-2019`: correctly accepts VHDL-2019 features

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
