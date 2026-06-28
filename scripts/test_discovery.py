"""
VHDL test file discovery and metadata parsing.

Scans the tests/ directory tree, parses structured comment headers from each
.vhd file, and builds an in-memory index of all tests.

Metadata format (comment block at top of .vhd file):
    -- STD: VHDL-2008
    -- FEATURE: process(all) — automatic sensitivity list
    -- CATEGORY: processes
    -- TEST_TYPE: sim
    -- DESCRIPTION:
    --   Multi-line description here...
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional


@dataclass
class TestInfo:
    """Parsed metadata for a single VHDL test file."""
    file_path: Path               # absolute path to .vhd file
    relative_path: str            # relative from tests/ root
    standard: str = ""            # VHDL-2000, VHDL-2002, VHDL-2008, VHDL-2019
    feature: str = ""             # human-readable feature name
    category: str = ""            # subdirectory name
    test_type: str = ""           # sim, synth, both, or backcompat
    description: str = ""         # educational explanation
    entity_name: str = ""         # extracted from file (for simulator invocation)
    synth_entity: str = ""        # entity name for synthesis (from SYNTH_ENTITY: tag)
    xref: str = ""                # IEEE cross-reference: LCS2016-XXX or FTXX
    # Backwards-compatibility fields (only for test_type = backcompat)
    valid_in: List[str] = field(default_factory=list)    # Standards where code IS valid
    invalid_in: List[str] = field(default_factory=list)  # Standards where code BREAKS
    break_reason: str = ""        # What changed (keyword, type, syntax, etc.)
    errors: List[str] = field(default_factory=list)  # parse problems


def discover_tests(tests_root: Path) -> Dict[str, TestInfo]:
    """
    Walk tests/ directory, parse every .vhd file, return index keyed by relative path.

    The file path (relative from tests_root) is the canonical test identifier.
    """
    tests: Dict[str, TestInfo] = {}
    _walk_and_parse(tests_root, tests_root, tests)
    return tests


def _walk_and_parse(root: Path, current: Path, tests: Dict[str, TestInfo]) -> None:
    """Recursively walk directories, parse .vhd files."""
    for entry in sorted(current.iterdir()):
        if entry.name.startswith("_") or entry.name.startswith("."):
            continue  # skip templates, hidden files
        if entry.is_dir():
            _walk_and_parse(root, entry, tests)
        elif entry.suffix.lower() == ".vhd":
            info = _parse_vhd_file(root, entry)
            if info.standard:  # only include files with valid metadata
                tests[info.relative_path] = info


def _parse_vhd_file(tests_root: Path, file_path: Path) -> TestInfo:
    """Parse metadata comment header from a VHDL file."""
    info = TestInfo(
        file_path=file_path,
        relative_path=str(file_path.relative_to(tests_root)).replace("\\", "/"),
    )

    try:
        content = file_path.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        info.errors.append(f"Cannot read file: {e}")
        return info

    # Parse metadata lines: -- FIELD: value
    description_lines: List[str] = []
    in_description = False

    for line in content.split("\n"):
        stripped = line.strip()

        # Start of description block
        if stripped.startswith("-- DESCRIPTION:"):
            in_description = True
            desc = stripped[len("-- DESCRIPTION:"):].strip()
            if desc:
                description_lines.append(desc)
            continue

        if in_description:
            # End of description: either a blank comment line, or a new field
            if stripped == "--" or not stripped.startswith("--"):
                info.description = "\n".join(description_lines).strip()
                in_description = False
                continue
            if re.match(r"--\s+[A-Z]+:", stripped):
                # New metadata field — end description
                info.description = "\n".join(description_lines).strip()
                in_description = False
                # Fall through to process this field
            else:
                # Continuation of description
                desc_text = re.sub(r"^--\s?", "", stripped).strip()
                description_lines.append(desc_text)
                continue

        # Parse single-line metadata fields
        m = re.match(r"--\s+STD:\s+(.+)", stripped, re.IGNORECASE)
        if m:
            info.standard = m.group(1).strip()
            continue

        m = re.match(r"--\s+FEATURE:\s+(.+)", stripped, re.IGNORECASE)
        if m:
            info.feature = m.group(1).strip()
            continue

        m = re.match(r"--\s+CATEGORY:\s+(\S+)", stripped, re.IGNORECASE)
        if m:
            info.category = m.group(1).strip()
            continue

        m = re.match(r"--\s+TEST_TYPE:\s+(.+)", stripped, re.IGNORECASE)
        if m:
            info.test_type = m.group(1).strip().lower()
            continue

        # Backwards-compatibility fields
        m = re.match(r"--\s+VALID_IN:\s+(.+)", stripped, re.IGNORECASE)
        if m:
            info.valid_in = [s.strip() for s in m.group(1).split(",")]
            continue

        m = re.match(r"--\s+INVALID_IN:\s+(.+)", stripped, re.IGNORECASE)
        if m:
            info.invalid_in = [s.strip() for s in m.group(1).split(",")]
            continue

        m = re.match(r"--\s+BREAK_REASON:\s+(.+)", stripped, re.IGNORECASE)
        if m:
            info.break_reason = m.group(1).strip()
            continue

        # IEEE cross-reference: LCS number (VHDL-2019) or FT number (VHDL-2008)
        m = re.match(r"--\s+XREF:\s+(.+)", stripped, re.IGNORECASE)
        if m:
            info.xref = m.group(1).strip()
            continue

        # Synthesizable entity name (which entity to run synth_design on)
        m = re.match(r"--\s+SYNTH_ENTITY:\s+(.+)", stripped, re.IGNORECASE)
        if m:
            info.synth_entity = m.group(1).strip()
            continue

        # After parsing at least one metadata field, a separator line
        # or a non-comment line signals the end of the metadata block
        if (info.standard or info.feature or info.category) and (
            stripped.startswith("-- ==") or not stripped.startswith("--")
        ):
            break

    # Handle description that runs to end of comment block
    if in_description:
        info.description = "\n".join(description_lines).strip()

    # Extract entity name for simulator invocation
    info.entity_name = _extract_entity_name(content)

    # Validate
    if not info.standard:
        info.errors.append("Missing STD field")
    if not info.feature:
        info.errors.append("Missing FEATURE field")
    if not info.category:
        info.errors.append("Missing CATEGORY field")
    if not info.test_type:
        info.errors.append("Missing TEST_TYPE field")

    # Additional validation for backcompat tests
    if info.test_type == "backcompat":
        if not info.valid_in:
            info.errors.append("backcompat test missing VALID_IN")
        if not info.invalid_in:
            info.errors.append("backcompat test missing INVALID_IN")
        if not info.break_reason:
            info.errors.append("backcompat test missing BREAK_REASON")

    # Category-directory consistency check (skip for backcompat tests —
    # backcompat/ uses a different directory structure)
    if info.test_type != "backcompat" and info.relative_path and info.category:
        path_parts = info.relative_path.split("/")
        # Path: tests/{standard}/{category}/file.vhd → category is index 1
        if len(path_parts) >= 2:
            actual_category = path_parts[1]
            if info.category != actual_category:
                info.errors.append(
                    f"CATEGORY field '{info.category}' does not match "
                    f"directory '{actual_category}'"
                )

    return info


def _extract_entity_name(content: str) -> str:
    """Extract the testbench entity name from a VHDL file.
    Prefers entity with _tb suffix. Falls back to first entity found.
    """
    tb_pattern = r"^\s*entity\s+(\w+_tb)\s+is"
    any_pattern = r"^\s*entity\s+(\w+)\s+is"

    # First try to find a _tb-suffixed entity (testbench)
    for pattern in [tb_pattern, any_pattern]:
        for m in re.finditer(pattern, content, re.MULTILINE | re.IGNORECASE):
            return m.group(1)
    return ""
