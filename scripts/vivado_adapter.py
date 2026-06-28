"""
Vivado adapter — analysis (xvhdl), simulation (xvhdl + xelab + xsim),
and synthesis (vivado batch Tcl).
"""

import os
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


class VivadoRunner(ToolRunner):
    """Vivado Design Suite runner for analyze, simulate, and synthesize."""

    # ------------------------------------------------------------------
    # Analysis (compile-only with xvhdl)
    # ------------------------------------------------------------------
    def analyze(self, test: TestInfo, standard: str) -> TestResult:
        """Compile the VHDL file with xvhdl. PASS if no errors."""
        result = TestResult(
            test_file=test.relative_path,
            feature=test.feature,
            standard=test.standard,
            category=test.category,
            test_type=test.test_type,
            xref=test.xref,
            mode="analyze",
        )

        xvhdl = self._find_tool("xvhdl")
        if not xvhdl:
            result.status = TestStatus.UNTESTED
            result.comment = "xvhdl not found — check tools/installed.toml"
            return result

        flags = self._get_std_flags(standard)
        work_dir = self._setup_work_dir()

        cmd = [str(xvhdl), "-work", "work", "--nolog"] + flags + [str(test.file_path.resolve())]

        start = time.time()
        try:
            proc = subprocess.run(
                cmd, capture_output=True, text=True, timeout=60,
                cwd=str(work_dir),
            )
            result.compile_time_ms = (time.time() - start) * 1000

            output = proc.stdout + proc.stderr
            result.errors_raw = output[:2000]

            if proc.returncode != 0 or "ERROR" in output or "Error:" in output:
                result.status = TestStatus.FAIL
                for line in output.split("\n"):
                    if "ERROR" in line or "Error:" in line:
                        result.comment = line.strip()[:200]
                        break
                if not result.comment:
                    result.comment = f"xvhdl exit code {proc.returncode}"
            else:
                result.status = TestStatus.PASS

        except subprocess.TimeoutExpired:
            result.status = TestStatus.FAIL
            result.comment = "xvhdl timed out (60s)"
        except Exception as e:
            result.status = TestStatus.FAIL
            result.comment = f"Runner error: {e}"

        return result

    # ------------------------------------------------------------------
    # Simulation (xvhdl + xelab + xsim)
    # ------------------------------------------------------------------
    def simulate(self, test: TestInfo, standard: str, work_dir: Path) -> TestResult:
        """Compile, elaborate, and simulate with xsim.
        Returns PASS only if the test passes its own assertions.
        """
        result = TestResult(
            test_file=test.relative_path,
            feature=test.feature,
            standard=test.standard,
            category=test.category,
            test_type=test.test_type,
            xref=test.xref,
            mode="sim",
        )

        xvhdl = self._find_tool("xvhdl")
        xelab = self._find_tool("xelab")
        xsim = self._find_tool("xsim")
        if not (xvhdl and xelab and xsim):
            result.status = TestStatus.UNTESTED
            result.comment = "Vivado tools not found — check tools/installed.toml"
            return result

        flags = self._get_std_flags(standard)
        entity_name = test.entity_name or f"tb_{test.category}"

        start = time.time()
        try:
            # Step 1: Analyze
            proc = subprocess.run(
                [str(xvhdl), "-work", "work", "--nolog"] + flags + [str(test.file_path.resolve())],
                capture_output=True, text=True, timeout=60,
                cwd=str(work_dir),
            )
            output = proc.stdout + proc.stderr
            if proc.returncode != 0 or "ERROR" in output:
                result.status = TestStatus.FAIL
                result.comment = "Analysis failed"
                result.errors_raw = output[:2000]
                return result

            # Step 2: Elaborate
            proc = subprocess.run(
                [str(xelab), entity_name, "--nolog"],
                capture_output=True, text=True, timeout=60,
                cwd=str(work_dir),
            )
            output = proc.stdout + proc.stderr
            if proc.returncode != 0 or "ERROR" in output:
                result.status = TestStatus.FAIL
                result.comment = "Elaboration failed"
                result.errors_raw = output[:2000]
                return result

            # Step 3: Simulate (run with -R, check for PASS:/FAIL: in output)
            proc = subprocess.run(
                [str(xsim), entity_name, "-R", "--nolog"],
                capture_output=True, text=True, timeout=30,
                cwd=str(work_dir),
            )
            result.sim_time_ms = (time.time() - start) * 1000

            sim_output = proc.stdout + proc.stderr
            result.errors_raw = sim_output[:2000]

            if "PASS:" in sim_output:
                result.status = TestStatus.PASS
            elif "FAIL:" in sim_output:
                result.status = TestStatus.FAIL
                for line in sim_output.split("\n"):
                    if "FAIL:" in line:
                        result.comment = line.strip()[:200]
                        break
            elif proc.returncode != 0:
                result.status = TestStatus.FAIL
                result.comment = f"xsim exit code {proc.returncode}"
            else:
                result.status = TestStatus.FAIL
                result.comment = "No PASS: or FAIL: found in simulation output"

        except subprocess.TimeoutExpired:
            result.status = TestStatus.FAIL
            result.comment = "Simulation timed out"
        except Exception as e:
            result.status = TestStatus.FAIL
            result.comment = f"Runner error: {e}"

        return result

    # ------------------------------------------------------------------
    # Synthesis (vivado -mode batch Tcl)
    # ------------------------------------------------------------------
    def synthesize(self, test: TestInfo, standard: str) -> TestResult:
        """Run Vivado synthesis on the test file using a batch Tcl script.
        PASS if synthesis completes without errors.
        """
        result = TestResult(
            test_file=test.relative_path,
            feature=test.feature,
            standard=test.standard,
            category=test.category,
            test_type=test.test_type,
            xref=test.xref,
            mode="synth",
        )

        vivado = self._find_tool("vivado")
        if not vivado:
            result.status = TestStatus.UNTESTED
            result.comment = "vivado not found — check tools/installed.toml"
            return result

        work_dir = self._setup_work_dir()
        flags = self._get_std_flags(standard)

        # Create a synthesis Tcl script
        tcl_script = f"""
set vhdl_file [file normalize "{test.file_path.resolve()}"]
puts "INFO: Reading VHDL file: $vhdl_file"
if {{[catch {{
    read_vhdl $vhdl_file
}} err]}} {{
    puts "ERROR: $err"
    exit 1
}}
set part xc7k70tfbg676-1
puts "INFO: Running synth_design for part $part"
if {{[catch {{
    synth_design -top {test.entity_name or "test"} -part $part -flatten_hierarchy rebuilt
}} err]}} {{
    puts "ERROR: $err"
    exit 1
}}
puts "PASS: Synthesis completed successfully"
exit 0
"""
        tcl_path = work_dir / f"synth_{test.category}.tcl"
        tcl_path.write_text(tcl_script, encoding="utf-8")

        start = time.time()
        try:
            proc = subprocess.run(
                [str(vivado), "-mode", "batch", "-source", str(tcl_path)],
                capture_output=True, text=True, timeout=300,  # synthesis can take minutes
                cwd=str(work_dir),
            )
            result.compile_time_ms = (time.time() - start) * 1000

            output = proc.stdout + proc.stderr
            result.errors_raw = output[:2000]

            if "PASS: Synthesis completed successfully" in output:
                result.status = TestStatus.PASS
            elif "ERROR" in output:
                result.status = TestStatus.FAIL
                for line in output.split("\n"):
                    if "ERROR" in line:
                        result.comment = line.strip()[:200]
                        break
            else:
                result.status = TestStatus.FAIL
                result.comment = f"vivado exit code {proc.returncode}"

        except subprocess.TimeoutExpired:
            result.status = TestStatus.FAIL
            result.comment = "Synthesis timed out (300s)"
        except Exception as e:
            result.status = TestStatus.FAIL
            result.comment = f"Runner error: {e}"

        return result

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------
    def _setup_work_dir(self) -> Path:
        """Create a working directory for this tool/version."""
        work_dir = Path(f"tmp/vivado-{self.version}")
        work_dir.mkdir(parents=True, exist_ok=True)
        return work_dir

    def _find_tool(self, exe_name: str) -> Path | None:
        """Find a Vivado tool executable (xvhdl, xelab, xsim, vivado)."""
        import sys
        project_root = Path(__file__).resolve().parent.parent
        if str(project_root) not in sys.path:
            sys.path.insert(0, str(project_root))
        try:
            from scripts.tool_discovery import detect_installed_versions
        except ImportError:
            from tool_discovery import detect_installed_versions

        detected = detect_installed_versions(Path("tools"), verbose=False)
        for dt in detected.get("vivado", []):
            # Check common executable extensions on Windows
            for exe_name_variant in (f"{exe_name}.exe", f"{exe_name}.bat", exe_name):
                exe_path = dt.exe_dir / exe_name_variant
                if exe_path.exists():
                    return exe_path
        return None

    def _get_std_flags(self, standard: str) -> list:
        """Get VHDL standard flags for the analyzer tool."""
        std_cfg = self.config.get_standard_config(f"vhdl{standard}")
        if std_cfg.analysis_flags:
            return list(std_cfg.analysis_flags)
        std_map = {"2000": ["-2002"], "2002": ["-2002"], "2008": ["-2008"], "2019": ["-2019"]}
        return std_map.get(standard, [])
