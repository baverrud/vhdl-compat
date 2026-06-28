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


def build_feature_index(all_reports: Dict[str, dict]) -> List[Tuple[str, str, str]]:
    """Build a sorted list of unique features across all reports.

    Returns list of (standard, category, feature) tuples.
    """
    features: Dict[Tuple[str, str, str], None] = {}  # ordered set via dict

    for data in all_reports.values():
        std = data.get("standard", "?")
        for result in data.get("results", {}).values():
            key = (std, result.get("category", "?"), result.get("feature", "?"))
            features[key] = None

    return sorted(features.keys(), key=lambda x: (x[0], x[1], x[2]))


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
    features: List[Tuple[str, str, str]],
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

    # Column headers: include standard for uniqueness when same tool runs multiple standards
    columns = sorted(all_reports.keys())
    # key format: "Tool-Ver/Std-Mode" → display as "Tool-Ver (Std)"
    col_headers = []
    for c in columns:
        parts = c.split("/")
        tool_ver = parts[0]
        std_mode = parts[1] if len(parts) > 1 else ""
        std = std_mode.split("-")[0] if std_mode else ""
        # Only add standard suffix if there are multiple runs of the same tool
        same_tool_runs = sum(1 for cc in columns if cc.split("/")[0] == tool_ver)
        if same_tool_runs > 1:
            col_headers.append(f"{tool_ver} ({std})")
        else:
            col_headers.append(tool_ver)

    # Build the table
    header = "| Feature | Standard | Category | " + " | ".join(col_headers) + " |"
    separator = "|---------|----------|----------|" + "|".join(["---"] * len(columns)) + "|"

    lines.append(header)
    lines.append(separator)

    current_std = ""
    for std, category, feature in features:
        # Standard section header
        if std != current_std:
            current_std = std
            lines.append(f"| **VHDL-{std}** | | | |" + " | " * len(columns))

        # Build row
        row = f"| {feature} | {std} | {category} |"

        for col_key in columns:
            data = all_reports.get(col_key)
            if data:
                # Find matching result
                result = _find_result(data, feature, category)
                if result:
                    row += f" {build_status_cell(result.get('status', 'untested'))} |"
                else:
                    row += " ➖ |"
            else:
                row += " ➖ |"

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

    for std, category, feature in features:
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
