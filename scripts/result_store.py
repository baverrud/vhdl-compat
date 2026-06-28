"""
Result storage and accumulation.

Design: In-memory dict for O(1) lookup by test identifier.
Persists to JSON on write. RAM acceptable per project conventions.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Any, Dict, Optional


class TestStatus(Enum):
    """Three-state result: PASS, PARTIAL, or FAIL."""
    PASS = "pass"
    PARTIAL = "partial"  # compiles but behaves incorrectly
    FAIL = "fail"
    UNTESTED = "untested"
    NOT_APPLICABLE = "n/a"  # e.g., synthesis for sim-only tool


@dataclass
class TestResult:
    """Result for a single test file."""
    test_file: str           # relative path from tests/
    feature: str             # human-readable feature name
    standard: str            # VHDL-2000, VHDL-2002, VHDL-2008, VHDL-2019
    category: str            # subdirectory category
    test_type: str           # sim, synth, or both
    mode: str                # analyze, sim, or synth
    xref: str = ""           # IEEE cross-reference: LCS2016-XXX or FTXX
    status: TestStatus = TestStatus.UNTESTED
    comment: str = ""        # human explanation for PARTIAL or FAIL
    errors_raw: str = ""     # raw tool output on failure
    compile_time_ms: float = 0.0
    sim_time_ms: float = 0.0


@dataclass
class RunResult:
    """Aggregate result for a single tool/version/standard/mode run."""
    tool_name: str
    tool_version: str
    standard: str
    mode: str                 # analyze, sim, or synth
    results: Dict[str, TestResult] = field(default_factory=dict)
    timestamp: str = ""

    @property
    def pass_count(self) -> int:
        return sum(1 for r in self.results.values() if r.status == TestStatus.PASS)

    @property
    def partial_count(self) -> int:
        return sum(1 for r in self.results.values() if r.status == TestStatus.PARTIAL)

    @property
    def fail_count(self) -> int:
        return sum(1 for r in self.results.values() if r.status == TestStatus.FAIL)

    @property
    def total_count(self) -> int:
        return len(self.results)

    def to_dict(self) -> Dict[str, Any]:
        """Serialize to a JSON-compatible dict."""
        return {
            "tool_name": self.tool_name,
            "tool_version": self.tool_version,
            "standard": self.standard,
            "mode": self.mode,
            "timestamp": self.timestamp,
            "summary": {
                "total": self.total_count,
                "pass": self.pass_count,
                "partial": self.partial_count,
                "fail": self.fail_count,
            },
            "results": {
                key: {
                    "status": r.status.value,
                    "feature": r.feature,
                    "category": r.category,
                    "test_type": r.test_type,
                    "xref": r.xref,
                    "comment": r.comment,
                    "compile_time_ms": r.compile_time_ms,
                    "sim_time_ms": r.sim_time_ms,
                }
                for key, r in sorted(self.results.items())
            }
        }

    def save_json(self, path: Path) -> None:
        """Write results to a JSON file."""
        path.parent.mkdir(parents=True, exist_ok=True)
        data = self.to_dict()
        path.write_text(json.dumps(data, indent=2), encoding="utf-8")
