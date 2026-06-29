"""
Combined comparison matrix generator.

Reads all individual tool/version JSON reports from results/,
produces a combined Markdown matrix table and JSON:
  rows = features (grouped by standard/category)
  columns = tool/version/mode
  cells = PASS / PARTIAL / FAIL / UNTESTED / N/A

Usage:
    python scripts/generate_matrix.py [--results-dir results/]
"""

from __future__ import annotations

import json
import sys
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Optional, Tuple

try:
    from .result_store import TestStatus
except ImportError:
    from result_store import TestStatus


def load_all_results(results_dir: Path) -> Dict[str, dict]:
    """Load all report.json files from the results directory.

    Returns dict mapping tool_key -> report_data.
    tool_key = "tool-version/standard-mode"
    """
    all_reports: Dict[str, dict] = {}

    for json_file in sorted(results_dir.glob("*.json")):
        try:
            data = json.loads(json_file.read_text(encoding="utf-8"))

            # Build a display key from the data
            tool_key = (
                f"{data.get('tool_name', '?')}-{data.get('tool_version', '?')}"
                f"/{data.get('standard', '?')}-{data.get('mode', '?')}"
            )
            all_reports[tool_key] = data

        except Exception as e:
            print(f"Warning: Failed to load {json_file}: {e}")

    return all_reports


def _std_sort_key(std: str) -> int:
    """Sort standards chronologically: 2000, 2002, 2008, 2019."""
    try:
        return int(std)
    except ValueError:
        return 0


def build_feature_index(all_reports: Dict[str, dict]) -> List[Tuple[str, str, str, str]]:
    """Build a sorted list of unique features across all reports.

    Returns list of (standard, category, feature, xref) tuples.
    Deduplicates by (standard, category, feature); picks the first non-empty xref.
    Sorted chronologically by standard; VHDL-2019 sorted by pass/fail
    for the primary tool (PASS before FAIL).
    """
    # Use dict to deduplicate by (std, cat, feature), keeping best xref
    feature_map: Dict[Tuple[str, str, str], str] = {}

    # Determine primary tool column: Questa first, then most informative
    all_columns = sorted(all_reports.keys())
    # Build col_entries for primary tool selection
    col_entries: list[tuple[str, str, str]] = []
    seen: set[str] = set()
    for c in all_columns:
        tool_part = c.split("/")[0]
        std_mode = c.split("/")[1]
        mode = std_mode.split("-")[-1]
        entry_key = f"{tool_part} ({mode})"
        if entry_key not in seen:
            seen.add(entry_key)
            col_entries.append((tool_part, mode, entry_key))
    col_entries = _reorder_column_entries(col_entries)
    primary_col_prefix = _pick_primary_column(all_reports, col_entries)

    for data in all_reports.values():
        for result in data.get("results", {}).values():
            std = result.get("standard", data.get("standard", "?"))
            # Normalize: strip "VHDL-" prefix so _std_sort_key can parse it
            std = std.replace("VHDL-", "")
            key = (std, result.get("category", "?"), result.get("feature", "?"))
            xref = result.get("xref", "")
            # Keep the first non-empty xref found
            if key not in feature_map or (not feature_map[key] and xref):
                feature_map[key] = xref

    # Build list with xrefs
    features: List[Tuple[str, str, str, str]] = [
        (std, cat, feat, xref) for (std, cat, feat), xref in feature_map.items()
    ]

    # Sort: chronological by standard, then by pass/fail priority for primary tool
    def sort_key(item: Tuple[str, str, str, str]) -> tuple:
        std, cat, feat, xref = item
        std_order = _std_sort_key(std)
        status_priority = _get_status_priority(all_reports, primary_col_prefix, std, feat, cat)
        return (std_order, status_priority, cat, feat)

    return sorted(features, key=sort_key)


def _reorder_column_entries(entries: list[tuple[str, str, str]]) -> list[tuple[str, str, str]]:
    """Reorder columns: sim first (Questa, ModelSim, rest), then synth last."""
    ordered: list[tuple[str, str, str]] = []
    # Pull Questa to front
    for prefix in ("questa", "Questa"):
        for e in entries:
            if e[0].lower().startswith(prefix) and e not in ordered:
                ordered.append(e)
    # Pull ModelSim second
    for prefix in ("modelsim", "ModelSim"):
        for e in entries:
            if e[0].lower().startswith(prefix) and e not in ordered:
                ordered.append(e)
    # Rest sim columns alphabetically
    for e in sorted(entries, key=lambda x: x[0].lower()):
        if e not in ordered and e[1] != "synth":
            ordered.append(e)
    # Synth columns last
    for e in sorted(entries, key=lambda x: x[0].lower()):
        if e not in ordered and e[1] == "synth":
            ordered.append(e)
    return ordered


def _pick_primary_column(
    all_reports: Dict[str, dict],
    col_entries: list[tuple[str, str, str]],
) -> str:
    """Pick the column with the most informative results (most non-UNTESTED)."""
    best_col = col_entries[0][0] if col_entries else ""
    best_score = 0
    for tool_part, mode, _display in col_entries:
        score = 0
        for key, data in all_reports.items():
            if key.startswith(tool_part + "/") and data.get("mode") == mode:
                for r in data.get("results", {}).values():
                    if r.get("status", "untested") in ("pass", "partial", "fail"):
                        score += 1
        if score > best_score:
            best_score = score
            best_col = tool_part
    return best_col


def _get_status_priority(
    all_reports: Dict[str, dict],
    tool_prefix: str,
    std: str,
    feature: str,
    category: str,
) -> int:
    """Get sort priority for a feature based on its status.
    0=PASS, 1=PARTIAL, 2=FAIL, 3=UNTESTED/N/A.
    """
    for col_key, data in all_reports.items():
        if col_key.startswith(tool_prefix + "/"):
            result = _find_result(data, feature, category)
            if result:
                result_std = result.get("standard", data.get("standard", "?"))
                # Normalize: strip "VHDL-" prefix for consistent comparison
                if result_std.replace("VHDL-", "") != std:
                    continue
                status = result.get("status", "untested")
                priority = {"pass": 0, "partial": 1, "fail": 2}
                return priority.get(status, 3)
    return 3  # Not found — put at end


def build_status_cell(status: str) -> str:
    """Convert a status string to a compact table cell."""
    mapping = {
        "pass": "✅",
        "partial": "❌",
        "fail": "❌",
        "untested": "⬜",  # not run yet on this tool
        "n/a": "➖",       # genuinely not applicable (e.g., synth for sim-only)
    }
    return mapping.get(status, "⬜")


def generate_matrix_markdown(
    all_reports: Dict[str, dict],
    features: List[Tuple[str, str, str, str]],
) -> str:
    """Generate a combined comparison matrix in Markdown."""
    lines: List[str] = []

    lines.append("# VHDL Compatibility Matrix")
    lines.append("")
    lines.append(f"**Generated from {len(all_reports)} test runs across "
                 f"{len(set(k.split('/')[0] for k in all_reports))} tools.**")
    lines.append("")
    lines.append("> Legend: ✅ PASS  ❌ FAIL  ⬜ not run  ➖ N/A (not applicable to this mode)")
    lines.append("")
    lines.append("> sim = simulation  |  synth = synthesis (only features expected to synthesize)")
    lines.append("")

    # Build column entries: (tool_part, mode, display_name)
    # Each report key is "tool-name-tool-version/standard-mode"
    # Only include sim and synth modes (not analyze)
    columns = sorted(all_reports.keys())
    col_entries: list[tuple[str, str, str]] = []
    seen: set[str] = set()
    for c in columns:
        tool_part = c.split("/")[0]       # "Altera Questa Starter-2025.3"
        std_mode = c.split("/")[1]         # "vhdl2008-sim"
        mode_raw = std_mode.split("-")[-1] # "sim" or "synth"
        if mode_raw == "analyze":
            continue
        entry_key = f"{tool_part} ({mode_raw})"
        if entry_key not in seen:
            seen.add(entry_key)
            # Split tool_part into name and version
            # Format: each word on its own line, then version, then mode
            data = all_reports.get(c, {})
            tool_name = data.get("tool_name", tool_part.rsplit("-", 1)[0] if "-" in tool_part else tool_part)
            tool_ver = data.get("tool_version", tool_part.rsplit("-", 1)[-1] if "-" in tool_part else "")
            # Build multi-line header: name words + version + mode
            name_parts = tool_name.split()
            header_lines = name_parts + [tool_ver, f"({mode_raw})"]
            display = "<br>".join(header_lines)
            col_entries.append((tool_part, mode_raw, display))

    # Reorder: Questa first, ModelSim second, rest alphabetically
    col_entries = _reorder_column_entries(col_entries)

    # Build the table
    col_displays = [e[2] for e in col_entries]
    header = "| Feature | Category | " + " | ".join(col_displays) + " |"
    separator = "|---------|----------|" + "|".join(["---"] * len(col_displays)) + "|"

    lines.append(header)
    lines.append(separator)

    current_std = ""
    for std, category, feature, xref in features:
        # Standard section header
        if std != current_std:
            current_std = std
            # std may be "VHDL-2000" or just "2000" — normalize
            std_clean = std.replace("VHDL-", "")
            lines.append(f"| **VHDL-{std_clean}** | |" + "|".join([""] * len(col_displays)) + "|")

        # Build display name: prepend LCS xref for VHDL-2019, link to test file
        display_feature = feature
        if xref:
            display_feature = f"{xref}: {feature}"

        # Try to find the test file path for this feature to create a link
        test_file = _find_test_file(all_reports, std, feature, category)
        if test_file:
            url = GITHUB_BASE + test_file
            display_feature = f"[{display_feature}]({url})"

        # Build row — iterate over (tool_part, mode, display_name) entries
        row = f"| {display_feature} | {category} |"

        for tool_part, mode, _display in col_entries:
            cell = " ⬜ |"
            # Find the report matching this tool_part, standard, and mode
            for col_key in columns:
                if col_key.startswith(tool_part + "/"):
                    data = all_reports.get(col_key)
                    if data and data.get("mode") == mode:
                        result = _find_result(data, feature, category)
                        if result:
                            result_std = result.get("standard", data.get("standard", "?"))
                            # Normalize: strip "VHDL-" prefix for consistent comparison
                            if result_std.replace("VHDL-", "") == std:
                                cell = f" {build_status_cell(result.get('status', 'untested'))} |"
                        break
            row += cell

        lines.append(row)

    lines.append("")
    return "\n".join(lines)


def _find_result(report_data: dict, feature: str, category: str) -> Optional[dict]:
    """Find a test result in a report matching feature and category."""
    for result in report_data.get("results", {}).values():
        if (result.get("feature") == feature
                and result.get("category") == category):
            return result
    return None


# Base URL for linking to test files on GitHub
GITHUB_BASE = "https://github.com/baverrud/vhdl-compat/blob/main/tests/"


def _find_test_file(all_reports: Dict[str, dict], std: str,
                    feature: str, category: str) -> Optional[str]:
    """Find the test file path for a given feature by scanning reports."""
    candidate = ""
    for data in all_reports.values():
        for result in data.get("results", {}).values():
            result_std = result.get("standard", data.get("standard", "?"))
            # Normalize: strip "VHDL-" prefix for consistent comparison
            if result_std.replace("VHDL-", "") != std:
                continue
            if (result.get("feature") == feature
                    and result.get("category") == category):
                test_file = result.get("test_file", "")
                if test_file:
                    return test_file  # Found one with test_file — use it
                candidate = test_file
    return candidate or None


def _find_result_in_report(report_data: dict, feature: str, category: str) -> Optional[dict]:
    """Find a test result in a report matching feature and category."""
    for result in report_data.get("results", {}).values():
        if (result.get("feature") == feature
                and result.get("category") == category):
            return result
    return None


def generate_vivado_comparison(all_reports: Dict[str, dict]) -> str:
    """Generate sim-vs-synth comparison table for each Vivado version."""
    lines: List[str] = []
    lines.append("")
    lines.append("---")
    lines.append("## Vivado Sim vs Synth Comparison")
    lines.append("")
    lines.append("Features where simulation and synthesis **disagree** —")
    lines.append("works in one but not the other. Highlights the different")
    lines.append("VHDL engines: xvhdl/xsim (Verific parser) vs synth_design.")
    lines.append("")

    # Group reports by Vivado version
    vivado_versions: dict[str, dict[str, dict]] = {}
    for col_key, data in all_reports.items():
        if "vivado" not in col_key.lower():
            continue
        parts = col_key.split("/")
        tool_part = parts[0]
        if "-" not in tool_part:
            continue
        version = tool_part.split("-", 1)[1]
        std_mode = parts[1] if len(parts) > 1 else ""
        mode = std_mode.split("-")[-1] if "-" in std_mode else std_mode
        if version not in vivado_versions:
            vivado_versions[version] = {}
        vivado_versions[version][mode] = data

    for version in sorted(vivado_versions.keys(), reverse=True):
        modes = vivado_versions[version]
        sim_data = modes.get("sim")
        synth_data = modes.get("synth")
        if not sim_data or not synth_data:
            lines.append(f"### Vivado {version}")
            lines.append("")
            if not sim_data:
                lines.append("No simulation results available.")
            if not synth_data:
                lines.append("No synthesis results available.")
            lines.append("")
            continue

        # Find features where sim and synth differ
        diffs: list[tuple[str, str, str, str, str]] = []
        for result in sim_data.get("results", {}).values():
            feature = result.get("feature", "")
            category = result.get("category", "")
            std = result.get("standard", "").replace("VHDL-", "")
            sim_status = result.get("status", "")

            # Skip sim-only features (marked n/a in synth)
            if sim_status == "n/a":
                continue

            synth_result = _find_result_in_report(synth_data, feature, category)
            synth_status = synth_result.get("status", "") if synth_result else "n/a"

            if sim_status == synth_status:
                continue
            if synth_status == "n/a":
                continue  # sim-only feature, not interesting
            if sim_status == "untested" or synth_status == "untested":
                continue

            diffs.append((std, category, feature, sim_status, synth_status))

        if not diffs:
            lines.append(f"### Vivado {version}")
            lines.append("")
            lines.append("No differences — sim and synth agree on all features.")
            lines.append("")
            continue

        # Group by standard
        lines.append(f"### Vivado {version}")
        lines.append("")
        lines.append("| Feature | Standard | Sim | Synth | Notes |")
        lines.append("|---------|----------|:---:|:----:|-------|")
        current_std = ""
        for std, category, feature, sim_status, synth_status in sorted(diffs, key=lambda x: (x[0], x[2])):
            if std != current_std:
                current_std = std
                std_clean = std.replace("VHDL-", "")
                lines.append(f"| **VHDL-{std_clean}** | | | | |")
            sim_cell = "✅" if sim_status == "pass" else "❌"
            synth_cell = "✅" if synth_status == "pass" else "❌"
            if sim_status == "pass":
                note = "Simulation only"
            else:
                note = "Synthesis only"
            display_feature = feature
            test_file = _find_test_file(all_reports, std, feature, category)
            if test_file:
                display_feature = f"[{feature}]({GITHUB_BASE}{test_file})"
            lines.append(f"| {display_feature} | VHDL-{std} | {sim_cell} | {synth_cell} | {note} |")
        lines.append("")

    return "\n".join(lines)


def generate_uvvm_appendix(all_reports: Dict[str, dict]) -> str:
    """Generate UVVM compatibility appendix.

    UVVM (Universal VHDL Verification Methodology) is the most widely used
    open-source VHDL verification framework. Its adoption is a key test of
    real-world VHDL tool compatibility.
    """
    lines: List[str] = []
    lines.append("")
    lines.append("---")
    lines.append("## UVVM Compatibility")
    lines.append("")
    lines.append("UVVM (Universal VHDL Verification Methodology) is the leading")
    lines.append("open-source VHDL verification framework. As of 2026-06-29,")
    lines.append("**uvvm_util (20 files) and uvvm_vvc_framework (8 files) compile")
    lines.append("and run on xsim 2026.1**. A minimal UVVM testbench with logging,")
    lines.append("alerts, and check_value executes successfully.")
    lines.append("")
    lines.append("The only confirmed VHDL language blocker for xsim is **external")
    lines.append("names** (`<< signal >>`), which are required by some VIPs but")
    lines.append("NOT by the UVVM core libraries. Multi-library compilation")
    lines.append("(same file into different libraries) is a Vivado tool limitation")
    lines.append("that affects VVC setup scripts but not VHDL compliance.")
    lines.append("")

    # Determine column order matching the main matrix
    columns = sorted(all_reports.keys())
    col_entries: list[tuple[str, str, str]] = []
    seen: set[str] = set()
    for c in columns:
        tool_part = c.split("/")[0]
        std_mode = c.split("/")[1]
        mode_raw = std_mode.split("-")[-1]
        if mode_raw == "analyze":
            continue
        entry_key = f"{tool_part} ({mode_raw})"
        if entry_key not in seen:
            seen.add(entry_key)
            data = all_reports.get(c, {})
            tool_name = data.get("tool_name", tool_part)
            tool_ver = data.get("tool_version", "")
            name_parts = tool_name.split()
            header_lines = name_parts + [tool_ver, f"({mode_raw})"]
            col_entries.append((tool_part, mode_raw, "<br>".join(header_lines)))
    col_entries = _reorder_column_entries(col_entries)
    # UVVM is simulation-only — filter to sim columns
    col_entries = [e for e in col_entries if e[1] == "sim"]

    # UVVM-critical features — verified against actual UVVM source (28 files)
    # (feature_name, category, standard, description)
    uvvm_features = [
        ("Global shared variables of protected types — package-level shared variables",
         "protected_types", "2000",
         "Working — package-level shared variable (UVVM logger pattern)"),
        ("std.env.stop / std.env.finish — standard simulation control",
         "verification", "2008",
         "Working — UVVM uses std.env for simulation control"),
        ("to_string / to_bstring / to_hstring / to_ostring — formatted string conversion",
         "misc", "2008",
         "Working — UVVM uses string formatting for log messages"),
        ("Unconstrained arrays of unconstrained vectors — UVVM data type pattern",
         "uvvm", "2008",
         "Working — type slv_array is array(<>) of std_logic_vector"),
        ("Protected types with internal access types — UVVM dynamic data pattern",
         "uvvm", "2008",
         "Working — allocate/deallocate in PTs (UVVM command queue)"),
        ("External names targeting arrays and records — UVVM signal spying pattern",
         "uvvm", "2008",
         "BLOCKER — << signal >> not on xsim (VIP BFMs only, not core)"),
    ]

    # Build header row matching main matrix columns
    col_displays = [e[2] for e in col_entries]
    header = "| Feature | Standard | " + " | ".join(col_displays) + " | Description |"
    separator = "|---------|----------|" + "|".join(["---"] * len(col_displays)) + "|-----------|"
    lines.append(header)
    lines.append(separator)

    for feature, category, std, description in uvvm_features:
        display_feature = feature
        test_file = _find_test_file(all_reports, std, feature, category)
        if test_file:
            display_feature = f"[{feature}]({GITHUB_BASE}{test_file})"
        row = f"| {display_feature} | VHDL-{std} |"
        for tool_part, mode, _display in col_entries:
            cell = " ⬜ |"
            for col_key in columns:
                if col_key.startswith(tool_part + "/"):
                    data = all_reports.get(col_key)
                    if data and data.get("mode") == mode:
                        result = _find_result(data, feature, category)
                        if result:
                            result_std = result.get("standard", data.get("standard", "?"))
                            # result_std is "VHDL-2000", std is "2000"
                            if result_std == f"VHDL-{std}":
                                cell = f" {build_status_cell(result.get('status', 'untested'))} |"
                        break
            row += cell
        row += f" {description} |"
        lines.append(row)

    lines.append("")
    lines.append("> **Source:** uvvm_util (20 files) + uvvm_vvc_framework (8 files)")
    lines.append("> compiled with xvhdl 2026.1 — all passed. A minimal UVVM testbench")
    lines.append("> with log(), check_value(), and stop() executed successfully.")
    lines.append("> The only blocker is `<< signal >>` (external names), which UVVM")
    lines.append("> core does NOT use — only certain VIP BFMs need it.")
    lines.append("")
    return "\n".join(lines)


def main(argv: Optional[List[str]] = None) -> int:
    """CLI entry point for matrix generation."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Generate combined VHDL compatibility comparison matrix"
    )
    parser.add_argument(
        "--results-dir", type=str, default="results",
        help="Path to results/ directory"
    )
    args = parser.parse_args(argv)

    results_dir = Path(args.results_dir).resolve()
    if not results_dir.exists():
        print(f"Error: results directory not found: {results_dir}")
        return 1

    all_reports = load_all_results(results_dir)
    if not all_reports:
        print("No report.json files found in results/")
        return 1

    print(f"Loaded {len(all_reports)} report(s)")

    features = build_feature_index(all_reports)
    print(f"Found {len(features)} unique feature(s) across all reports")

    # Generate Markdown — save directly to project root
    md = generate_matrix_markdown(all_reports, features)
    md += generate_vivado_comparison(all_reports)
    md += generate_uvvm_appendix(all_reports)
    root_path = results_dir.parent / "MATRIX.md"
    root_path.write_text(md, encoding="utf-8")
    print(f"Matrix saved: {root_path}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
