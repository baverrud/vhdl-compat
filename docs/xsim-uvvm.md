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

## Root cause: two layered VHDL-2008 gaps in xsim

Fixing the first failure only exposes the second — UVVM + xsim is a multi-issue campaign,
not a one-line fix. Both failures are the same class of problem, **xsim's incomplete
VHDL-2008 semantics**, and neither involves UVVM's global shared variables (ruled out
below).

| Layer | Symptom on xsim 2026.1 | VHDL-2008 feature xsim gets wrong |
|-------|------------------------|-----------------------------------|
| 1 | `TB_ERROR` at 0 ps (TB never starts) | `std.env.resolution_limit` returns a non-positive value |
| 2 | `FAILURE` at 105 ns (`ready = 'X'`) | default value of the driver for an unassigned element of a composite `inout` port |

### Layer 1 — `std.env.resolution_limit` is non-positive

Every VVC has a `p_unwanted_activity` process that must wait for the VVC to finish
registering before it reads the registration index:

```vhdl
signal entry_num_in_vvc_activity_register : integer;   -- no initialiser → integer'left

p_unwanted_activity : process is
begin
  wait for std.env.resolution_limit;   -- defer one resolution step, past all time-0 deltas
  loop
    if shared_vvc_activity_register.priv_get_vvc_activity(entry_num_in_vvc_activity_register) = ACTIVE then
    ...
```
(SBI [sbi_vvc.vhd:475](../UVVM/bitvis_vip_sbi/src/sbi_vvc.vhd#L475), UART-RX
[uart_rx_vvc.vhd:399](../UVVM/bitvis_vip_uart/src/uart_rx_vvc.vhd#L399))

`entry_num_in_vvc_activity_register` is set by a **signal** assignment during interpreter
init ([sbi_vvc.vhd:138](../UVVM/bitvis_vip_sbi/src/sbi_vvc.vhd#L138)), so it only holds
the real index after the time-0 delta cycles settle. The single
`wait for std.env.resolution_limit` is UVVM's mechanism to advance one resolution step
and flush those deltas.

On xsim `std.env.resolution_limit` returns a **non-positive** value (the regression test
below measures `0 ps`; an earlier in-context probe saw `-12 ps`), so the wait does not
defer the read. `p_unwanted_activity` resumes inside the time-0 delta soup and reads
`entry_num_in_vvc_activity_register` at its default `integer'left`, which is passed to
`priv_get_vvc_activity` and trips its range check:

```
UVVM: ***  TB_ERROR #1  ***
  check_value_in_range(int, 0, 1) => Failed. Value was -2147483648.
UVVM: Simulator has been paused as requested after 1 TB_ERROR
```

ModelSim passes because there `std.env.resolution_limit` correctly returns `1 ps`, so the
wait advances real time and all time-0 deltas settle first.

### Layer 2 — composite `inout` port default not applied to the driver

Patching every `std.env.resolution_limit` → `(1 ps)` in the compiled UVVM sources
(throwaway experiment; all edits reverted with `git -C UVVM checkout -- .`) clears
layer 1 and lets real SBI transactions run — until a different failure at 105 ns from the
SBI BFM ([sbi_bfm_pkg.vhd:363](../UVVM/bitvis_vip_sbi/src/sbi_bfm_pkg.vhd#L363)):

```
FAILURE #1  @ 105000 ps  SBI_VVC,1
check_value(bool, true) => Failed.
'Verifying that ready signal is set to either '1' or '0' when in use'
```

An in-situ monitor (added to the harness, reverted afterwards) captured `ready = 'X'`,
not `'U'` — the std_logic resolution of **two conflicting strong drivers**.

The mechanism: the SBI VVC passes its **whole** interface record to the BFM as an
`inout` subprogram parameter ([sbi_vvc.vhd:319](../UVVM/bitvis_vip_sbi/src/sbi_vvc.vhd#L319),
[:350](../UVVM/bitvis_vip_sbi/src/sbi_vvc.vhd#L350)):

```vhdl
sbi_write(addr_value => ..., sbi_if => sbi_vvc_master_if, ...);
sbi_read (addr_value => ..., sbi_if => sbi_vvc_master_if, ...);
```

Per the LRM this gives the VVC process a driver for **every** element of the record —
including `ready` — even though the BFM only ever **reads** `ready`. That never-assigned
driver must keep the port's declared default, `init_sbi_if_signals(...)`, which sets
`ready := 'Z'` ([sbi_bfm_pkg.vhd:313](../UVVM/bitvis_vip_sbi/src/sbi_bfm_pkg.vhd#L313)).
On a compliant simulator that element sits at `'Z'` and is dominated by the harness
`ready <= '1'` (`Z + 1 = '1'`) — which is why ModelSim passes. xsim instead gives the
unassigned composite-port driver element a **forcing** value, so it collides with the
harness `'1'` and `ready` resolves to `'X'`, failing UVVM's `ready = '1' or '0'` sanity
check.

The trigger requires the *combination* of a composite `inout` port with a non-`'U'`
default **and** that port being passed whole to an `inout` subprogram parameter (creating
a driver for elements that are never assigned). Isolated probes with a plain scalar port
default, or a record port defaulted via a function call, both worked on xsim
(`Z + 1 = 1`); only the full pattern reproduces the bug.

### Ruled out — global shared variables

UVVM routes commands, config and VVC activity through package-level protected-type
`shared variable`s. A known historical xsim limitation gives each process its **own copy**
of such a variable instead of one global object, which would break UVVM everywhere.
Tested directly: a global protected counter incremented by three separate entity
instances and read by a fourth process returned `3` — **xsim 2026.1 keeps a single global
instance**. The per-context-copy bug is absent, so shared variables are not the cause of
either failure.

### Regression tests

Both failures are covered by self-checking tests in the `uvvm` category. Each **passes on
ModelSim** (compliant) and **fails on xsim 2026.1**, isolating one layer with no UVVM
dependency:

| Test | Property checked | ModelSim | xsim 2026.1 |
|------|------------------|----------|-------------|
| [tests/vhdl2008/uvvm/uvvm_resolution_limit.vhd](../tests/vhdl2008/uvvm/uvvm_resolution_limit.vhd) | `std.env.resolution_limit > 0 fs` | `1 ps` → PASS | `0 ps` → FAIL |
| [tests/vhdl2008/uvvm/uvvm_inout_default_driver.vhd](../tests/vhdl2008/uvvm/uvvm_inout_default_driver.vhd) | composite `inout` port default `'Z'` reaches the driver (`Z + 1 = '1'`) | `ready = '1'` → PASS | `ready = 'X'` → FAIL |

`uvvm_inout_default_driver.vhd` reproduces the SBI pattern minimally: a record with an
unconstrained element, an `inout` port defaulted via an init function, a BFM passed the
whole record as `inout` that only reads `ready`, and a harness driving `ready <= '1'`.

### Confirmed by the UVVM maintainers

The UVVM team states that xsim is **not** a supported simulator because it "is still
missing some important VHDL-2008 features"
([forum.uvvm.org/t/uvvm-in-vivado-xsim/365](https://forum.uvvm.org/t/uvvm-in-vivado-xsim/365),
EspenTa, Apr 2023). Officially supported / known-working simulators are ModelSim, Questa,
Active-HDL, Riviera-PRO and GHDL. The two failures above are concrete instances of that
gap.

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

## Next steps (future task)

- **Layer 1:** check whether any `xelab`/`xsim` time-resolution option makes
  `std.env.resolution_limit` return a positive value; otherwise shim the VVC deferral
  (e.g. `wait for 1 ps`) in an xsim-specific UVVM build. Defensively initialising
  `entry_num_in_vvc_activity_register` alone is **not** enough — the real index still
  arrives late, so the deferral is the core issue.
- **Layer 2:** no clean workaround from outside UVVM; needs xsim to apply composite
  `inout` port defaults to unassigned driver elements.
- Use the two regression tests above to detect whether a future xsim release closes
  either gap.
