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
    """Vivado Design Suite runner for simulation and synthesis."""

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
        Returns N/A for simulation-only tests (not expected to synthesize).
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

        # Simulation-only features are not expected to synthesize
        if test.test_type == "sim" or not test.synth_entity:
            result.status = TestStatus.NOT_APPLICABLE
            result.comment = "Not synthesizable (simulation-only feature)"
            return result

        vivado = self._find_tool("vivado")
        if not vivado:
            result.status = TestStatus.UNTESTED
            result.comment = "vivado not found — check tools/installed.toml"
            return result

        work_dir = self._setup_work_dir()

        # Create a synthesis-safe copy: strip std.env and TB section
        synth_file = work_dir / f"synth_{test.synth_entity}.vhd"
        original = test.file_path.read_text(encoding="utf-8", errors="replace")
        # Strip use std.env.all lines
        clean = "\n".join(
            line for line in original.split("\n")
            if "use std.env.all" not in line
        )
        # Cut at TB_IMPORT: the "library ieee; use ... use std.env.all;" block after RTL
        # Find the TB_IMPORT pattern that appears AFTER the RTL entity
        import re
        rtl_entity_pattern = rf"entity {re.escape(test.synth_entity)}\s+is"
        m_start = re.search(rtl_entity_pattern, clean)
        if m_start:
            # Find TB_IMPORT after RTL entity
            after_rtl = clean[m_start.end():]
            # TB_IMPORT = library + use + use + (use std.env which was already stripped)
            m_tb = re.search(r'library ieee;\s*\nuse ieee\.std_logic_1164\.all;\s*\nuse ieee\.numeric_std\.all;', after_rtl)
            if m_tb:
                cut_pos = m_start.end() + m_tb.start()
                clean = clean[:cut_pos].rstrip()
        synth_file.write_text(clean, encoding="utf-8")

        # Create a synthesis Tcl script targeting the synthesizable entity
        synth_top = test.synth_entity
        vhd_path = str(synth_file.resolve())
        # Map VHDL standard to read_vhdl flag
        std_flag = {"2000": "-vhdl93", "2002": "-vhdl2002", "2008": "-vhdl2008", "2019": "-vhdl2019"}.get(standard, "-vhdl2008")
        tcl_script = (
            f'create_project -in_memory -part xc7a35tcsg324-1\n'
            f'set vhdl_file {{{vhd_path}}}\n'
            f'puts "INFO: Reading VHDL file with {std_flag}: $vhdl_file"\n'
            f'if {{[catch {{read_vhdl {std_flag} $vhdl_file}} err]}} {{\n'
            f'    puts "ERROR: $err"\n'
            f'    exit 1\n'
            f'}}\n'
            f'puts "INFO: Running synth_design -top {synth_top}"\n'
            f'if {{[catch {{synth_design -top {synth_top} -part xc7a35tcsg324-1 -flatten_hierarchy rebuilt}} err]}} {{\n'
            f'    puts "ERROR: $err"\n'
            f'    exit 1\n'
            f'}}\n'
            f'puts "PASS: Synthesis completed successfully"\n'
            f'exit 0\n'
        )
        tcl_path = (work_dir / f"synth_{test.category}.tcl").resolve()
        tcl_path.write_text(tcl_script, encoding="utf-8")

        start = time.time()
        try:
            proc = subprocess.run(
                [str(vivado), "-mode", "batch", "-source", str(tcl_path)],
                capture_output=True, text=True, timeout=300,
                cwd=str(work_dir.resolve()),
            )
            result.compile_time_ms = (time.time() - start) * 1000

            output = proc.stdout + proc.stderr
            result.errors_raw = output[:2000]

            if "PASS: Synthesis completed successfully" in output:
                result.status = TestStatus.PASS
            elif "ERROR:" in output:
                result.status = TestStatus.FAIL
                for line in output.split("\n"):
                    s = line.strip()
                    # Skip Tcl echo lines (start with #) and Vivado banner lines
                    if s.startswith("#") or "Copyright" in s or "All Rights Reserved" in s:
                        continue
                    if "ERROR:" in s:
                        result.comment = s[:200]
                        break
                if not result.comment:
                    result.comment = "Synthesis error (see errors_raw)"
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
        # Match by version — without this, all versions return the first installed Vivado
        for dt in detected.get("vivado", []):
            if dt.version != self.version:
                continue
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
        # xvhdl only supports --2008 and --2019 flags.
        # VHDL-2000 and VHDL-2002 must use -2008 (closest standard with
        # protected type support). VHDL-93 is the default (no flag).
        std_map = {"2000": ["-2008"], "2002": ["-2008"], "2008": ["-2008"], "2019": ["-2019"]}
        return std_map.get(standard, [])
