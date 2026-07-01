# Running ModelSim + UVVM

Verified working 2026-07-01 with the `bitvis_uart` UART VVC demo.

## ModelSim install (from `tools/installed.toml`)

- "Altera ModelSim Starter" 2020.1, alias `modelsim`
- Path: `C:/intelFPGA_pro/21.1/modelsim_ase/win32aloem` (32-bit `vsim.exe`, `vcom.exe`, `vmap.exe`)
- Stock ini: `C:/intelFPGA_pro/21.1/modelsim_ase/modelsim.ini`

## CRITICAL GOTCHA: read-only `modelsim.ini`

The install-dir `modelsim.ini` is read-only. `vmap` tries to modify it and fails
with `EACCES` lock errors (`Failed to open lock file ..._lock`).

**Fix:** copy `modelsim.ini` into the local working/sim dir and set the env var
`$env:MODELSIM` to the absolute path of that local copy. Then `vmap` writes locally.

## Verified working flow (bitvis_uart UART VVC demo)

```powershell
$env:PATH = "C:/intelFPGA_pro/21.1/modelsim_ase/win32aloem;" + $env:PATH
Remove-Item -Recurse -Force "UVVM/bitvis_uart/sim" -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path "UVVM/bitvis_uart/sim" | Out-Null
Copy-Item "C:/intelFPGA_pro/21.1/modelsim_ase/modelsim.ini" "UVVM/bitvis_uart/sim/modelsim.ini"
Push-Location "UVVM/bitvis_uart/sim"
$env:MODELSIM = (Resolve-Path "modelsim.ini").Path
vsim -c -do "do ../script/compile_all_and_simulate.do; exit" 2>&1 | Tee-Object -FilePath ../../../tmp/uvvm_uart_run.log
Pop-Location
```

## UVVM script structure (per VIP/demo, e.g. `bitvis_uart/script/`)

- `compile_all_and_simulate.do` = entry point. It runs:
  - `compile_dependencies.do` → compiles `uvvm_util`, `uvvm_vvc_framework`,
    `bitvis_vip_scoreboard`, `bitvis_vip_sbi`, `bitvis_vip_uart`, `bitvis_vip_clock_generator`
  - `compile_src.do` (module src) → `compile_demo_tb.do` → `simulate_demo_tb.do`
- Scripts are meant to run from a `sim/` subdir; they create/compile into it.
- Top-level `UVVM/script/compile_src.do` reads each module's
  `script/compile_order.txt` (lib name is the 3rd token) and compiles with
  `-2008 -suppress 1346,1246,1236` for modelsim.
- `simulate_demo_tb.do` does `vsim bitvis_uart.uart_vvc_demo_tb; do wave.do; run -all`.

## Notes / expected output

- Run with `vsim -c` (console/batch). `onerror {abort all; exit -f -code 1}` in the
  scripts makes batch runs fail on error.
- In batch mode the `wave.do` "add wave" commands emit benign ONERROR warnings
  (no GUI) — **not** test failures. Expect `Errors: 0, Warnings: 2`.
- SUCCESS markers in the log:
  - `>> Simulation SUCCESS: No mismatch between counted and expected serious alerts`
  - `SIMULATION COMPLETED`
- `Tee-Object` writes the log as UTF-16; use PowerShell `Get-Content` (or grep with
  ignored-files enabled) to scan it.

## Log location used

- `tmp/uvvm_uart_run.log`
