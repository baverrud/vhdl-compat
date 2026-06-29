"""Questa Advanced Simulator adapter — analysis (compile-check) mode.
See docs/tool-notes.md for Questa quirks and exit code handling.
"""

import os
import shutil
import subprocess
import time
from pathlib import Path

try:
    from .result_store import TestResult, TestStatus
    from .test_discovery import TestInfo
    from .tool_discovery import ToolConfig
    from .tool_runner import ToolRunner
except ImportError:
    from result_store import TestResult, TestStatus
    from test_discovery import TestInfo
    from tool_discovery import ToolConfig
    from tool_runner import ToolRunner


class QuestaRunner(ToolRunner):
    """Questa Advanced Simulator runner using vcom for compile-check."""

    def _setup_work_dir(self, clean: bool = False) -> Path:
        """Create and return the working directory. Optionally clean it first."""
        work_dir = Path(f"tmp/questa-{self.version}")
        if clean and work_dir.exists():
            shutil.rmtree(work_dir, ignore_errors=True)
        work_dir.mkdir(parents=True, exist_ok=True)
        return work_dir

    def _cleanup_locks(self, work_dir: Path) -> None:
        """Remove Questa lock files that block re-compilation."""
        lock = work_dir / "work" / "_lock"
        if lock.exists():
            try:
                lock.unlink()
            except OSError:
                pass

    def _cleanup_work(self, work_dir: Path) -> None:
        """Remove work library artifacts after a run."""
        work_lib = work_dir / "work"
        if work_lib.exists():
            shutil.rmtree(work_lib, ignore_errors=True)

    @staticmethod
    def _kill_vcom() -> None:
        """Kill stuck vcom processes (Windows + Linux)."""
        try:
            if os.name == "nt":
                subprocess.run(
                    ["taskkill", "/F", "/IM", "vcom.exe"],
                    capture_output=True, timeout=5,
                )
            else:
                subprocess.run(
                    ["pkill", "-9", "vcom"],
                    capture_output=True, timeout=5,
                )
        except Exception:
            pass

    def _compile(self, test: TestInfo, standard: str) -> TestResult:
        """Compile the VHDL file with vcom. Returns result with compile_time_ms."""
        result = TestResult(
            test_file=test.relative_path,
            feature=test.feature,
            standard=test.standard,
            category=test.category,
            test_type=test.test_type,
            xref=test.xref,
            mode="analyze",
        )

        vcom = self._find_vcom()
        if not vcom:
            result.status = TestStatus.UNTESTED
            result.comment = "vcom not found — check tools/installed.toml"
            return result

        flags = self._get_std_flags(standard)
        work_dir = self._setup_work_dir()
        self._cleanup_locks(work_dir)

        cmd = [str(vcom), "-work", "work", "-quiet"] + flags + [str(test.file_path.resolve())]

        start = time.time()
        try:
            proc = subprocess.run(
                cmd,
                capture_output=True, text=True, timeout=30,
                cwd=str(work_dir),
            )
            result.compile_time_ms = (time.time() - start) * 1000

            output = proc.stdout + proc.stderr
            # Filter lockfile spam from starter edition
            clean = "\n".join(
                l for l in output.split("\n") if "Lockfile is" not in l
            )
            result.errors_raw = clean[:2000]

            # Questa exit code is unreliable — grep for actual errors
            # Match both "** Error:" and "** Error (suppressible):" formats
            if "** Error" in output:
                result.status = TestStatus.FAIL
                for line in output.split("\n"):
                    if "** Error:" in line:
                        result.comment = line.strip()[:200]
                        break
            else:
                result.status = TestStatus.PASS

        except subprocess.TimeoutExpired:
            result.status = TestStatus.FAIL
            result.comment = "Compilation timed out (30s)"
            self._kill_vcom()
        except Exception as e:
            result.status = TestStatus.FAIL
            result.comment = f"Runner error: {e}"

        return result

    def simulate(self, test: TestInfo, standard: str, work_dir: Path) -> TestResult:
        return self._compile(test, standard)

    def _find_vcom(self) -> Path | None:
        import sys
        project_root = Path(__file__).resolve().parent.parent
        if str(project_root) not in sys.path:
            sys.path.insert(0, str(project_root))
        try:
            from scripts.tool_discovery import detect_installed_versions
        except ImportError:
            from tool_discovery import detect_installed_versions

        detected = detect_installed_versions(Path("tools"), verbose=False)
        # Only search for the tool this runner was configured for
        tool_key = self.config.name.lower()
        for dt in detected.get(tool_key, []):
            vcom = dt.exe_dir / ("vcom.exe" if os.name == "nt" else "vcom")
            if vcom.exists():
                return vcom
        return None

    def _get_std_flags(self, standard: str) -> list:
        std_cfg = self.config.get_standard_config(f"vhdl{standard}")
        if std_cfg.analysis_flags:
            return list(std_cfg.analysis_flags)
        # VHDL-2000/2002 features are subsets of 2008 — test with closest flag
        std_map = {"2000": ["-2002"], "2002": ["-2002"], "2008": ["-2008"], "2019": ["-2019"]}
        return std_map.get(standard, ["-2008"])
