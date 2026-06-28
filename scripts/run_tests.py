"""
Abstract tool runner interface and the CLI entry point.

Each EDA tool gets its own adapter that subclasses ToolRunner.
The CLI orchestrates: discover → configure → run → report.

Usage:
    python scripts/run_tests.py --list
    python scripts/run_tests.py --tool vivado --version 2024.1 --std 2008 --mode sim
    python scripts/run_tests.py --all-tools --all-stds --mode both
"""

from __future__ import annotations

import argparse
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple

try:
    from .result_store import RunResult, TestResult, TestStatus
    from .test_discovery import TestInfo, discover_tests
    from .tool_discovery import ToolConfig, DetectionConfig, DetectedTool, discover_tool_configs, load_tool_config, detect_installed_versions
    from .tool_runner import ToolRunner, GenericRunner
except ImportError:
    from result_store import RunResult, TestResult, TestStatus
    from test_discovery import TestInfo, discover_tests
    from tool_discovery import ToolConfig, DetectionConfig, DetectedTool, discover_tool_configs, load_tool_config, detect_installed_versions
    from tool_runner import ToolRunner, GenericRunner


# ============================================================================
# CLI Entry Point
# ============================================================================

def build_parser() -> argparse.ArgumentParser:
    """Build the command-line argument parser."""
    parser = argparse.ArgumentParser(
        description="VHDL Compatibility Test Suite Runner",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    # What to run
    parser.add_argument(
        "--tool", type=str,
        help="Tool name (vivado, questa, modelsim, ghdl, nvc, ...)"
    )
    parser.add_argument(
        "--version", type=str, default="latest",
        help="Tool version (e.g., 2024.1)"
    )
    parser.add_argument(
        "--std", type=str, action="append", dest="standards",
        help="VHDL standard to test (2000, 2002, 2008, 2019). Repeatable."
    )
    parser.add_argument(
        "--mode", type=str, default="sim",
        choices=["analyze", "sim", "synth", "both"],
        help="Test mode (default: sim)"
    )
    parser.add_argument(
        "--category", type=str, action="append",
        help="Only run tests in this category. Repeatable."
    )

    # Discovery
    parser.add_argument(
        "--list", action="store_true",
        help="List all discovered tests and exit"
    )
    parser.add_argument(
        "--list-tools", action="store_true",
        help="List all configured tools and exit"
    )
    parser.add_argument(
        "--detect", action="store_true",
        help="Scan system for installed EDA tool versions and exit"
    )

    # Paths
    parser.add_argument(
        "--tests-dir", type=str, default="tests",
        help="Path to tests/ directory"
    )
    parser.add_argument(
        "--tools-dir", type=str, default="tools",
        help="Path to tools/ directory"
    )
    parser.add_argument(
        "--results-dir", type=str, default="results",
        help="Path to results/ directory"
    )
    parser.add_argument(
        "--work-dir", type=str, default=None,
        help="Working directory for simulation (default: temp dir)"
    )

    # Options
    parser.add_argument(
        "--verbose", "-v", action="store_true",
        help="Verbose output"
    )
    parser.add_argument(
        "--stop-on-fail", action="store_true",
        help="Stop after first failure"
    )

    return parser


def resolve_paths(args) -> Tuple[Path, Path, Path]:
    """Resolve and validate directory paths from CLI args."""
    project_root = Path(__file__).resolve().parent.parent
    tests_dir = (project_root / args.tests_dir).resolve()
    tools_dir = (project_root / args.tools_dir).resolve()
    results_dir = (project_root / args.results_dir).resolve()

    if not tests_dir.exists():
        sys.exit(f"Error: tests directory not found: {tests_dir}")
    if not tools_dir.exists():
        sys.exit(f"Error: tools directory not found: {tools_dir}")

    return tests_dir, tools_dir, results_dir


def cli_list_tests(tests_dir: Path) -> None:
    """List all discovered tests."""
    tests = discover_tests(tests_dir)
    if not tests:
        print("No tests found.")
        return

    print(f"\nFound {len(tests)} test(s):\n")
    print(f"{'Standard':<12} {'Category':<24} {'Feature':<50} {'Type':<6}")
    print("-" * 94)

    for key, info in sorted(tests.items()):
        print(
            f"{info.standard:<12} "
            f"{info.category:<24} "
            f"{info.feature:<50.50} "
            f"{info.test_type:<6}"
        )
        if info.errors:
            for err in info.errors:
                print(f"  ⚠ {err}")

    print()


def cli_list_tools(tools_dir: Path) -> None:
    """List all configured tools."""
    configs = discover_tool_configs(tools_dir)
    if not configs:
        print("No tool configurations found.")
        return

    print(f"\nConfigured tools ({len(configs)}):\n")
    print(f"{'Name':<15} {'Vendor':<25} {'Type':<8} {'Description'}")
    print("-" * 90)

    for name, cfg in sorted(configs.items()):
        print(
            f"{cfg.name:<15} "
            f"{cfg.vendor:<25} "
            f"{cfg.tool_type:<8} "
            f"{cfg.description}"
        )

    print()


def cli_detect_tools(tools_dir: Path, verbose: bool = False) -> None:
    """Discover installed EDA tool versions (manual config or auto-scan)."""
    manual_path = tools_dir / "installed.toml"

    print("\nTool discovery:")
    print(f"  Manual config: {'FOUND' if manual_path.exists() else 'not found'} "
          f"({manual_path})")
    print(f"  Auto-scan:     available via --detect (slower, may be invasive)")
    print()

    if not manual_path.exists():
        print("Tip: Create tools/installed.toml to declare your tools manually.")
        print("     Copy tools/installed.example.toml as a starting point.\n")

    detected = detect_installed_versions(tools_dir, verbose=verbose)

    if not detected:
        print("No EDA tools configured.")
        print("Options:")
        print("  1. Copy tools/installed.example.toml -> tools/installed.toml and edit paths")
        print("  2. Or run with --verbose to see auto-scan details")
        return

    print(f"{'Tool':<15} {'Version':<14} {'Path'}")
    print("-" * 70)

    for tool_key, versions in sorted(detected.items()):
        for dt in sorted(versions, key=lambda d: _parse_version(d.version), reverse=True):
            print(f"{dt.tool_name:<15} {dt.version:<14} {dt.exe_dir}")

    print(f"\nFound {sum(len(v) for v in detected.values())} installation(s).")
    print(f"\nUsage examples:")
    for tool_key, versions in sorted(detected.items()):
        if versions:
            latest = max(versions, key=lambda d: _parse_version(d.version))
            print(f"  vhdl-compat --tool {tool_key} --version {latest.version} --std 2008 --mode sim")


def run_tests(
    runner: ToolRunner,
    tests: Dict[str, TestInfo],
    standard: str,
    modes: List[str],
    work_dir: Path,
    verbose: bool = False,
    stop_on_fail: bool = False,
) -> RunResult:
    """Run all applicable tests with the given runner and collect results."""
    result = RunResult(
        tool_name=runner.config.name,
        tool_version=runner.version,
        standard=standard,
        mode="+".join(modes),
        timestamp=datetime.now(timezone.utc).isoformat(),
    )

    test_list = sorted(tests.items())
    total = len(test_list)

    for idx, (key, info) in enumerate(test_list, 1):
        if not _standard_matches(info.standard, standard):
            continue

        for mode in modes:
            if mode == "synth" and info.test_type not in ("synth", "both"):
                continue
            if mode in ("analyze", "sim") and info.test_type not in ("sim", "both"):
                continue

            test_key = f"{key}@{mode}"
            if verbose:
                print(f"  [{idx}/{total}] {info.relative_path} ({mode})...", end=" ")

            try:
                test_result = runner.run_test(info, standard, mode, work_dir)
            except Exception as e:
                test_result = TestResult(
                    test_file=info.relative_path,
                    feature=info.feature,
                    standard=info.standard,
                    category=info.category,
                    test_type=info.test_type,
                    mode=mode,
                    status=TestStatus.FAIL,
                    comment=f"Runner exception: {e}",
                )

            result.results[test_key] = test_result

            if verbose:
                status_char = {
                    TestStatus.PASS: "✓ PASS",
                    TestStatus.PARTIAL: "⚠ PARTIAL",
                    TestStatus.FAIL: "✗ FAIL",
                    TestStatus.UNTESTED: "? UNTESTED",
                    TestStatus.NOT_APPLICABLE: "- N/A",
                }.get(test_result.status, "?")
                print(status_char)

            if stop_on_fail and test_result.status == TestStatus.FAIL:
                print(f"\nStopping: {info.relative_path} FAILED")
                break

    return result


def _normalize_standard(std: str) -> str:
    """Normalize standard strings for comparison: 'VHDL-2008', '2008', 'vhdl2008' → '2008'."""
    return std.lower().replace("vhdl", "").replace("-", "").strip()


def _standard_matches(test_std: str, target_std: str) -> bool:
    """Check if a test's standard matches the target standard."""
    return _normalize_standard(test_std) == _normalize_standard(target_std)
    """Parse a version string into a comparable tuple, e.g. '2024.1' → (2024, 1)."""
    parts = []
    for p in version_str.replace("-", ".").split("."):
        try:
            parts.append(int(p))
        except ValueError:
            parts.append(0)
    return tuple(parts) if parts else (0,)


def main(argv: Optional[List[str]] = None) -> int:
    """Main entry point for the test runner CLI."""
    parser = build_parser()
    args = parser.parse_args(argv)

    tests_dir, tools_dir, results_dir = resolve_paths(args)

    # List modes (no execution)
    if args.list:
        cli_list_tests(tests_dir)
        return 0

    if args.list_tools:
        cli_list_tools(tools_dir)
        return 0

    if args.detect:
        cli_detect_tools(tools_dir, verbose=args.verbose)
        return 0

    # Validate required args
    if not args.tool:
        parser.error("--tool is required (use --list-tools to see available tools)")

    # Load tool config
    tool_config_path = tools_dir / f"{args.tool.lower()}.toml"
    if not tool_config_path.exists():
        sys.exit(
            f"Error: Tool config not found: {tool_config_path}\n"
            f"Available tools: {[p.stem for p in tools_dir.glob('*.toml')]}"
        )

    config = load_tool_config(tool_config_path)

    # Auto-detect tool version if not specified
    version = args.version
    if version == "latest":
        detected_all = detect_installed_versions(tools_dir, verbose=False)
        tool_detected = detected_all.get(args.tool.lower(), [])
        if tool_detected:
            # Pick the highest version found
            best = max(tool_detected, key=lambda d: _parse_version(d.version))
            version = best.version
            if args.verbose:
                print(f"Auto-detected: {config.name} {version} at {best.exe_dir}")
        else:
            print(f"Warning: {config.name} not detected on this system. "
                  f"Run 'vhdl-compat --detect' to scan.")
            print(f"Continuing with version='{version}' (runner will simulate results)")

    # Discover tests
    all_tests = discover_tests(tests_dir)
    if not all_tests:
        print("No tests found. Create .vhd files in tests/ with metadata headers.")
        return 1

    # Determine standards to test
    standards = args.standards or ["2008", "2019"]
    standards = [s.strip() for s in standards]

    # Determine modes
    if args.mode == "both":
        modes = ["sim", "synth"]
    else:
        modes = [args.mode]

    # Setup work directory
    work_dir = Path(args.work_dir) if args.work_dir else Path(tempfile.mkdtemp(prefix="vhdl_compat_"))
    work_dir.mkdir(parents=True, exist_ok=True)

    # Create runner (placeholder — tool-specific adapters to be added)
    runner = GenericRunner(config, version)

    # Run tests for each standard
    for standard in standards:
        std_display = _normalize_standard(standard)
        print(f"\n{'='*60}")
        print(f"Running: {config.name} {version} | VHDL-{std_display} | modes={modes}")
        print(f"{'='*60}")

        result = run_tests(
            runner, all_tests, standard, modes, work_dir,
            verbose=args.verbose or True,
            stop_on_fail=args.stop_on_fail,
        )

        # Print summary
        print(f"\nResults: {result.pass_count} pass, "
              f"{result.partial_count} partial, "
              f"{result.fail_count} fail "
              f"({result.total_count} total)")

        # Save report
        report_subdir = f"{config.name.lower()}-{version}/vhdl{std_display}-{'-'.join(modes)}"
        report_path = results_dir / report_subdir / "report.json"
        result.save_json(report_path)
        print(f"Report saved: {report_path}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
