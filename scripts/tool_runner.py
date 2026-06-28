"""
Abstract tool runner interface and generic placeholder.

ToolRunner is the abstract base class that all tool-specific adapters subclass.
GenericRunner is a placeholder that reports UNTESTED until real adapters exist.

To add a new tool:
  1. Create scripts/{tool}_adapter.py
  2. Subclass ToolRunner
  3. Implement analyze(), simulate(), and optionally synthesize()
  4. Register it in ADAPTER_REGISTRY below
"""

from __future__ import annotations

import subprocess
import time
from abc import ABC, abstractmethod
from pathlib import Path

try:
    from .result_store import TestResult, TestStatus
    from .test_discovery import TestInfo
    from .tool_discovery import ToolConfig
except ImportError:
    from result_store import TestResult, TestStatus
    from test_discovery import TestInfo
    from tool_discovery import ToolConfig


class ToolRunner(ABC):
    """Abstract base for tool-specific adapters.

    Subclasses implement the tool-specific subprocess invocations for:
      - analyze(): compile/lint the VHDL file
      - simulate(): compile + elaborate + run, capture PASS/FAIL
      - synthesize(): run synthesis via Tcl batch or equivalent
    """

    def __init__(self, config: ToolConfig, version: str):
        self.config = config
        self.version = version

    @abstractmethod
    def analyze(self, test: TestInfo, standard: str) -> TestResult:
        """Compile/check the VHDL file. Return result with status."""

    @abstractmethod
    def simulate(self, test: TestInfo, standard: str, work_dir: Path) -> TestResult:
        """Compile, elaborate, and simulate. Return result with PASS/FAIL."""

    def synthesize(self, test: TestInfo, standard: str) -> TestResult:
        """Run synthesis. Default: not supported."""
        result = TestResult(
            test_file=test.relative_path,
            feature=test.feature,
            standard=test.standard,
            category=test.category,
            test_type=test.test_type,
            mode="synth",
            status=TestStatus.NOT_APPLICABLE,
            comment="Synthesis not supported by this tool",
        )
        return result

    def run_test(self, test: TestInfo, standard: str, mode: str,
                 work_dir: Path) -> TestResult:
        """Dispatch to the appropriate method based on mode."""
        if mode == "analyze":
            return self.analyze(test, standard)
        elif mode == "sim":
            return self.simulate(test, standard, work_dir)
        elif mode == "synth":
            return self.synthesize(test, standard)
        else:
            return TestResult(
                test_file=test.relative_path,
                feature=test.feature,
                standard=test.standard,
                category=test.category,
                test_type=test.test_type,
                mode=mode,
                status=TestStatus.FAIL,
                comment=f"Unknown mode: {mode}",
            )


class GenericRunner(ToolRunner):
    """Placeholder runner that marks all tests as UNTESTED.

    Replace with real tool-specific adapters as they are implemented.
    """

    def analyze(self, test: TestInfo, standard: str) -> TestResult:
        return TestResult(
            test_file=test.relative_path,
            feature=test.feature,
            standard=test.standard,
            category=test.category,
            test_type=test.test_type,
            mode="analyze",
            status=TestStatus.UNTESTED,
            comment="Tool adapter not yet implemented",
        )

    def simulate(self, test: TestInfo, standard: str, work_dir: Path) -> TestResult:
        return TestResult(
            test_file=test.relative_path,
            feature=test.feature,
            standard=test.standard,
            category=test.category,
            test_type=test.test_type,
            mode="sim",
            status=TestStatus.UNTESTED,
            comment="Tool adapter not yet implemented",
        )

    def synthesize(self, test: TestInfo, standard: str) -> TestResult:
        if not self.config.synth.supported:
            return TestResult(
                test_file=test.relative_path,
                feature=test.feature,
                standard=test.standard,
                category=test.category,
                test_type=test.test_type,
                mode="synth",
                status=TestStatus.NOT_APPLICABLE,
                comment="Synthesis not supported by this tool",
            )
        return TestResult(
            test_file=test.relative_path,
            feature=test.feature,
            standard=test.standard,
            category=test.category,
            test_type=test.test_type,
            mode="synth",
            status=TestStatus.UNTESTED,
            comment="Tool adapter not yet implemented",
        )


# ---------------------------------------------------------------------------
# Adapter registry — maps tool names to runner classes
# Add new adapters here when they are created.
# ---------------------------------------------------------------------------
ADAPTER_REGISTRY: dict[str, type[ToolRunner]] = {
    "questa": None,  # Imported lazily to avoid circular imports
    "vivado": None,
}
