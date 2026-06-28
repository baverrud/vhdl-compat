# VHDL Compatibility Test Suite

A comprehensive test suite for evaluating EDA tool support of VHDL standards: **VHDL-2000**, **VHDL-2002**, **VHDL-2008**, and **VHDL-2019** — everything after VHDL-1993.

Tests cover **simulation** (compile + run), **synthesis** (compile to netlist), and **backwards-compatibility** (standards enforcement across versions), with per-tool reports and a combined comparison matrix.

## Quick Start

```bash
# Install (development mode)
pip install -e .

# List all available tests
vhdl-compat --list

# List configured tools
vhdl-compat --list-tools

# Run all VHDL-2008 simulation tests with Vivado 2024.1
vhdl-compat --tool vivado --version 2024.1 --std 2008 --mode sim

# Run VHDL-2019 synthesis tests
vhdl-compat --tool vivado --version 2024.1 --std 2019 --mode synth

# Quick analysis-only check (compile only)
vhdl-compat --tool questa --version 2024.1 --std 2008 --mode analyze

# Generate the combined comparison matrix from all results
vhdl-compat-matrix --results-dir results/

# Or run directly without installing:
python scripts/run_tests.py --list
python -m scripts.run_tests --list
```

## Project Philosophy

- **One feature, one file.** Each `.vhd` file tests exactly one VHDL language feature in isolation.
- **Educational by design.** Every test file includes a plain-language explanation of the feature. Ends with a **TAKEAWAY** one-liner. A junior engineer should learn VHDL by browsing `tests/`.
- **Three-state results.** PASS (works correctly), PARTIAL (compiles but behaves incorrectly), FAIL (rejected by tool). Never a simple pass/fail.
- **Backwards-compatibility testing.** Verify that a tool's `-93` mode rejects VHDL-2008 keywords, and its `-2008` mode accepts VHDL-93 identifiers.
- **Tool-agnostic runner.** Add a new tool with a single TOML config file + a lightweight Python adapter.

## Standards Covered

| Standard | IEEE | Features | Test Types |
|---|---|---|---|
| VHDL-2000 | 1076-2000 | ~8 | Forward |
| VHDL-2002 | 1076-2002 | ~3 | Forward |
| VHDL-2008 | 1076-2008 | ~40 | Forward |
| VHDL-2019 | 1076-2019 | ~43 | Forward |
| Backwards-compat | Cross-standard | Breaking changes across versions | Backcompat |

### Forward-Compatibility Categories

**VHDL-2000:** `protected_types`  
**VHDL-2002:** `buffer_ports`  
**VHDL-2008:** `generics`, `processes`, `expressions`, `aggregates`, `generate`, `types`, `packages`, `verification`, `ports`, `misc`  
**VHDL-2019:** `vectors`, `protected_types`, `file_io`, `env`, `conditional_analysis`, `sequential`, `attributes`, `types_2019`, `interfaces`, `generics_2019`, `assert_api`, `psl`, `syntax`

### Backwards-Compatibility Categories

`backcompat/keywords/` — new reserved keywords | `backcompat/types/` — type system changes | `backcompat/functions/` — predefined name collisions | `backcompat/syntax/` — syntax changes | `backcompat/semantic/` — semantic rule changes

### Complete VHDL-2019 Feature Catalog

All 43 features identified by LCS number. See [`docs/plan.md`](docs/plan.md) for the full catalog.

## Results

```
results/
├── vivado-2024.1/
│   ├── vhdl2008-sim/
│   │   ├── report.json    # Machine-readable per-feature results
│   │   └── report.md      # Human-readable summary with details
│   └── vhdl2008-synth/
│       ├── report.json
│       └── report.md
├── questa-2024.1/
│   └── ...
└── matrix.md               # Combined comparison: all tools × all features × all standards
```

## Adding a New Tool

1. Create `tools/{tool_name}.toml` — specify compile/simulate/synthesize commands
2. Create `scripts/{tool_name}_adapter.py` — subclass `ToolRunner`, implement `analyze()`, `simulate()`, `synthesize()`
3. Run the tests

See [`docs/tool-config.md`](docs/tool-config.md) for the full guide.

## Adding a New Test

1. Copy `tests/_TEMPLATE.vhd`
2. Fill in the metadata header
3. Write a minimal, self-checking testbench
4. Place in the appropriate `tests/{standard}/{category}/` directory

See [`docs/test-format.md`](docs/test-format.md) for the specification.

## License

Apache 2.0 — see [LICENSE](LICENSE).

## References

- [IEEE 1076-2019 Standard](https://standards.ieee.org/standard/1076-2019.html)
- [VHDL Analysis and Standardization Group (VASG)](http://www.eda-twiki.org/cgi-bin/view.cgi/P1076/WebHome)
- [VHDL/Compliance-Tests](https://github.com/VHDL/Compliance-Tests) — related open-source compliance suite
- [SynthWorks VHDL_2019 Examples](https://gitlab.com/synthworks/VHDL_2019) — authoritative examples by IEEE VASG chair Jim Lewis
- [NVC VHDL Simulator](https://github.com/nickg/nvc) — open-source VHDL simulator with feature tracking
