# VHDL Test File Specification

## Overview

Every VHDL test file in this project:
- Tests **exactly one** VHDL language feature in isolation
- Is a **self-checking testbench** (simulation mode) or **synthesizable entity** (synthesis mode)
- Contains **embedded metadata** in its comment header
- Is **educational** — a reader should learn the feature from the file

## File Naming

```
{category}_{feature_short}.vhd
```

Examples:
- `generics_generic_types.vhd`
- `processes_process_all.vhd`
- `expressions_condition_operator.vhd`
- `vectors_partially_connected.vhd`

Use lowercase with underscores. Keep names concise but descriptive.

## Metadata Header

Every test file must begin with this structured comment block:

```vhdl
-- STD: VHDL-2008
-- FEATURE: process(all) — automatic sensitivity list
-- CATEGORY: processes
-- TEST_TYPE: sim
-- DESCRIPTION:
--   VHDL-2008 introduced the keyword "all" in process sensitivity lists.
--   When a process uses "process(all)", the simulator automatically infers
--   which signals to include in the sensitivity list by scanning all signals
--   read within the process body.
--
--   Before VHDL-2008, forgetting a signal in the sensitivity list would cause
--   a simulation/synthesis mismatch — the simulator would miss events while
--   the synthesized hardware would behave correctly. process(all) eliminates
--   this entire class of bugs.
--
--   This test verifies that process(all) correctly detects all three input
--   signals (a, b, c) and recomputes y when any of them changes.
```

### Required Fields

| Field | Values | Description |
|---|---|---|
| `STD` | `VHDL-2000`, `VHDL-2002`, `VHDL-2008`, `VHDL-2019` | Which standard introduced this feature |
| `FEATURE` | Free text | Short human-readable name with one-sentence description |
| `CATEGORY` | See category list below | Which subdirectory this file belongs in |
| `XREF` | `LCS2016-XXX` (2019) or `FTXX` (2008) | IEEE working group reference number. Mandatory for VHDL-2019, optional for VHDL-2008 |
| `TEST_TYPE` | `sim`, `synth`, `both`, `backcompat` | Can this feature be tested in simulation, synthesis, both, or is this a backwards-compatibility test? |
| `DESCRIPTION` | Multi-line free text | Educational explanation. What the feature is, why it exists, what problem it solves. The reader should learn something. |

### VHDL-2019 Naming Convention

All VHDL-2019 test files **must** include the LCS number in the filename:

```
{category}_lcs{lcs-number}_{feature-short}.vhd
```

Example: `syntax_lcs071a_optional_trailing_semicolon.vhd`

This enables completeness auditing — `ls tests/vhdl2019/` immediately shows which of the 43 LCS items are covered. LCS numbers are permanent IEEE working group identifiers and are the community-standard way to reference VHDL-2019 features.

### VHDL-2008 Naming Convention

VHDL-2008 features use Fast Track Proposal numbers (e.g., FT19 for `process(all)`). These are less canonical than LCS numbers and are added as the `XREF` metadata field only — they do not appear in filenames.

## Simulation Tests (`TEST_TYPE: sim`)

A simulation test is a self-checking testbench:

- It must **compile** successfully if the tool supports the feature
- It must **run** and produce a **deterministic pass/fail** result
- Use `std.env.stop(0)` for success, `std.env.stop(1)` for failure
- Use `report` statements generously with descriptive messages
- Keep the test **minimal** — remove everything not needed to demonstrate the feature

**Recommended structure:**

```vhdl
-- STD: ... (metadata header)
library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_feature_name is
end entity;

architecture test of tb_feature_name is
  -- Signal declarations
begin
  -- Feature demonstration
  process
  begin
    -- Assert correct behavior
    assert expected = actual
      report "FAIL: feature_name — expected X but got Y"
      severity error;

    report "PASS: feature_name works correctly";
    stop(0);
    wait;
  end process;
end architecture;
```

## Synthesis Tests (`TEST_TYPE: synth`)

A synthesis test is a synthesizable design entity:

- It must have **entity ports** (not be a testbench)
- It must represent **real hardware** — flip-flops, combinational logic, etc.
- It must use the feature in a **synthesizable way**
- Success = `synth_design` completes without errors in Vivado

**Recommended structure:**

```vhdl
-- STD: ... (metadata header)
-- Note: This is a SYNTHESIS test. The entity should synthesize cleanly.
library ieee;
use ieee.std_logic_1164.all;

entity feature_name is
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    d     : in  std_logic;
    q     : out std_logic
  );
end entity;

architecture rtl of feature_name is
  -- Feature used in synthesizable RTL
begin
  process(all)  -- Example: process(all) in synthesizable code
  begin
    if rst then
      q <= '0';
    elsif rising_edge(clk) then
      q <= d;
    end if;
  end process;
end architecture;
```

## Both Tests (`TEST_TYPE: both`)

For features that are both synthesizable and behaviorally interesting:
Create the simulation variant. The synthesis adapter will auto-extract the entity for synthesis checking, or you can provide a separate `_synth` file.

## Backwards-Compatibility Tests (`TEST_TYPE: backcompat`)

Backwards-compatibility tests verify that a tool correctly rejects legacy code that was valid in an older standard but is illegal in a newer standard (e.g., VHDL-93 identifiers that became VHDL-2008 reserved keywords).

### Concept

Each backcompat test is a VHDL file that was perfectly legal in **Standard X** but became illegal in **Standard Y** due to a breaking change (new keyword, type redefinition, syntax change, etc.). The test verifies that:

1. **In the OLDER standard mode**, the tool accepts the code (it was legal then)
2. **In the NEWER standard mode**, the tool rejects the code (it's illegal now)

### Additional Metadata Fields

| Field | Values | Description |
|---|---|---|
| `VALID_IN` | Comma-separated standards | Standards where this code SHOULD compile |
| `INVALID_IN` | Comma-separated standards | Standards where this code SHOULD be rejected |
| `BREAK_REASON` | Short text | What changed: "New reserved keyword", "Type redefinition", etc. |

### Example

```vhdl
-- STD: VHDL-2008
-- FEATURE: Reserved keyword "context" — breaks VHDL-93 identifiers named "context"
-- CATEGORY: keywords
-- TEST_TYPE: backcompat
-- VALID_IN: VHDL-93, VHDL-2000, VHDL-2002
-- INVALID_IN: VHDL-2008, VHDL-2019
-- BREAK_REASON: New reserved keyword
-- DESCRIPTION:
--   VHDL-2008 added "context" as a reserved word for context declarations.
--   Legacy code using "context" as an identifier breaks under VHDL-2008.
--   EXPECTED RESULT:
--     VHDL-93 mode:  PASS (compiles)
--     VHDL-2008 mode: FAIL (correctly rejected)
```

### Directory Structure

```
tests/backcompat/
├── keywords/       # New reserved keywords
├── types/          # Type system redefinitions
├── functions/      # Predefined name collisions
├── syntax/         # Syntax changes
└── semantic/       # Semantic rule changes
```

### Runner Behavior

The runner detects `TEST_TYPE: backcompat` and automatically runs the test against each standard listed in `VALID_IN` (expecting PASS) and `INVALID_IN` (expecting FAIL). The combined matrix has separate columns for each standard mode.

## Category List

See [`contributing.md`](contributing.md) for the full project structure. Categories per standard:

**VHDL-2000:** `protected_types`
**VHDL-2002:** `buffer_ports`
**VHDL-2008:** `generics`, `processes`, `expressions`, `aggregates`, `generate`, `types`, `packages`, `verification`, `ports`, `misc`
**VHDL-2019:** `vectors`, `protected_types`, `file_io`, `env`, `conditional_analysis`, `sequential`, `attributes`, `types_2019`, `interfaces`, `generics_2019`, `assert_api`, `psl`, `syntax`
