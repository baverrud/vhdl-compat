"""
Tool configuration loader.

Loads TOML files from tools/*.toml and provides a ToolConfig object
with all information needed to invoke a specific EDA tool.

Schema: see docs/tool-config.md
"""

from __future__ import annotations

import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional


if sys.version_info >= (3, 11):
    import tomllib
else:
    try:
        import tomli as tomllib  # type: ignore[no-redef]
    except ImportError:
        tomllib = None  # type: ignore[assignment]


@dataclass
class StandardConfig:
    """Flags for a specific VHDL standard."""
    analysis_flags: List[str] = field(default_factory=list)
    simulation_flags: List[str] = field(default_factory=list)


@dataclass
class SimConfig:
    """Simulation-mode configuration."""
    analysis_cmd: str = ""
    analysis_flags: List[str] = field(default_factory=list)
    analysis_error_pattern: str = ""

    elaboration_cmd: str = ""
    elaboration_flags: List[str] = field(default_factory=list)
    elaboration_error_pattern: str = ""

    run_cmd: str = ""
    run_flags: List[str] = field(default_factory=list)
    run_pass_pattern: str = ""
    run_fail_pattern: str = ""
    run_timeout_seconds: int = 30


@dataclass
class SynthConfig:
    """Synthesis-mode configuration."""
    supported: bool = False
    method: str = ""             # "tcl_batch" or None
    vivado_cmd: str = ""
    batch_flags: List[str] = field(default_factory=list)
    tcl_template: str = ""
    part: str = ""
    synth_error_pattern: str = ""
    synth_pass_pattern: str = ""
    synth_timeout_seconds: int = 120


@dataclass
class PathConfig:
    """Tool path discovery configuration."""
    environment_variable: str = ""
    search_paths: List[str] = field(default_factory=list)
    windows_default: str = ""
    linux_default: str = ""


@dataclass
class DetectionConfig:
    """Version detection configuration."""
    version_cmd: str = ""
    version_args: List[str] = field(default_factory=list)
    version_pattern: str = ""
    search_paths: List[str] = field(default_factory=list)
    exe_subdir: str = ""


@dataclass
class ToolConfig:
    """Complete configuration for one EDA tool."""
    name: str = ""
    vendor: str = ""
    tool_type: str = ""          # "sim", "synth", or "both"
    description: str = ""
    display_name: str = ""       # custom display name from installed.toml
    paths: PathConfig = field(default_factory=PathConfig)
    detection: DetectionConfig = field(default_factory=DetectionConfig)
    standards: Dict[str, StandardConfig] = field(default_factory=dict)
    sim: SimConfig = field(default_factory=SimConfig)
    synth: SynthConfig = field(default_factory=SynthConfig)

    def get_executable_dir(self) -> Optional[Path]:
        """Find the tool's executable directory.

        Priority:
        1. Environment variable
        2. Search common paths
        3. Platform default
        """
        import os
        import platform

        # 1. Environment variable
        if self.paths.environment_variable:
            env_val = os.environ.get(self.paths.environment_variable)
            if env_val:
                p = Path(env_val)
                if p.exists():
                    return p

        # 2. Search paths
        import glob
        for search in self.paths.search_paths:
            for found in glob.glob(search):
                p = Path(found)
                if p.exists():
                    return p

        # 3. Platform default
        if platform.system() == "Windows":
            default = self.paths.windows_default
        else:
            default = self.paths.linux_default

        if default:
            p = Path(default)
            if p.exists():
                return p

        return None

    def get_standard_config(self, standard: str) -> StandardConfig:
        """Get the standard-specific flags for a VHDL standard."""
        key = standard.lower().replace("-", "")
        return self.standards.get(key, StandardConfig())


def load_tool_config(config_path: Path) -> ToolConfig:
    """Load a tool configuration from a TOML file."""
    if tomllib is None:
        raise ImportError(
            "tomllib (Python 3.11+) or tomli is required to read TOML configs. "
            "Install with: pip install tomli"
        )

    raw = tomllib.loads(config_path.read_text(encoding="utf-8"))

    cfg = ToolConfig()

    # [tool]
    tool_section = raw.get("tool", {})
    cfg.name = tool_section.get("name", "")
    cfg.vendor = tool_section.get("vendor", "")
    cfg.tool_type = tool_section.get("type", "sim")
    cfg.description = tool_section.get("description", "")

    # [paths]
    paths_section = raw.get("paths", {})
    cfg.paths = PathConfig(
        environment_variable=paths_section.get("environment_variable", ""),
        search_paths=paths_section.get("search_paths", []),
        windows_default=paths_section.get("windows_default", ""),
        linux_default=paths_section.get("linux_default", ""),
    )

    # [detection]
    det_section = raw.get("detection", {})
    det_search = det_section.get("search", {})
    cfg.detection = DetectionConfig(
        version_cmd=det_section.get("version_cmd", ""),
        version_args=det_section.get("version_args", []),
        version_pattern=det_section.get("version_pattern", ""),
        search_paths=det_search.get("paths", []),
        exe_subdir=det_search.get("exe_subdir", ""),
    )

    # [standards.*]
    standards_section = raw.get("standards", {})
    for std_key, std_val in standards_section.items():
        cfg.standards[std_key] = StandardConfig(
            analysis_flags=std_val.get("analysis_flags", []),
            simulation_flags=std_val.get("simulation_flags", []),
        )

    # [sim]
    sim_section = raw.get("sim", {})
    cfg.sim = SimConfig(
        analysis_cmd=sim_section.get("analysis_cmd", ""),
        analysis_flags=sim_section.get("analysis_flags", []),
        analysis_error_pattern=sim_section.get("analysis_error_pattern", ""),
        elaboration_cmd=sim_section.get("elaboration_cmd", ""),
        elaboration_flags=sim_section.get("elaboration_flags", []),
        elaboration_error_pattern=sim_section.get("elaboration_error_pattern", ""),
        run_cmd=sim_section.get("run_cmd", ""),
        run_flags=sim_section.get("run_flags", []),
        run_pass_pattern=sim_section.get("run_pass_pattern", "PASS:"),
        run_fail_pattern=sim_section.get("run_fail_pattern", "FAIL:"),
        run_timeout_seconds=sim_section.get("run_timeout_seconds", 30),
    )

    # [synth]
    synth_section = raw.get("synth", {})
    cfg.synth = SynthConfig(
        supported=synth_section.get("supported", True),
        method=synth_section.get("method", ""),
        vivado_cmd=synth_section.get("vivado_cmd", ""),
        batch_flags=synth_section.get("batch_flags", []),
        tcl_template=synth_section.get("tcl_template", ""),
        part=synth_section.get("part", ""),
        synth_error_pattern=synth_section.get("synth_error_pattern", ""),
        synth_pass_pattern=synth_section.get("synth_pass_pattern", ""),
        synth_timeout_seconds=synth_section.get("synth_timeout_seconds", 120),
    )

    return cfg


def discover_tool_configs(tools_dir: Path) -> Dict[str, ToolConfig]:
    """Load all tool configurations from a directory."""
    configs: Dict[str, ToolConfig] = {}
    for toml_file in sorted(tools_dir.glob("*.toml")):
        # Skip manual installation config — it's not a tool definition
        if toml_file.name in ("installed.toml", "installed.example.toml"):
            continue
        try:
            cfg = load_tool_config(toml_file)
            configs[cfg.name.lower()] = cfg
        except Exception as e:
            print(f"Warning: Failed to load {toml_file}: {e}")
    return configs


# ---------------------------------------------------------------------------
# Tool version detection
# ---------------------------------------------------------------------------

@dataclass
class DetectedTool:
    """A detected installation of an EDA tool."""
    tool_name: str
    version: str
    exe_dir: Path
    exe_path: Path
    display_name: str = ""   # custom display name from installed.toml section


# ---------------------------------------------------------------------------
# Alias map: custom installed.toml section names → canonical tool config keys
# ---------------------------------------------------------------------------
TOOL_ALIASES: dict[str, str] = {
    "altera questa starter": "questa",
    "altera questastarter": "questa",
    "intel/altera modelsim starter": "modelsim",
    "modelsim starter": "modelsim",
    "modelsim de": "modelsim",
    "modelsim pe": "modelsim",
    "vivado": "vivado",
    "xilinx vivado": "vivado",
}


def detect_installed_versions(
    tools_dir: Path,
    verbose: bool = False,
) -> Dict[str, List[DetectedTool]]:
    """Discover installed EDA tool versions.

    Priority:
    1. Manual config: tools/installed.toml (user-controlled, no filesystem scan)
    2. Auto-detection: scan filesystem using [detection.search] paths

    Returns dict mapping tool_name → list of detected versions.
    """
    detected: Dict[str, List[DetectedTool]] = {}

    # 1. Check manual config first
    manual_path = tools_dir / "installed.toml"
    if manual_path.exists():
        if verbose:
            print(f"Reading manual tool config: {manual_path}")
        manual_detected = _load_manual_installations(manual_path, tools_dir)
        for tool_key, versions in manual_detected.items():
            detected.setdefault(tool_key, []).extend(versions)
        if detected and verbose:
            print(f"  Found {sum(len(v) for v in detected.values())} manually configured installation(s).")
        if detected:
            return detected  # Manual config takes priority — skip auto-scan

    # 2. Fall back to auto-detection
    if verbose:
        print("No manual config found — scanning filesystem...")
        print("  (Create tools/installed.toml to avoid filesystem scans)")

    return _detect_by_scanning(tools_dir, verbose)


def _load_manual_installations(
    manual_path: Path,
    tools_dir: Path,
) -> Dict[str, List[DetectedTool]]:
    """Parse tools/installed.toml and return detected installations."""
    if tomllib is None:
        print("Warning: tomli not available, cannot read installed.toml")
        return {}

    configs = discover_tool_configs(tools_dir)

    try:
        raw = tomllib.loads(manual_path.read_text(encoding="utf-8"))
    except Exception as e:
        error_msg = str(e)
        if "unescaped" in error_msg.lower() or "backslash" in error_msg.lower():
            # Windows users often use backslashes in paths — auto-convert them
            text = manual_path.read_text(encoding="utf-8")
            text = text.replace("\\", "/")
            try:
                raw = tomllib.loads(text)
            except Exception as e2:
                print(f"Error in {manual_path.name}: {e2}")
                print(f"  TOML requires forward slashes in paths — even on Windows.")
                print(f'  Correct: path = "C:/Xilinx/Vivado/2024.1/bin"')
                return {}
        else:
            print(f"Warning: Failed to parse {manual_path}: {e}")
            return {}

    detected: Dict[str, List[DetectedTool]] = {}

    for tool_key, versions_data in raw.items():
        if not isinstance(versions_data, dict):
            continue

        tool_key_lower = tool_key.lower()
        alias_target = TOOL_ALIASES.get(tool_key_lower, tool_key_lower)
        tool_cfg = configs.get(alias_target)

        # Use the installed.toml section key as the display name
        display_name = tool_key.strip()
        tool_name = tool_cfg.name if tool_cfg else tool_key

        for version, data in versions_data.items():
            if not isinstance(data, dict):
                continue
            exe_dir_str = data.get("path", "")
            if not exe_dir_str:
                continue

            exe_dir = Path(exe_dir_str)
            if not exe_dir.is_dir():
                if alias_target in configs:
                    print(f"  Warning: {tool_name} {version} — path not found: {exe_dir}")
                continue

            # Verify the expected executable exists
            if tool_cfg and tool_cfg.detection.version_cmd:
                import platform
                exe_name = tool_cfg.detection.version_cmd
                if platform.system() == "Windows":
                    exe_name += ".exe"
                exe_path = exe_dir / exe_name
                if not exe_path.exists():
                    # Try without .exe
                    exe_path = exe_dir / tool_cfg.detection.version_cmd
                    if not exe_path.exists():
                        print(f"  Warning: {tool_name} {version} — {exe_name} not found in {exe_dir}")
                        continue

            # Key the detection by CANONICAL name so --tool questa finds it
            detected.setdefault(alias_target, []).append(
                DetectedTool(
                    tool_name=tool_name,
                    version=version,
                    exe_dir=exe_dir,
                    exe_path=exe_path if 'exe_path' in dir() else exe_dir,
                    display_name=display_name,
                )
            )

    return detected


def _detect_by_scanning(
    tools_dir: Path,
    verbose: bool,
) -> Dict[str, List[DetectedTool]]:
    import glob as glob_mod
    import platform
    import re
    import subprocess

    configs = discover_tool_configs(tools_dir)
    detected: Dict[str, List[DetectedTool]] = {}

    for tool_key, cfg in configs.items():
        if not cfg.detection.search_paths:
            if verbose:
                print(f"  {cfg.name}: no search paths configured, skipping scan")
            continue

        found_versions: Dict[str, Path] = {}  # version → exe_dir (deduplicate)

        for search_pattern in cfg.detection.search_paths:
            for found_path_str in glob_mod.glob(search_pattern):
                found_path = Path(found_path_str)
                if not found_path.is_dir():
                    continue

                exe_dir = found_path
                if cfg.detection.exe_subdir:
                    candidate = found_path / cfg.detection.exe_subdir
                    if candidate.is_dir():
                        exe_dir = candidate

                exe_name = cfg.detection.version_cmd
                if platform.system() == "Windows":
                    exe_name += ".exe"
                exe_path = exe_dir / exe_name

                if not exe_path.exists():
                    # Try without .exe on Windows
                    if platform.system() == "Windows":
                        exe_path = exe_dir / cfg.detection.version_cmd
                    if not exe_path.exists():
                        if verbose:
                            print(f"  {cfg.name}: exe not found at {exe_path}")
                        continue

                # Try to get version
                version_str = _query_tool_version(
                    exe_path,
                    cfg.detection.version_args,
                    cfg.detection.version_pattern,
                    verbose,
                )

                if version_str and version_str not in found_versions:
                    detected.setdefault(tool_key, []).append(
                        DetectedTool(
                            tool_name=cfg.name,
                            version=version_str,
                            exe_dir=exe_dir,
                            exe_path=exe_path,
                        )
                    )
                    found_versions[version_str] = exe_dir
                    if verbose:
                        print(f"  {cfg.name} {version_str} at {exe_dir}")

        if cfg.name.lower() not in detected and verbose:
            print(f"  {cfg.name}: not found")

    return detected


def _query_tool_version(
    exe_path: Path,
    version_args: List[str],
    version_pattern: str,
    verbose: bool = False,
) -> str:
    """Run the version command and extract the version string."""
    import re
    import subprocess

    try:
        result = subprocess.run(
            [str(exe_path)] + version_args,
            capture_output=True,
            text=True,
            timeout=10,
        )
        output = result.stdout + result.stderr
        m = re.search(version_pattern, output, re.IGNORECASE)
        if m:
            return m.group(1)
        if verbose:
            print(f"    version pattern not matched in output: {output[:120]}")
    except FileNotFoundError:
        if verbose:
            print(f"    executable not found: {exe_path}")
    except subprocess.TimeoutExpired:
        if verbose:
            print(f"    timeout querying version: {exe_path}")
    except Exception as e:
        if verbose:
            print(f"    error querying version: {e}")

    return ""
