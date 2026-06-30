# Contributing

## Ways to Contribute

- **Add a test file.** The project needs ~100 VHDL test files covering every feature. See [`test-format.md`](test-format.md).
- **Add a tool adapter.** Support a new EDA tool or version. See [`tool-config.md`](tool-config.md).
- **Fix a test.** If a test incorrectly flags a feature, fix it.
- **Improve the runner.** Better error parsing, faster execution, richer reports.

## Development Setup

```bash
# Clone the repo
git clone <repo-url>
cd vhdl-compatibility

# Create virtual environment
python -m venv .venv
.venv\Scripts\activate  # Windows
# source .venv/bin/activate  # Linux/macOS

# Install dev dependencies
pip install -e ".[dev]"
```

## Project Structure

```
vhdl-compatibility/
├── tests/                  # VHDL test files, organized by standard/category
│   ├── _TEMPLATE.vhd       # Copy this to start a new test
│   ├── vhdl2000/           # VHDL-2000 feature tests
│   ├── vhdl2002/           # VHDL-2002 feature tests
│   ├── vhdl2008/           # VHDL-2008 feature tests (10 categories)
│   └── vhdl2019/           # VHDL-2019 feature tests (13 categories)
├── tools/                  # Per-tool TOML configuration files
├── scripts/                # Python test runner and adapters
├── docs/                   # Documentation
├── results/                # Generated JSON reports (tracked) + MATRIX.md
└── README.md
```

## Design Decisions

Every design decision is documented inline or in the plan. Key principles:

1. **No external manifest.** Test metadata lives in VHDL comment headers. The filesystem is the index.
2. **Three-state results.** PASS / PARTIAL / FAIL — never binary. PARTIAL means a feature compiles but behaves incorrectly in simulation.
3. **Educational test files.** Each `.vhd` teaches the feature it tests. Header comments explain the "why", not just the "what". Ends with a TAKEAWAY.
4. **Synthesis + simulation.** Some features are simulation-only (e.g., `std.env.stop`), some are synthesizable. The runner handles both.
5. **VUnit for simulation orchestration.** We leverage VUnit's proven runner patterns rather than reinventing subprocess management.

## Running Tests

```bash
# Discover tests
python scripts/run_tests.py --list

# Run a specific tool/standard/mode (use version number or alias)
python scripts/run_tests.py --tool vivado --version 2024.1 --std 2008 --mode sim
python scripts/run_tests.py --tool vivado --version v26 --std 2008 --mode sim  # alias form

# Run a single test file
python scripts/run_tests.py --tool vivado --version v26 --file vhdl2008/aggregates/aggregates_open.vhd

# Run Python unit tests
python -m pytest scripts/tests/ -v
```

## Code Style

- **Python:** Follow [PEP 8](https://peps.python.org/pep-0008/). Format with `ruff format`. Line length 100.
- **VHDL:** Follow the [`_TEMPLATE.vhd`](../tests/_TEMPLATE.vhd) pattern. Use 2-space indentation. Lowercase keywords preferred but not enforced.
- **TOML:** Follow standard TOML conventions. One tool per file.

## License

All contributions are licensed under Apache 2.0.
