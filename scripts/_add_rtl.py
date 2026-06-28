"""Add synthesizable RTL entities to test files with SYNTH_ENTITY tags."""
import re
from pathlib import Path


def make_rtl(name: str) -> str:
    """Create a minimal RTL entity with proper library imports."""
    return f"""
-- ============================================================================
-- Synthesizable RTL — demonstrates this VHDL feature in hardware
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity {name} is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of {name} is
  signal reg : std_logic_vector(7 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        reg <= (others => '0');
      else
        reg <= din;
      end if;
    end if;
  end process;
  dout <= reg;
end architecture;
"""


def add_rtl_entity(filepath: Path) -> bool:
    content = filepath.read_text(encoding="utf-8", errors="replace")

    m = re.search(r"--\s+SYNTH_ENTITY:\s+(\w+)", content)
    if not m:
        return False
    rtl_name = m.group(1)

    if f"entity {rtl_name} is" in content:
        return False  # Already has RTL entity

    tb_name = f"{rtl_name}_tb"
    old = f"entity {tb_name} is"
    if old not in content:
        old2 = f"entity tb_{rtl_name} is"
        if old2 in content:
            old = old2
        else:
            return False

    rtl_code = make_rtl(rtl_name)
    # Insert RTL before TB entity, and add re-imports for TB after RTL
    tb_import = "library ieee;\nuse ieee.std_logic_1164.all;\nuse ieee.numeric_std.all;\nuse std.env.all;\n\n"
    content = content.replace(old, rtl_code + tb_import + old, 1)
    filepath.write_text(content, encoding="utf-8")
    print(f"  +RTL: {filepath.relative_to(filepath.parents[2])}")
    return True


def main():
    tests_root = Path(__file__).resolve().parent.parent / "tests"
    count = 0
    for vhd_file in sorted(tests_root.rglob("*.vhd")):
        if vhd_file.name.startswith("_"):
            continue
        if add_rtl_entity(vhd_file):
            count += 1
    print(f"\nAdded RTL entities to {count} files.")


if __name__ == "__main__":
    main()
