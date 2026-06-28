# Project Plan — VHDL Compatibility Test Suite

> **Status:** In progress | **Last updated:** 2026-06-28
>
> This document records every architectural decision, design principle, and feature catalog.
> It is the single source of truth for project scope and direction.

---

## TL;DR

Build a structured VHDL compatibility test suite covering **all standards after VHDL-1993**: VHDL-2000, VHDL-2002, VHDL-2008, and VHDL-2019. Tests both simulation and synthesis, plus backwards-compatibility verification. Uses categorized VHDL test files (one feature per file) with embedded metadata, a Python test runner with pluggable tool adapters, and automated Markdown+JSON report generation with a combined comparison matrix. Targets Vivado and ModelSim/Questa initially, architected for easy addition of GHDL, NVC, Riviera-PRO, VCS, etc.

---

## Phase 1: Project Scaffolding & Test File Design ✅

### 1.1 Create project structure ✅
- Git repo initialized at project root
- Full directory tree created
- `.gitignore`, `pyproject.toml`, `README.md`, `LICENSE` created
- `scripts/` Python package created

### 1.2 Define test file metadata format ✅
Each VHDL test file embeds metadata in structured comment headers:
```vhdl
-- STD: VHDL-2008
-- FEATURE: process(all) sensitivity list
-- CATEGORY: processes
-- TEST_TYPE: sim
-- DESCRIPTION: ...
```
No external manifest — the filesystem and metadata comments are the source of truth.

**Extended fields for backcompat tests:**
```vhdl
-- TEST_TYPE: backcompat
-- VALID_IN: VHDL-93, VHDL-2000, VHDL-2002
-- INVALID_IN: VHDL-2008, VHDL-2019
-- BREAK_REASON: New reserved keyword
```

### 1.3 Feature categories and test file inventory ✅

Sources: Doulos, NVC, VHDLwhiz, nselvara/VHDL-20xx-New-Features, SynthWorks/VHDL_2019 (Jim Lewis/IEEE VASG chair), VHDL/Compliance-Tests.

**VHDL-2000 (~6-8 features):**
- `protected_types/` — protected type declarations, methods, shared variables of protected type, file I/O extensions

**VHDL-2002 (~2-3 features):**
- `buffer_ports/` — relaxed buffer port connection rules

**VHDL-2008 — complete catalog (~40 features across 10 categories):**
- `generics/` — generic types, generic packages, generic subprograms, package generics
- `processes/` — process(all) sensitivity, conditional/selected sequential assignments in processes
- `expressions/` — condition operator `??`, enhanced bit string literals, matching operators, unary reduction operators, shift/rotate operators
- `aggregates/` — array slices in aggregates, aggregates as assignment targets
- `generate/` — if-elsif-else generate, case generate
- `types/` — unconstrained array/record elements, boolean_vector, integer_vector, real_vector, time_vector
- `packages/` — context declarations, fixed/floating point packages, numeric_std_unsigned/signed
- `verification/` — external/hierarchical names, force/release, std.env.stop/finish, PSL
- `ports/` — reading output ports, expressions in port maps, enhanced port association
- `misc/` — block comments, minimum/maximum, to_string, IP encryption, rising_edge for boolean

**VHDL-2019 — complete catalog (43 features across 13 categories):**

| # | LCS | Feature | Category |
|---|---|---|---|
| 1 | LCS2016-001 | Partially connected vectors on port map | `vectors/` |
| 2 | LCS2016-002/004 | Access, file, PT as subprogram parameters in PT | `protected_types/` |
| 3 | LCS2016-006a | File I/O / TextIO updates | `file_io/` |
| 4 | LCS2016-006c | Directory API | `file_io/` |
| 5 | LCS2016-006e | Environment variable access (GETENV) | `env/` |
| 6 | LCS2016-006f | Standard conditional analysis identifiers | `conditional_analysis/` |
| 7 | LCS2016-007 | Sequential declaration regions | `sequential/` |
| 8 | LCS2016-011 | Date/time functions | `env/` |
| 9 | LCS2016-012 | 'IMAGE and TO_STRING for composite types | `attributes/` |
| 10 | LCS2016-014 | Composites of protected types | `protected_types/` |
| 11 | LCS2016-014a | Pointers to composites of PT | `protected_types/` |
| 12 | LCS2016-015 | GET_CALL_PATH | `env/` |
| 13 | LCS2016-015a | FILE_NAME, FILE_PATH, FILE_LINE | `env/` |
| 14 | LCS2016-016 | Anonymous types in interface lists | `types_2019/` |
| 15 | LCS2016-018/018a/018d | Attributes for enumerated types | `attributes/` |
| 16 | LCS2016-019 | Inferring constraints from initial values | `types_2019/` |
| 17 | LCS2016-023 | Relax library requirement on configurations | `syntax/` |
| 18 | LCS2016-026c | Long integers (64-bit) | `types_2019/` |
| 19 | LCS2016-028 | Access external types through library path | `types_2019/` |
| 20 | LCS2016-030 | Garbage collection | `protected_types/` |
| 21 | LCS2016-032 | PATH_NAME/INSTANCE_NAME for PT | `protected_types/` |
| 22 | LCS2016-033 | Public variable + PRIVATE keyword in PT | `protected_types/` |
| 23 | LCS2016-034 | Protected types with generic clause | `protected_types/` |
| 24 | LCS2016-036a | Conditional expressions in declarations | `sequential/` |
| 25 | LCS2016-041 | Record introspection / 'reflect | `attributes/` |
| 26 | LCS2016-043 | PSL attributes and functions | `psl/` |
| 27 | LCS2016-045a/c | Interface mode view + 'CONVERSE | `interfaces/` |
| 28 | LCS2016-047 | Shared variables on entity interface | `protected_types/` |
| 29 | LCS2016-049 | Map generics on subprogram call | `generics_2019/` |
| 30 | LCS2016-050 | API for assert | `assert_api/` |
| 31 | LCS2016-055a | Syntax regularization — components | `syntax/` |
| 32 | LCS2016-059 | Array type generics | `generics_2019/` |
| 33 | LCS2016-059a | Ordering on any scalar array | `types_2019/` |
| 34 | LCS2016-061 | Conditional compilation (`if/`else/`end if) | `conditional_analysis/` |
| 35 | LCS2016-071a | Optional trailing semicolon | `syntax/` |
| 36 | LCS2016-072b | Function knows vector size | `vectors/` |
| 37 | LCS2016-075 | Closely related record types | `types_2019/` |
| 38 | LCS2016-082 | Empty records | `types_2019/` |
| 39 | LCS2016-086 | All interface lists can be ordered | `syntax/` |
| 40 | LCS2016-094a | Conditional return statement | `sequential/` |
| 41 | LCS2016-099 | Extended ranges / range expressions | `syntax/` |
| 42 | LCS2016-I03 | Signatures in association lists | `syntax/` |
| 43 | LCS2016-I13 | Precedence of unary operators | `syntax/` |

**Backwards-compatibility categories:**
- `backcompat/keywords/` — New reserved keywords breaking legacy identifiers
- `backcompat/types/` — Type system redefinitions (e.g., std_logic_vector subtype change)
- `backcompat/functions/` — Predefined function name collisions
- `backcompat/syntax/` — Syntax changes (e.g., VHDL-87 file declaration)
- `backcompat/semantic/` — Semantic rule changes (e.g., shared variables must be protected)

### 1.4 Test files created ✅

**16 tests total:** 9 forward-compatibility + 7 backwards-compatibility

**Key design rule:** Every VHDL test file must be self-explanatory. Educational header comments, minimal complete examples, comments explaining the "why", self-checking assertions, and a TAKEAWAY one-liner.

---

## Phase 2: Tool Configuration System ✅

- `tools/vivado.toml` — xvhdl/xelab/xsim + Vivado batch Tcl for synthesis
- `tools/questa.toml` — vcom/vsim (simulation only)
- `tools/modelsim.toml` — vcom/vsim (simulation only)

Schema documented in `docs/tool-config.md`.

---

## Phase 3: Python Test Runner ✅ (skeleton)

### Core modules implemented
- `test_discovery.py` — Walk `tests/`, parse metadata, build in-memory index ✅ verified (16 tests)
- `tool_discovery.py` — Load TOML configs ✅
- `tool_runner.py` — Abstract ToolRunner + GenericRunner placeholder + adapter registry ✅
- `result_store.py` — Three-state results (PASS/PARTIAL/FAIL) ✅
- `run_tests.py` — CLI entry point (`--list`, `--tool`, `--std`, `--mode`) ✅
- `report_generator.py` — JSON + Markdown report writer ✅
- `generate_matrix.py` — Cross-tool comparison matrix ✅

### Tool-specific adapters (TO DO)
- `vivado_adapter.py`
- `questa_adapter.py`
- `modelsim_adapter.py`
- `ghdl_adapter.py`
- `nvc_adapter.py`

### CLI design
```
vhdl-compat --list
vhdl-compat --tool vivado --version 2024.1 --std 2008 --mode sim
vhdl-compat --tool questa --version 2024.1 --std 2019 --mode sim
vhdl-compat --tool vivado --version 2024.1 --std 2008 --mode synth
vhdl-compat-matrix --results-dir results/
```

---

## Phase 4: Report Generation ✅ (skeleton)

### Per-tool/version report
- JSON: machine-readable canonical format
- Markdown: human-readable with category summaries and detail sections

### Combined comparison matrix
- Reads all `report.json` files, generates `MATRIX.md` + `matrix.json`
- Rows = features, columns = tools/versions/modes

---

## Phase 5: Documentation & GitHub Setup ✅ (skeleton)

- `README.md` — Project overview, quick start
- `docs/plan.md` — This file. Complete design record.
- `docs/contributing.md` — How to add tests, tools, contribute
- `docs/test-format.md` — VHDL test file specification (forward + backcompat)
- `docs/tool-config.md` — TOML schema reference

### TO DO
- `.github/workflows/` — CI for OSS tools (GHDL, NVC)
- GitHub Pages — Auto-publish matrix report

---

## Design Decisions

| Decision | Rationale |
|---|---|
| **One feature per file** | Simplest attribution; avoids coupling |
| **Embedded metadata in VHDL comments** | No external manifest to maintain; filesystem is the index |
| **Categorized subdirectories** | Enables browsing and selective test runs |
| **Python for runner** | Cross-platform, subprocess-rich, rich output generation |
| **TOML for tool configs** | Human-readable, Python 3.11+ native |
| **Markdown + JSON reports** | JSON = canonical machine-readable; MD = human consumption |
| **Both simulation + synthesis** | Synthesis via Vivado Tcl batch; sim-only tools report N/A |
| **Educational test files** | Header explains "why", not just "what"; TAKEAWAY one-liner |
| **Three-state results** | PASS / PARTIAL / FAIL — never binary |
| **Standard-version verification** | Baseline tests confirm tool is running in correct mode |
| **Consistent file naming** | `{category}_{feature_short}.vhd` — sortable, scannable |
| **Test file template** | `tests/_TEMPLATE.vhd` — canonical starting point |
| **Backwards-compatibility testing** | Separate `backcompat/` tree with VALID_IN/INVALID_IN metadata |
| **Fast analysis-only mode** | `--mode analyze` for compile-check; `--mode sim` for thorough |
| **VUnit for simulation** | Leverage existing runner patterns for vcom/vsim |
| **Standalone + module execution** | Both `python scripts/run_tests.py` and `python -m scripts.run_tests` work |

---

## Further Considerations

1. **Test file count:** ~100+ feature test files total. Start with ~20, expand incrementally. Each file is independent parallel work.
2. **Existing reference:** `github.com/VHDL/Compliance-Tests` (Apache 2.0) — study for patterns. We differentiate with synthesis testing, multi-tool matrix, and educational focus.
3. **Vivado license:** Batch mode needs a license. Detect availability gracefully. Fallback to GHDL/NVC for CI.
4. **Partial support detection:** Full simulation catches behavioral bugs that analysis-only would miss.
5. **Educational value:** A junior engineer should learn VHDL by browsing `tests/`.
