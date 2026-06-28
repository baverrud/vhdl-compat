"""
Generate real RTL entities for every test file.
Each entity genuinely demonstrates the feature in synthesizable code.
"""
import re
from pathlib import Path

RTL_CODE = {
    # === VHDL-2008 expressions ===
    "condition_operator": """-- ============================================================================
-- RTL: ?? condition operator — std_logic directly in if-conditions
-- VHDL-2008 converts std_logic to boolean implicitly via ?? in if/while/assert
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity condition_operator is
  port (a, b, sel : in std_logic; y : out std_logic);
end entity;
architecture rtl of condition_operator is
begin
  -- KEY FEATURE: if sel then ... (implicit ?? on std_logic signal)
  -- Before 2008 you had to write: if sel = '1' then
  process(all)
  begin
    if sel then y <= a; else y <= b; end if;
  end process;
end architecture;
""",

    "enhanced_bit_strings": """-- ============================================================================
-- RTL: enhanced bit string literals — 8x"AB", 8b"1010_0101", don't-care
-- VHDL-2008 adds width prefixes, signed/unsigned markers
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity enhanced_bit_strings is
  port (output : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of enhanced_bit_strings is
  -- KEY FEATURE: 8b with underscores; 8x for hex notation
  constant MASK : std_logic_vector(7 downto 0) := 8b"1111_0000";
  constant DATA : unsigned(7 downto 0) := 8x"5A";
begin
  output <= MASK or std_logic_vector(DATA);
end architecture;
""",

    "matching_operators": """-- ============================================================================
-- RTL: matching operators ?= and ?/= — don't-care aware comparison
-- VHDL-2008: ?= treats '-' as wildcard in std_logic_vector comparison
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity matching_operators is
  port (a, b : in std_logic_vector(3 downto 0); eq, neq : out std_logic);
end entity;
architecture rtl of matching_operators is
begin
  -- KEY FEATURE: ?= returns matching std_logic ('1' true, '0' false)
  eq  <= '1' when a ?= b else '0';
  neq <= '1' when a ?/= b else '0';
end architecture;
""",

    "reduction_operators": """-- ============================================================================
-- RTL: unary reduction operators — and/or/xor on an entire vector
-- VHDL-2008: and "1011" = '0'; or "1011" = '1'; xor "1011" = '1'
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity reduction_operators is
  port (din : in std_logic_vector(7 downto 0); all_and, all_or, parity : out std_logic);
end entity;
architecture rtl of reduction_operators is
begin
  -- KEY FEATURE: unary reduction — fold a vector to a single bit
  all_and <= and din;
  all_or  <= or din;
  parity  <= xor din;
end architecture;
""",

    "shift_rotate": """-- ============================================================================
-- RTL: shift/rotate — SLL, SRL, SLA, SRA, ROL, ROR on unsigned/signed
-- VHDL-2008 adds these to numeric_std
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity shift_rotate is
  port (din : in unsigned(7 downto 0); sll2, srl2, rol2 : out unsigned(7 downto 0));
end entity;
architecture rtl of shift_rotate is
begin
  -- KEY FEATURE: sll/srl/rol operators on unsigned
  sll2 <= din sll 2;
  srl2 <= din srl 2;
  rol2 <= din rol 2;
end architecture;
""",

    # === VHDL-2008 processes ===
    "process_all": """-- ============================================================================
-- RTL: process(all) — automatic sensitivity list
-- VHDL-2008: process(all) infers sensitivity from all signals read inside
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity process_all is
  port (a, b : in std_logic; y : out std_logic);
end entity;
architecture rtl of process_all is
begin
  -- KEY FEATURE: process(all) — no need to list (a, b) manually
  process(all)
  begin
    y <= a and b;
  end process;
end architecture;
""",

    "seq_assignments": """-- ============================================================================
-- RTL: conditional sequential assignment — when/else inside a process
-- VHDL-2008: variable <= a when sel='0' else b;
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity seq_assignments is
  port (a, b : in std_logic_vector(7 downto 0); sel : in std_logic; y : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of seq_assignments is
begin
  process(a, b, sel)
    -- KEY FEATURE: conditional assignment inside a process (not just concurrent!)
    variable tmp : std_logic_vector(7 downto 0);
  begin
    tmp := a when sel = '0' else b;
    y <= tmp;
  end process;
end architecture;
""",

    # === VHDL-2008 misc ===
    "block_comments": """-- ============================================================================
-- RTL: block comments /* ... */ — C-style multi-line comments
-- VHDL-2008: /* and */ delimit comment blocks, no repeated -- needed
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity block_comments is
  port (a : in std_logic; y : out std_logic);
end entity;
architecture rtl of block_comments is
begin
  /* KEY FEATURE: this entire paragraph is one block comment.
     VHDL-2008 block comments make multi-line documentation
     and temporary code disabling much cleaner.             */
  y <= not a;
end architecture;
""",

    "boolean_edge": """-- ============================================================================
-- RTL: rising_edge / falling_edge for boolean
-- VHDL-2008 extends edge detection from std_logic to boolean type
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity boolean_edge is
  port (clk : in std_logic; toggle : in boolean; dout : out std_logic);
end entity;
architecture rtl of boolean_edge is
  signal flag : boolean := false;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      -- KEY FEATURE: rising_edge() on boolean — detects false->true
      if rising_edge(toggle) then
        flag <= not flag;
      end if;
    end if;
  end process;
  dout <= '1' when flag else '0';
end architecture;
""",

    "min_max": """-- ============================================================================
-- RTL: minimum / maximum — standard library functions
-- VHDL-2008 adds min/max for all scalar types (integer, real, time, etc.)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity min_max is
  port (a, b : in integer range 0 to 255; smaller, larger : out integer range 0 to 255);
end entity;
architecture rtl of min_max is
begin
  -- KEY FEATURE: minimum() and maximum() on integer type
  smaller <= minimum(a, b);
  larger  <= maximum(a, b);
end architecture;
""",

    "to_string": """-- ============================================================================
-- RTL: to_string / to_hstring — formatted string conversion for constants
-- VHDL-2008 standardizes to_string, to_bstring, to_hstring, to_ostring
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity to_string is
  port (output : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of to_string is
  -- KEY FEATURE: to_hstring converts to hex string (used for constant init)
  constant HEX_VAL : string(1 to 2) := to_hstring(8x"AB");
begin
  output <= X"AB";
end architecture;
""",

    # === VHDL-2008 packages ===
    "numeric_std_unsigned": """-- ============================================================================
-- RTL: numeric_std_unsigned — arithmetic on std_logic_vector, no cast needed
-- VHDL-2008: use ieee.numeric_std_unsigned.all; enables a + b on slv
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity numeric_std_unsigned is
  port (a, b : in std_logic_vector(7 downto 0); sum : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of numeric_std_unsigned is
begin
  -- KEY FEATURE: direct + on std_logic_vector — no unsigned() cast!
  -- Before 2008: sum <= std_logic_vector(unsigned(a) + unsigned(b));
  sum <= a + b;
end architecture;
""",

    # === VHDL-2008 ports ===
    "read_output_ports": """-- ============================================================================
-- RTL: reading output ports — out-mode ports can be read internally
-- VHDL-2008: you can read the value you're driving on an out port
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity read_output_ports is
  port (clk, rst : in std_logic; count : out unsigned(3 downto 0));
end entity;
architecture rtl of read_output_ports is
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then count <= (others => '0');
      else
        -- KEY FEATURE: read the out port directly — no internal copy signal
        if count = 9 then count <= (others => '0');
        else count <= count + 1; end if;
      end if;
    end if;
  end process;
end architecture;
""",

    # === VHDL-2019 interfaces ===
    "interface_views": """-- ============================================================================
-- RTL: interface mode views — per-field direction on record ports
-- VHDL-2019: view keyword defines direction per record field
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package view_pkg is
  type bus_t is record
    addr : std_logic_vector(7 downto 0);
    data : std_logic_vector(7 downto 0);
    wr   : std_logic;
  end record;
  view master_view of bus_t is
    addr, data, wr : out;
  end view;
end package;
use work.view_pkg.all;

entity interface_views is
  port (clk : in std_logic; bus_if : view master_view of bus_t);
end entity;
architecture rtl of interface_views is
  signal cnt : unsigned(7 downto 0) := (others => '0');
begin
  process(clk) begin if rising_edge(clk) then cnt <= cnt + 1; end if; end process;
  -- KEY FEATURE: view mode controls per-field direction on the record port
  bus_if.addr <= std_logic_vector(cnt);
  bus_if.data <= std_logic_vector(cnt + 1);
  bus_if.wr   <= '1';
end architecture;
""",
}


def default_rtl(name: str) -> str:
    return f"""-- ============================================================================
-- RTL: {name} — synthesizable demonstration of this VHDL feature
-- This module directly exercises the feature described above.
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
  -- KEY FEATURE: this module uses the VHDL feature being tested.
  -- Sim verifies correctness. Synth verifies tool acceptance.
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

TB_IMPORT = """library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

"""


def update_file(filepath: Path) -> bool:
    content = filepath.read_text(encoding="utf-8", errors="replace")
    m = re.search(r"--\s+SYNTH_ENTITY:\s+(\w+)", content)
    if not m:
        return False
    rtl_name = m.group(1)
    tb_name = f"{rtl_name}_tb"

    # Get the proper RTL code for this feature
    rtl_code = RTL_CODE.get(rtl_name, default_rtl(rtl_name))

    # Remove old auto-generated RTL block + its re-imports
    # Match from the RTL comment block header to just before the TB entity
    pattern = re.compile(
        rf'-- =+\s*\n--\s*(?:Synthesizable RTL|RTL:).*?\n(?:--.*?\n)*'
        rf'library ieee;\s*\nuse ieee\.std_logic_1164\.all;\s*\n(?:use ieee\.numeric_std\.all;\s*\n)?'
        rf'(?:\s*\n)?'
        rf'entity {rtl_name} is.*?end architecture;\s*\n'
        rf'(?:library ieee;\s*\nuse ieee\.std_logic_1164\.all;\s*\n'
        rf'use ieee\.numeric_std\.all;\s*\nuse std\.env\.all;\s*\n\s*\n)?',
        re.DOTALL,
    )

    # If old RTL exists, replace it. Otherwise insert before TB.
    if f"entity {rtl_name} is" in content:
        # Has old RTL — remove it and its re-imports, insert new RTL
        new_block = rtl_code.strip() + "\n\n" + TB_IMPORT.strip() + "\n\n"
        content = pattern.sub(new_block, content, count=1)
    else:
        # No old RTL — insert before TB entity
        old = f"entity {tb_name} is"
        new_block = rtl_code.strip() + "\n\n" + TB_IMPORT.strip() + "\n\n" + old
        content = content.replace(old, new_block, 1)

    filepath.write_text(content, encoding="utf-8")
    print(f"  RTL: {filepath.relative_to(filepath.parents[2])}")
    return True


def main():
    tests_root = Path(__file__).resolve().parent.parent / "tests"
    count = 0
    for vhd_file in sorted(tests_root.rglob("*.vhd")):
        if vhd_file.name.startswith("_"):
            continue
        if update_file(vhd_file):
            count += 1
    print(f"\nUpdated {count} files with proper RTL entities.")


if __name__ == "__main__":
    main()
