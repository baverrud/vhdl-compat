# Running UVVM with Vivado xsim

Attempt logged 2026-07-01 with the `bitvis_uart` UART VVC demo TB, Vivado **2026.1** xsim.

> **Status: FAILS at runtime.** UVVM is known not to work with xsim yet. This file
> documents *how* the run is driven and *where* it currently breaks. Do **not** treat
> the failure as a regression — fixing it is a separate, upcoming task.

## Vivado / xsim install (from `tools/installed.toml`)

- Vivado 2026.1, alias `v26`
- Bin: `C:/Xilinx/2026.1/Vivado/bin` (`xvhdl.bat`, `xelab.bat`, `xsim.bat`)

## Why a custom script is needed

UVVM ships ModelSim/Riviera `.do` scripts only — there are **no xsim scripts**. So we
replicate the compile order manually. The compile order per library comes from each
module's `script/compile_order.txt` (first line = `# library <name>`, remaining lines =
source files relative to `<module>/script/`).

Library compile order for the UART demo (same as ModelSim `compile_dependencies.do`):

1. `uvvm_util`               (20 files)
2. `uvvm_vvc_framework`      (8 files)
3. `bitvis_vip_scoreboard`   (3 files)
4. `bitvis_vip_sbi`          (11 files)
5. `bitvis_vip_uart`         (15 files)
6. `bitvis_vip_clock_generator` (8 files)
7. `bitvis_uart` src + demo TB (7 files: 5 src + `uart_vvc_demo_th.vhd` + `uart_vvc_demo_tb.vhd`)

Note: the `uvvm_vvc_framework/src_target_dependent/td_*.vhd` files are **recompiled into
each VIP library** (sbi, uart, clock_generator) — they are generic target-dependent
templates, not a shared library.

## How to run

A reusable script is checked in at `tmp/xsim_uvvm_uart.ps1`. From the repo root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tmp/xsim_uvvm_uart.ps1
```

It:
1. Prepends the Vivado bin to `PATH`.
2. Creates a clean work dir `tmp/xsim-uvvm/` (xsim writes `xsim.dir/` there).
3. Compiles each library in order: `xvhdl.bat -2008 -relax -work <lib> <files...>`.
4. Elaborates: `xelab.bat bitvis_uart.uart_vvc_demo_tb -relax -debug typical -s uart_demo_sim`.
5. Runs: `xsim.bat uart_demo_sim -R`.

Full log: `tmp/xsim_uvvm_uart.log`.

## Result — where it breaks

| Stage        | Outcome |
|--------------|---------|
| Compile (`xvhdl`, all 7 libs) | **OK** — 0 errors (many benign warnings, see below) |
| Elaboration (`xelab`)         | **OK** — static elaboration completes |
| Simulation (`xsim`)           | **FAILS** — UVVM `TB_ERROR` at time 0 |

Runtime failure:

```
UVVM: ***  TB_ERROR #1  ***
UVVM:   check_value_in_range(int, 0, 1) => Failed. Value was -2147483648.
        Expected between 0 and 1.
        'priv_get_vvc_activity() => vvc_idx invalid range:'
UVVM: Simulator has been paused as requested after 1 TB_ERROR
```

- `-2147483648` is `integer'left` — the default value of an **uninitialised integer
  signal**. UVVM passes this stale value as a VVC index into
  `priv_get_vvc_activity(natural)`, whose internal `check_value_in_range(vvc_idx, 0,
  priv_last_registered_vvc_idx)` then aborts. See the full analysis below.
- UVVM then pauses the sim (default behaviour after a serious alert), so no test runs.

## Root-cause analysis (confirmed)

### The signal that is read stale

Every VVC declares, with **no initialiser**:

```vhdl
signal entry_num_in_vvc_activity_register : integer;   -- defaults to integer'left
```

It is assigned once, in the VVC's `p_cmd_interpreter` process init, from a function
with a side effect that also registers the VVC in the shared activity register:

```vhdl
entry_num_in_vvc_activity_register <= shared_vvc_activity_register.priv_register_vvc(...);
```
(e.g. [UVVM/bitvis_vip_sbi/src/sbi_vvc.vhd](../UVVM/bitvis_vip_sbi/src/sbi_vvc.vhd#L138))

Because `<=` is a signal assignment, the signal only holds its real index after the
time-0 delta cycles settle.

### The process that reads it too early

Each VVC also has a `p_unwanted_activity` process that reads that signal and feeds it to
`priv_get_vvc_activity`:

```vhdl
p_unwanted_activity : process is
begin
  -- Add a delay to allow the VVC to be registered in the activity register
  wait for std.env.resolution_limit;              -- <-- the load-bearing line
  loop
    if shared_vvc_activity_register.priv_get_vvc_activity(entry_num_in_vvc_activity_register) = ACTIVE then
    ...
```
(SBI [sbi_vvc.vhd:475](../UVVM/bitvis_vip_sbi/src/sbi_vvc.vhd#L475), UART-RX
[uart_rx_vvc.vhd:399](../UVVM/bitvis_vip_uart/src/uart_rx_vvc.vhd#L399); both VVCs are
in the demo.)

The single `wait for std.env.resolution_limit` is UVVM's mechanism to advance simulation
time by exactly one resolution step, flushing **all** time-0 delta cycles so that the
`entry_num_in_vvc_activity_register <= ...` assignment (which happens some deltas into
time 0, after `initialize_interpreter`) has propagated before it is read.

### Why it breaks on xsim: `std.env.resolution_limit` is broken

Under xsim 2026.1, `std.env.resolution_limit` does **not** return the true resolution.
A minimal standalone probe ([tmp/res_limit_probe.vhd](../tmp/res_limit_probe.vhd))
reports:

```
Time resolution is 1 ps
resolution_limit = -12 ps                       <-- wrong; should be +1 ps
ERROR: Negative time value -12 in wait statement
```

So `wait for std.env.resolution_limit` does not perform the intended one-step time
advance. `p_unwanted_activity` therefore resumes while still inside the time-0 delta
soup, **before** the VVC's registration signal assignment has propagated, and reads
`entry_num_in_vvc_activity_register` at its default `integer'left`. That stale value is
passed to `priv_get_vvc_activity`, tripping the range check → `TB_ERROR` at 0 ps.
(The range `0..1` in the message just reflects that only 2 VVCs had finished registering
at that instant; the `TB seq.` scope is hard-coded inside the check and does **not**
identify the real caller.)

The same construct works on ModelSim because there `std.env.resolution_limit` correctly
returns `1 ps`, so the wait advances real time and all time-0 deltas settle first.

### Summary

| Layer | ModelSim | xsim 2026.1 |
|-------|----------|-------------|
| `std.env.resolution_limit` | `1 ps` (correct) | garbage / non-positive (probe: `-12 ps`) |
| `wait for std.env.resolution_limit` | advances 1 time step, flushes time-0 deltas | fails to defer the read |
| `entry_num_in_vvc_activity_register` when read | registered index | still `integer'left` |
| Result | passes | `TB_ERROR`, sim paused |

## Benign compile warnings (expected, not the problem)

xvhdl emits large numbers of these on UVVM sources — they do **not** stop compilation:

- `[VRFC 10-2115] shared variables must be of a protected type` (UVVM uses non-protected
  shared vars in some -2008 packages)
- `[VRFC 10-1749] default expression of interface object is not globally static`

## Log encoding gotcha

The script pipes through `Tee-Object`, which on Windows PowerShell 5.1 writes the log as
**UTF-16**. To read it back reliably:

```powershell
Get-Content tmp/xsim_uvvm_uart.log -Encoding Unicode | Select-String 'ERROR|TB_ERROR|=== '
```

(Plain `Get-Content` / grep tools misread it as bytes with embedded nulls.)

## Next steps (future task — not done here)

The fix must address xsim's broken `std.env.resolution_limit`. Options to evaluate:

- Confirm whether a specific `xelab`/`xsim` time-resolution flag (e.g. `-timescale` /
  `--sv_root`, or `xsim` resolution options) makes `std.env.resolution_limit` return a
  sane positive value.
- If xsim cannot be coerced, patch/shim the VVC pattern for xsim so the deferral uses a
  concrete positive delay (e.g. `wait for 1 ps` or a delta-robust wait) instead of
  `std.env.resolution_limit`. This is a UVVM-source change and should be isolated to an
  xsim-specific build.
- Also initialise `entry_num_in_vvc_activity_register` defensively is **not** enough on
  its own (the real index still arrives late); the timing/deferral is the core issue.

Reproduction probes are checked in: [tmp/res_limit_probe.vhd](../tmp/res_limit_probe.vhd)
and [tmp/res_limit_probe2.vhd](../tmp/res_limit_probe2.vhd).
