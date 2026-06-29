# Tool Configuration Guide

## Overview

Each EDA tool is configured via a single TOML file in `tools/`. The Python test runner reads these files to know how to invoke the tool.

## Manual Installation Config (`installed.toml`)

To declare fixed tool paths (bypassing automatic detection), edit `tools/installed.toml`:

```toml
[["Vivado"]]
version = "2026.1"
alias = "v26"       # optional: short name for --version
path = "C:/Xilinx/2026.1/Vivado/bin"

["Altera Questa Starter"]
version = "2025.3"
alias = "questa"     # optional: short name for --version
path = "C:/altera_pro/26.1/questa_fse/win64"
```

Once configured, use the alias with:

```bash
python scripts/run_tests.py --tool vivado --version v26 --std 2008 --mode sim
```

> **Note:** The `alias` field is optional. If omitted, you must use the full `version` string to select this installation.

---

## Tool Adapter Config

The schema below is for tool *adapter* files (`tools/*.toml`), which tell the runner how to invoke a tool type (commands, flags, paths). This is separate from `installed.toml`.

```toml
# tools/vivado.toml

[tool]
name = "Vivado"
vendor = "AMD/Xilinx"
type = "both"                    # "sim" | "synth" | "both"

# ---------------------------------------------------------------------------
# Path discovery — the runner tries these in order until it finds the tool
# ---------------------------------------------------------------------------
[paths]
environment_variable = "XILINX_VIVADO"   # $XILINX_VIVADO/bin
search_paths = [
    "C:/Xilinx/Vivado/*/bin",           # Wildcards supported
    "/opt/Xilinx/Vivado/*/bin",
]
windows_default = "C:/Xilinx/Vivado/2024.1/bin"
linux_default = "/opt/Xilinx/Vivado/2024.1/bin"

# ---------------------------------------------------------------------------
# Standard flags — added to every invocation for a given VHDL standard
# ---------------------------------------------------------------------------
[standards]
2008_flags = ["-2008"]
2019_flags = ["-2019"]

# ---------------------------------------------------------------------------
# Simulation commands
# ---------------------------------------------------------------------------
[sim]
analysis = "xvhdl"               # Command to analyze/compile a VHDL file
analysis_flags = ["-work", "work"]
analysis_file_flag = ""           # How to pass the file (empty = positional arg)
analysis_output_pattern = "ERROR:" # Grep for this in stdout/stderr to detect errors

elaboration = "xelab"             # Command to elaborate the design
elaboration_flags = ["-debug", "typical"]

run = "xsim"                       # Command to run simulation
run_flags = ["-R"]                 # -R = run immediately
run_output_pass_pattern = "PASS:"   # If this appears in output, test passes
run_output_fail_pattern = "FAIL:"   # If this appears in output, test fails

# ---------------------------------------------------------------------------
# Synthesis commands (optional — omit if tool is sim-only)
# ---------------------------------------------------------------------------
[synth]
tcl_wrapper = true                 # Generate Tcl script for batch mode
tcl_commands = [
    "read_vhdl -vhdl2008 {file}",
    "synth_design -top {top} -part xc7k70t-fbg676-1",
]
error_pattern = "ERROR:"
