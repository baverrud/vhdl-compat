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
class ToolConfig:
    """Complete configuration for one EDA tool."""
    name: str = ""
    vendor: str = ""
    tool_type: str = ""          # "sim", "synth", or "both"
    description: str = ""
    paths: PathConfig = field(default_factory=PathConfig)
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
        try:
            cfg = load_tool_config(toml_file)
            configs[cfg.name.lower()] = cfg
        except Exception as e:
            print(f"Warning: Failed to load {toml_file}: {e}")
    return configs
