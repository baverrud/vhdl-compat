"""
Report generator: converts RunResult to Markdown and JSON reports.

Design: reads JSON from results/ dir, produces human-readable Markdown.
JSON is the canonical format; Markdown is generated from JSON.
"""

from __future__ import annotations

from pathlib import Path
from typing import List

try:
    from .result_store import RunResult, TestResult, TestStatus
except ImportError:
    from result_store import RunResult, TestResult, TestStatus


def generate_markdown_report(result: RunResult) -> str:
    """Generate a comprehensive Markdown report for a single run."""

    lines: List[str] = []

    # Header
    lines.append(f"# {result.tool_name} {result.tool_version} — "
                 f"VHDL-{result.standard} ({result.mode})")
    lines.append("")
    lines.append(f"**Generated:** {result.timestamp}")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Summary
    lines.append("## Summary")
    lines.append("")
    total = result.total_count
    pct = (result.pass_count / total * 100) if total > 0 else 0
    lines.append(f"| Metric | Count |")
    lines.append(f"|--------|-------|")
    lines.append(f"| Total tests | {total} |")
    lines.append(f"| PASS | {result.pass_count} |")
    lines.append(f"| PARTIAL | {result.partial_count} |")
    lines.append(f"| FAIL | {result.fail_count} |")
    lines.append(f"| **Pass rate** | **{pct:.1f}%** |")
    lines.append("")

    # Results by category
    lines.append("## Results by Category")
    lines.append("")

    # Group by category
    by_category: dict[str, list[TestResult]] = {}
    for r in result.results.values():
        by_category.setdefault(r.category, []).append(r)

    for category in sorted(by_category):
        cat_results = by_category[category]
        lines.append(f"### {category}")
        lines.append("")
        lines.append("| Feature | Status | Comment |")
        lines.append("|---------|--------|---------|")

        for r in sorted(cat_results, key=lambda x: x.feature):
            status_emoji = {
                TestStatus.PASS: "✅ PASS",
                TestStatus.PARTIAL: "⚠️ PARTIAL",
                TestStatus.FAIL: "❌ FAIL",
                TestStatus.UNTESTED: "⬜ UNTESTED",
                TestStatus.NOT_APPLICABLE: "➖ N/A",
            }.get(r.status, "?")

            comment = r.comment.replace("|", "\\|") if r.comment else ""
            lines.append(f"| {r.feature} | {status_emoji} | {comment} |")

        lines.append("")

    # Detailed failures
    failures = [r for r in result.results.values() if r.status != TestStatus.PASS]
    if failures:
        lines.append("## Non-Passing Tests")
        lines.append("")
        for r in sorted(failures, key=lambda x: x.feature):
            lines.append(f"### {r.feature}")
            lines.append("")
            lines.append(f"- **Status:** {r.status.value.upper()}")
            lines.append(f"- **Category:** {r.category}")
            lines.append(f"- **Test type:** {r.test_type}")
            if r.comment:
                lines.append(f"- **Comment:** {r.comment}")
            if r.errors_raw:
                lines.append("")
                lines.append("```")
                lines.append(r.errors_raw[:2000])  # truncate very long output
                lines.append("```")
            lines.append("")

    return "\n".join(lines)


def save_markdown_report(result: RunResult, path: Path) -> None:
    """Save a Markdown report to a file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    md = generate_markdown_report(result)
    path.write_text(md, encoding="utf-8")
