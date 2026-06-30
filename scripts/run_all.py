"""
run_all.py — Run the full VHDL compatibility test suite across all tools.

Detects all installed tools/versions from installed.toml, runs sim + synth
for all standards, and generates MATRIX.md.

Usage:
    python scripts/run_all.py                  # full run
    python scripts/run_all.py --skip-synth      # skip Vivado synthesis (~45 min)
    python scripts/run_all.py --tool vivado     # only Vivado
"""
from __future__ import annotations

import sys
import time
from pathlib import Path
from datetime import datetime, timezone

# Ensure project root is on path
PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from scripts.tool_discovery import detect_installed_versions
from scripts.run_tests import main as run_tests_main


def run_tool(tool: str, version: str, standards: list[str], modes: list[str]) -> bool:
    """Run tests for one tool/version. Returns True on success."""
    argv = [
        "--tool", tool,
        "--version", version,
        *[s for std in standards for s in ("--std", std)],
        "--mode", "+".join(modes),
        "--verbose",
    ]
    print(f"  {tool} {version} {','.join(standards)} {'+'.join(modes)}...", end=" ", flush=True)
    start = time.time()
    try:
        rc = run_tests_main(argv)
        elapsed = time.time() - start
        print(f"done ({elapsed:.0f}s)" if rc == 0 else f"WARN (rc={rc}, {elapsed:.0f}s)")
        return rc == 0
    except Exception as e:
        elapsed = time.time() - start
        print(f"ERROR ({elapsed:.0f}s): {e}")
        return False


def main():
    skip_synth = "--skip-synth" in sys.argv
    tool_filter = None
    version_filter = None
    for i, a in enumerate(sys.argv):
        if a == "--tool" and i + 1 < len(sys.argv):
            tool_filter = sys.argv[i + 1]
        if a == "--version" and i + 1 < len(sys.argv):
            version_filter = sys.argv[i + 1]

    print("=" * 60)
    print(f"VHDL Compatibility Test Suite — Full Run")
    print(f"Started: {datetime.now(timezone.utc).isoformat()}")
    print(f"Skip synth: {skip_synth}")
    print(f"Tool filter: {tool_filter or 'all'}")
    print(f"Version filter: {version_filter or 'all'}")
    print("=" * 60)
    print()

    # Map internal names to CLI tool names
    TOOL_CLI = {
        "questa": "questa",
        "modelsim": "modelsim",
        "vivado": "vivado",
    }

    # Discover all installed tools
    detected = detect_installed_versions(PROJECT_ROOT / "tools", verbose=False)

    # Run each tool
    for canonical_key, versions in sorted(detected.items()):
        cli_name = TOOL_CLI.get(canonical_key)
        if not cli_name:
            print(f"  Skipping unknown tool: {canonical_key}")
            continue
        if tool_filter and cli_name != tool_filter:
            continue

        for dt in sorted(versions, key=lambda d: d.version, reverse=True):
            version = dt.version
            # Respect alias and version filter
            if version_filter:
                if version_filter != version and version_filter.lower() != dt.alias.lower():
                    continue
            print(f"\n--- {dt.display_name or canonical_key} {version} ---")

            if cli_name == "vivado" and not skip_synth:
                # Vivado: run sim+synth in one invocation (faster than two runs)
                run_tool(cli_name, version, ["2000", "2002", "2008", "2019"], ["sim", "synth"])
            else:
                # Sim-only tools or when synth is skipped
                run_tool(cli_name, version, ["2000", "2002", "2008", "2019"], ["sim"])

    # Generate matrix
    print(f"\n--- Generating MATRIX.md ---")
    try:
        from scripts.generate_matrix import main as gen_main
        gen_main()
    except Exception as e:
        print(f"  ERROR: Matrix generation failed: {e}")

    print(f"\n{'=' * 60}")
    print("Complete!")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
