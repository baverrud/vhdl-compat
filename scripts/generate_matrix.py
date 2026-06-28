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

    for json_file in sorted(results_dir.rglob("report.json")):
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

    # Determine primary tool column: prefer one with most PASS results
    # (alphabetically first may be a tool with no VHDL-2019 support)
    all_columns = sorted(all_reports.keys())
    col_headers = list(dict.fromkeys(c.split("/")[0] for c in all_columns))
    primary_col_prefix = _pick_primary_column(all_reports, col_headers)

    for data in all_reports.values():
        std = data.get("standard", "?")
        for result in data.get("results", {}).values():
            key = (std, result.get("category", "?"), result.get("feature", "?"))
            xref = result.get("xref", "")
            # Keep the first non-empty xref found
            if key not in feature_map or (not feature_map[key] and xref):
                feature_map[key] = xref

    # Build list with xrefs
    features: List[Tuple[str, str, str, str]] = [
        (std, cat, feat, xref) for (std, cat, feat), xref in feature_map.items()
    ]

    # Sort: chronological by standard, then VHDL-2019 by pass/fail priority
    def sort_key(item: Tuple[str, str, str, str]) -> tuple:
        std, cat, feat, xref = item
        std_order = _std_sort_key(std)
        if std == "2019":
            status_priority = _get_status_priority(all_reports, primary_col_prefix, std, feat, cat)
            return (std_order, status_priority, cat, feat)
        else:
            return (std_order, 0, cat, feat)

    return sorted(features, key=sort_key)


def _pick_primary_column(
    all_reports: Dict[str, dict],
    col_headers: List[str],
) -> str:
    """Pick the column with the most informative results (most non-UNTESTED)."""
    best_col = col_headers[0] if col_headers else ""
    best_score = 0
    for col in col_headers:
        # Count how many results this column has that are PASS, PARTIAL, or FAIL
        score = 0
        for key, data in all_reports.items():
            if key.startswith(col + "/"):
                for r in data.get("results", {}).values():
                    if r.get("status", "untested") in ("pass", "partial", "fail"):
                        score += 1
        if score > best_score:
            best_score = score
            best_col = col
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
        if col_key.startswith(tool_prefix + "/") and data.get("standard") == std:
            result = _find_result(data, feature, category)
            if result:
                status = result.get("status", "untested")
                priority = {"pass": 0, "partial": 1, "fail": 2}
                return priority.get(status, 3)
    return 3  # Not found — put at end


def build_status_cell(status: str) -> str:
    """Convert a status string to a compact table cell."""
    mapping = {
        "pass": "✅",
        "partial": "⚠️",
        "fail": "❌",
        "untested": "⬜",
        "n/a": "➖",
    }
    return mapping.get(status, "?")


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
    lines.append("> Legend: ✅ PASS  ⚠️ PARTIAL  ❌ FAIL  ⬜ UNTESTED  ➖ N/A")
    lines.append("")

    # Column headers: group by unique tool-version, deduplicate across standards
    columns = sorted(all_reports.keys())
    # Extract unique tool-version identifiers (first part of key before /)
    col_headers = list(dict.fromkeys(c.split("/")[0] for c in columns))

    # Build the table
    header = "| Feature | Standard | Category | " + " | ".join(col_headers) + " |"
    separator = "|---------|----------|----------|" + "|".join(["---"] * len(col_headers)) + "|"

    lines.append(header)
    lines.append(separator)

    current_std = ""
    for std, category, feature, xref in features:
        # Standard section header
        if std != current_std:
            current_std = std
            lines.append(f"| **VHDL-{std}** | | | |" + " | " * len(col_headers))

        # Build display name: prepend LCS xref for VHDL-2019
        display_feature = feature
        if xref:
            display_feature = f"{xref}: {feature}"

        # Build row
        row = f"| {display_feature} | {std} | {category} |"

        for tool_ver in col_headers:
            # Find the report for this tool-version that matches the feature's standard
            cell = " ➖ |"
            for col_key in columns:
                if col_key.startswith(tool_ver + "/"):
                    data = all_reports.get(col_key)
                    if data and data.get("standard") == std:
                        result = _find_result(data, feature, category)
                        if result:
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


def generate_matrix_json(
    all_reports: Dict[str, dict],
    features: List[Tuple[str, str, str]],
) -> dict:
    """Generate a combined comparison matrix in JSON-compatible dict."""
    columns = sorted(all_reports.keys())

    matrix = {
        "columns": columns,
        "features": [],
    }

    for std, category, feature, xref in features:
        row = {
            "standard": std,
            "category": category,
            "feature": feature,
            "results": {},
        }
        for col_key in columns:
            data = all_reports.get(col_key)
            result = None
            if data:
                result = _find_result(data, feature, category)
            row["results"][col_key] = {
                "status": result.get("status", "untested") if result else "untested",
                "comment": result.get("comment", "") if result else "",
            }
        matrix["features"].append(row)

    return matrix


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

    # Generate Markdown
    md = generate_matrix_markdown(all_reports, features)
    md_path = results_dir / "matrix.md"
    md_path.write_text(md, encoding="utf-8")
    print(f"Matrix (Markdown) saved: {md_path}")

    # Generate JSON
    json_data = generate_matrix_json(all_reports, features)
    json_path = results_dir / "matrix.json"
    json_path.write_text(json.dumps(json_data, indent=2), encoding="utf-8")
    print(f"Matrix (JSON) saved: {json_path}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
