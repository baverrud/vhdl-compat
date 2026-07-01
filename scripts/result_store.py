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
    mode: str                # sim or synth
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
                    "standard": r.standard,
                    "feature": r.feature,
                    "category": r.category,
                    "test_type": r.test_type,
                    "xref": r.xref,
                    "test_file": r.test_file,
                    "comment": r.comment,
                    "compile_time_ms": r.compile_time_ms,
                    "sim_time_ms": r.sim_time_ms,
                }
                for key, r in sorted(self.results.items())
            }
        }

    @classmethod
    def load_json(cls, path: Path) -> Optional["RunResult"]:
        """Load results from a JSON file. Returns None if file does not exist."""
        if not path.exists():
            return None
        data = json.loads(path.read_text(encoding="utf-8"))
        rr = cls(
            tool_name=data.get("tool_name", ""),
            tool_version=data.get("tool_version", ""),
            standard=data.get("standard", ""),
            mode=data.get("mode", ""),
            timestamp=data.get("timestamp", ""),
        )
        for key, rd in data.get("results", {}).items():
            tr = TestResult(
                test_file=rd.get("test_file", ""),
                feature=rd.get("feature", ""),
                standard=rd.get("standard", ""),
                category=rd.get("category", ""),
                test_type=rd.get("test_type", ""),
                mode=rd.get("mode", rr.mode),
                xref=rd.get("xref", ""),
                status=TestStatus(rd.get("status", "untested")),
                comment=rd.get("comment", ""),
                errors_raw=rd.get("errors_raw", ""),
                compile_time_ms=rd.get("compile_time_ms", 0.0),
                sim_time_ms=rd.get("sim_time_ms", 0.0),
            )
            rr.results[key] = tr
        return rr

    def save_json(self, path: Path) -> None:
        """Merge new results with any existing file, then save.

        Existing results for tests NOT in this run are preserved unchanged.
        The standard is set to "combined" (individual results carry their own
        standard) and the timestamp is updated to now.
        """
        path.parent.mkdir(parents=True, exist_ok=True)
        # Load existing results if any
        existing = RunResult.load_json(path)
        if existing:
            # Keep existing results for tests we didn't run; our results take priority
            for key, r in existing.results.items():
                if key not in self.results:
                    self.results[key] = r
        data = self.to_dict()
        path.write_text(json.dumps(data, indent=2), encoding="utf-8")
