"""
Unit tests for the VHDL compatibility test suite.

Run with: python -m pytest scripts/tests/ -v
"""
import sys
from pathlib import Path

# Ensure project root is on path
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))


def test_imports():
    """Verify all core modules can be imported."""
    from scripts.test_discovery import discover_tests, TestInfo
    from scripts.tool_discovery import detect_installed_versions, DetectedTool, ToolConfig
    from scripts.generate_matrix import load_all_results, build_feature_index
    assert True


def test_discover_tests():
    """Verify test discovery finds all 96 tests."""
    from scripts.test_discovery import discover_tests
    tests = discover_tests(PROJECT_ROOT / "tests")
    assert len(tests) == 96, f"Expected 96 tests, found {len(tests)}"


def test_discover_tests_grouped():
    """Verify tests are grouped by standard."""
    from scripts.test_discovery import discover_tests
    tests = discover_tests(PROJECT_ROOT / "tests")
    standards = {}
    for t in tests.values():
        standards.setdefault(t.standard, 0)
        standards[t.standard] += 1
    assert standards["VHDL-2000"] == 2
    assert standards["VHDL-2002"] == 1
    assert standards["VHDL-2008"] == 41
    assert standards["VHDL-2019"] == 52


def test_discover_tests_metadata():
    """Verify test metadata is parsed correctly."""
    from scripts.test_discovery import discover_tests
    tests = discover_tests(PROJECT_ROOT / "tests")
    proc_tests = [t for t in tests.values() if "process_all" in t.relative_path]
    assert len(proc_tests) == 1
    assert proc_tests[0].standard == "VHDL-2008"
    assert proc_tests[0].category == "processes"
    assert "process(all)" in proc_tests[0].feature


def test_load_results():
    """Verify result files can be loaded."""
    from scripts.generate_matrix import load_all_results
    reports = load_all_results(PROJECT_ROOT / "results")
    assert len(reports) >= 4, f"Expected at least 4 reports, found {len(reports)}"


def test_matrix_generation():
    """Verify matrix generation produces output."""
    from scripts.generate_matrix import load_all_results, build_feature_index
    reports = load_all_results(PROJECT_ROOT / "results")
    features = build_feature_index(reports)
    assert len(features) == 96, f"Expected 96 features, found {len(features)}"


def test_matrix_markdown():
    """Verify matrix markdown generation runs without error."""
    from scripts.generate_matrix import load_all_results, build_feature_index, generate_matrix_markdown
    reports = load_all_results(PROJECT_ROOT / "results")
    features = build_feature_index(reports)
    md = generate_matrix_markdown(reports, features)
    assert "VHDL Compatibility Matrix" in md
    assert "✅" in md


def test_tool_discovery():
    """Verify tool discovery from installed.toml."""
    from scripts.tool_discovery import detect_installed_versions
    detected = detect_installed_versions(PROJECT_ROOT / "tools", verbose=False)
    assert "vivado" in detected
    assert len(detected["vivado"]) >= 2


def test_tool_alias():
    """Verify aliases are parsed from installed.toml."""
    from scripts.tool_discovery import detect_installed_versions
    detected = detect_installed_versions(PROJECT_ROOT / "tools", verbose=False)
    for dt in detected.get("vivado", []):
        if dt.version == "2026.1":
            assert dt.alias == "v26"
            break
    else:
        assert False, "Vivado 2026.1 not found in installed.toml"


def test_status_cell():
    """Verify status cell builder."""
    from scripts.generate_matrix import build_status_cell
    assert "✅" in build_status_cell("pass")
    assert "❌" in build_status_cell("fail")
    assert "⬜" in build_status_cell("untested")
    assert "➖" in build_status_cell("n/a")
