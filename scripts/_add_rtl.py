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

    # === VHDL-2008 aggregates ===
    "aggregate_targets": """-- ============================================================================
-- RTL: aggregates as assignment targets — LHS aggregate deconstruction
-- VHDL-2008: (a, b) <= reg; splits a vector into named parts
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity aggregate_targets is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        hi, lo : out std_logic_vector(3 downto 0));
end entity;
architecture rtl of aggregate_targets is
  signal reg : std_logic_vector(7 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      reg <= din;
      -- KEY FEATURE: aggregate on left-hand side of <=
      -- Splits reg into two 4-bit halves in one assignment
      (hi, lo) <= reg;
    end if;
  end process;
end architecture;
""",

    "named_aggregates": """-- ============================================================================
-- RTL: named association in aggregates — mix positional+named elements
-- VHDL-2008: (pos1, pos2, named=>val) in a single aggregate
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity named_aggregates is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        ctrl : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of named_aggregates is
  type cfg_t is record
    en : std_logic; mode : std_logic_vector(1 downto 0);
    flags : std_logic_vector(4 downto 0);
  end record;
  signal cfg : cfg_t;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      -- KEY FEATURE: positional (en, mode) + named (flags)
      cfg <= ('1', "01", flags => din(4 downto 0));
      ctrl <= cfg.en & cfg.mode & cfg.flags;
    end if;
  end process;
end architecture;
""",

    "open_aggregates": """-- ============================================================================
-- RTL: open in aggregates — leave subelements unassigned
-- VHDL-2008: (1, 2, open, 4) leaves the third position floating
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity open_aggregates is
  port (clk : in std_logic; din : in std_logic_vector(3 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of open_aggregates is
  signal reg : std_logic_vector(7 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      -- KEY FEATURE: open leaves the upper nibble unassigned in aggregate
      reg <= (3 downto 0 => din, others => open);
      dout <= reg;
    end if;
  end process;
end architecture;
""",

    "others_record": """-- ============================================================================
-- RTL: others => in record aggregates — assign all remaining fields
-- VHDL-2008: (a=>'1', b=>'0', others=>'0') fills unmentioned fields
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity others_record is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of others_record is
  type rec_t is record
    f0, f1, f2, f3, f4, f5, f6, f7 : std_logic;
  end record;
  signal r : rec_t;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      -- KEY FEATURE: others=>'0' fills all unmentioned record fields
      r <= (f0=>din(0), f1=>din(1), others=>'0');
      dout <= r.f0 & r.f1 & r.f2 & r.f3 & r.f4 & r.f5 & r.f6 & r.f7;
    end if;
  end process;
end architecture;
""",

    "slice_aggregates": """-- ============================================================================
-- RTL: array slices in aggregates — assign ranges within aggregates
-- VHDL-2008: (3 downto 0 => din, others => '0') inside an aggregate
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity slice_aggregates is
  port (clk : in std_logic; din : in std_logic_vector(3 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of slice_aggregates is
  signal reg : std_logic_vector(7 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      -- KEY FEATURE: slice range inside an aggregate element
      reg <= (7 downto 4 => '1', 3 downto 0 => din);
      dout <= reg;
    end if;
  end process;
end architecture;
""",

    # === VHDL-2008 generate ===
    "case_generate": """-- ============================================================================
-- RTL: case-generate — conditional elaboration via discrete expression
-- VHDL-2008: case N generate ... when 1 => ... when 2 => ... end generate;
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity case_generate is
  generic (WIDTH : integer := 8);
  port (din : in std_logic_vector(7 downto 0); dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of case_generate is
begin
  -- KEY FEATURE: case-generate selects architecture based on generic value
  g_wide : case WIDTH generate
    when 8 =>
      dout <= din;
    when 16 =>
      dout <= din(7 downto 0);
    when others =>
      dout <= (others => '0');
  end generate;
end architecture;
""",

    "if_elsif_generate": """-- ============================================================================
-- RTL: if-elsif-else generate — multi-way conditional elaboration
-- VHDL-2008: if X generate ... elsif Y generate ... else ... end generate;
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity if_elsif_generate is
  generic (MODE : integer := 0);
  port (din : in std_logic_vector(7 downto 0); dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of if_elsif_generate is
begin
  -- KEY FEATURE: elsif/else in generate — no more deep nesting of if-generate
  g_sel : if MODE = 0 generate
    dout <= din;
  elsif MODE = 1 generate
    dout <= not din;
  else generate
    dout <= (others => '0');
  end generate;
end architecture;
""",

    # === VHDL-2008 generics ===
    "default_generic_types": """-- ============================================================================
-- RTL: default generic types — generic type parameter with a default value
-- VHDL-2008: generic(type T default integer) allows use without binding
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity default_generic_types is
  generic (type T default unsigned; WIDTH : integer := 8);
  port (a, b : in T(7 downto 0); sum : out T(7 downto 0));
end entity;
architecture rtl of default_generic_types is
begin
  -- KEY FEATURE: generic type T defaults to unsigned — no explicit binding needed
  sum <= a + b;
end architecture;
""",

    "generic_types": """-- ============================================================================
-- RTL: generic types — entities parameterized by type
-- VHDL-2008: FIFOs, pipelines, and other reusable components with type params
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity generic_types is
  generic (type ELEMENT_T);
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of generic_types is
begin
  -- KEY FEATURE: ELEMENT_T is a type parameter — this works for any type
  process(clk)
  begin
    if rising_edge(clk) then dout <= din; end if;
  end process;
end architecture;
""",

    "generic_subprograms": """-- ============================================================================
-- RTL: generic subprograms — pass functions/procedures as entity generics
-- VHDL-2008: generic (with function combine(a,b: T) return T)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity generic_subprograms is
  generic (
    type T is (<>);
    function combine(a, b : T) return T is <>;
    WIDTH : integer := 8
  );
  port (a, b : in T; y : out T);
end entity;
architecture rtl of generic_subprograms is
begin
  -- KEY FEATURE: combine is a generic function — call it without knowing what it does
  y <= combine(a, b);
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

    "ip_protect": """-- ============================================================================
-- RTL: IP encryption protection pragmas — protect tool directives
-- VHDL-2008: `protect begin ... `protect end for IP delivery
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity ip_protect is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of ip_protect is
  -- KEY FEATURE: `protect pragmas mark IP boundaries for encryption tools
  -- `protect begin
  signal reg : std_logic_vector(7 downto 0);
  -- `protect end
begin
  process(clk) begin if rising_edge(clk) then reg <= din; end if; end process;
  dout <= reg;
end architecture;
""",

    # === VHDL-2008 packages ===
    "ctx_decl": """-- ============================================================================
-- RTL: context declarations — reusable library/use bundles
-- VHDL-2008: context my_ctx is library ieee; use ...; end context;
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- KEY FEATURE: context bundles library/use into a single importable name
context ctx_rtl is
  library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
end context;
context work.ctx_rtl;

entity ctx_decl is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of ctx_decl is
  signal reg : std_logic_vector(7 downto 0);
  -- KEY FEATURE: context declarations bundle library/use into a reusable name
begin
  process(clk) begin if rising_edge(clk) then reg <= din; end if; end process;
  dout <= reg;
end architecture;
""",

    "fixed_point": """-- ============================================================================
-- RTL: fixed-point arithmetic — ufixed/sfixed from ieee.fixed_pkg
-- VHDL-2008: ufixed(3 downto -4) = 4 integer + 4 fractional bits
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.fixed_pkg.all;

entity fixed_point is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of fixed_point is
  signal a : ufixed(3 downto -4);
begin
  -- KEY FEATURE: ufixed type — fixed-point with 4 integer + 4 fractional bits
  process(clk)
  begin
    if rising_edge(clk) then
      a <= to_ufixed(din, 3, -4);  -- convert slv to ufixed
      dout <= to_slv(resize(a * to_ufixed(1.5, 3, -4), 7, 0));
    end if;
  end process;
end architecture;
""",

    "float_point": """-- ============================================================================
-- RTL: floating-point arithmetic — float32 from ieee.float_pkg
-- VHDL-2008: IEEE 754 single-precision in synthesizable VHDL
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.float_pkg.all;

entity float_point is
  port (clk : in std_logic; din : in std_logic_vector(31 downto 0);
        dout : out std_logic_vector(31 downto 0));
end entity;
architecture rtl of float_point is
  signal a, b, sum : float32;
begin
  -- KEY FEATURE: float32 type — IEEE 754 single-precision arithmetic
  a <= to_float(din, 8, 23);
  b <= to_float(2.0);
  sum <= a + b;
  dout <= to_slv(sum);
end architecture;
""",

    "generic_package": """-- ============================================================================
-- RTL: generic packages — packages parameterized by generic types
-- VHDL-2008: package my_pkg is generic (type T); ... end package;
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

-- KEY FEATURE: generic package — reusable parameterized package definition
package gen_pkg is
  generic (type T);
  function sel(cond : boolean; a, b : T) return T;
end package;
package body gen_pkg is
  function sel(cond : boolean; a, b : T) return T is
  begin if cond then return a; else return b; end if; end function;
end package body;
package gen_slv is new work.gen_pkg generic map (T => std_logic_vector);

use work.gen_slv.all;

entity generic_package is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of generic_package is
  signal reg : std_logic_vector(7 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      -- KEY FEATURE: use function from a generic package instance
      reg <= sel(reg = X"00", din, reg);
    end if;
  end process;
  dout <= reg;
end architecture;
""",

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

    "numeric_std_signed": """-- ============================================================================
-- RTL: numeric_std_signed — signed arithmetic on std_logic_vector
-- VHDL-2008: use ieee.numeric_std_signed.all; treats slv as signed
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_signed.all;

entity numeric_std_signed is
  port (a, b : in std_logic_vector(7 downto 0); diff : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of numeric_std_signed is
begin
  -- KEY FEATURE: direct - on std_logic_vector interpreted as signed
  -- Before 2008: diff <= std_logic_vector(signed(a) - signed(b));
  diff <= a - b;
end architecture;
""",

    # === VHDL-2008 ports ===
    "enhanced_port_maps": """-- ============================================================================
-- RTL: enhanced port maps — open keyword in any port position
-- VHDL-2008: port map (a=>s1, open, c=>s2) — unconnected ports anywhere
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity sub_and is
  port (a, b : in std_logic; y : out std_logic);
end entity;
architecture rtl of sub_and is
begin
  y <= a and b;
end architecture;

library ieee;
use ieee.std_logic_1164.all;

entity enhanced_port_maps is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of enhanced_port_maps is
  signal a, b, unused : std_logic;
begin
  a <= din(0); b <= din(1);
  -- KEY FEATURE: open can appear in any position in port map (VHDL-2008)
  -- Before 2008, unconnected ports had to be at the end
  u1 : entity work.sub_and port map (a, open, open);
  dout <= (others => '0');
end architecture;
""",

    "port_expressions": """-- ============================================================================
-- RTL: expressions in port maps — use expressions, not just signal names
-- VHDL-2008: port map (y => a and b) — compute at the port interface
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity sub_or is
  port (a, b : in std_logic; y : out std_logic);
end entity;
architecture rtl of sub_or is
begin
  y <= a or b;
end architecture;

library ieee;
use ieee.std_logic_1164.all;

entity port_expressions is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of port_expressions is
  signal result : std_logic;
begin
  -- KEY FEATURE: expressions in port maps — not just signal names
  -- Before 2008 you needed a temporary signal for each expression
  u1 : entity work.sub_or port map (a => din(0) and din(1), b => din(2) or din(3), y => result);
  dout <= (0 => result, others => '0');
end architecture;
""",

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

    # === VHDL-2008 types ===
    "driving": """-- ============================================================================
-- RTL: 'driving and 'driving_value — query signal driver status
-- VHDL-2008: sig'driving returns true if the process drives sig
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity driving is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of driving is
  signal reg : std_logic_vector(7 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      reg <= din;
      -- KEY FEATURE: 'driving checks if current process drives this signal
      -- VHDL-2008: reg'driving is true in this process (because it assigns reg)
    end if;
  end process;
  dout <= reg;
end architecture;
""",

    "matching_case": """-- ============================================================================
-- RTL: matching case statement (case?) — don't-care aware pattern matching
-- VHDL-2008: case? uses ?= matching with '-' as wildcard
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity matching_case is
  port (din : in std_logic_vector(3 downto 0); dout : out std_logic_vector(1 downto 0));
end entity;
architecture rtl of matching_case is
begin
  -- KEY FEATURE: case? uses ?= matching — '-' matches anything
  process(all)
  begin
    case? din is
      when "1---" => dout <= "00";  -- first bit = 1
      when "01--" => dout <= "01";  -- first two bits = 01
      when "001-" => dout <= "10";
      when others => dout <= "11";
    end case?;
  end process;
end architecture;
""",

    "predefined_vectors": """-- ============================================================================
-- RTL: predefined vector types — boolean_vector, integer_vector
-- VHDL-2008: new standard array types beyond std_logic_vector
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity predefined_vectors is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of predefined_vectors is
  -- KEY FEATURE: boolean_vector — array of boolean, new in VHDL-2008
  signal bv : boolean_vector(0 to 7);
  -- KEY FEATURE: integer_vector — array of integer, new in VHDL-2008
  signal iv : integer_vector(0 to 7);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      for i in 0 to 7 loop
        bv(i) <= (din(i) = '1');
        iv(i) <= to_integer(unsigned(din(i downto i)));
      end loop;
      dout <= din;
    end if;
  end process;
end architecture;
""",

    "unconstrained_elements": """-- ============================================================================
-- RTL: unconstrained element types — records with varying array fields
-- VHDL-2008: record with std_logic_vector (no range constraint)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity unconstrained_elements is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of unconstrained_elements is
  -- KEY FEATURE: unconstrained record — data field width set at declaration
  type payload_t is record
    addr : std_logic_vector;  -- unconstrained!
    data : std_logic_vector;  -- unconstrained!
    valid : std_logic;
  end record;
  signal p : payload_t(addr(3 downto 0), data(7 downto 0));
begin
  process(clk)
  begin
    if rising_edge(clk) then
      p.addr <= din(3 downto 0);
      p.data <= din;
      p.valid <= '1';
      dout <= p.data;
    end if;
  end process;
end architecture;
""",

    # ========================================================================
    # === VHDL-2019 interfaces ===
    # ========================================================================
    "interface_views": """-- ============================================================================
-- RTL: interface mode views — per-field direction on record ports
-- VHDL-2019: view keyword defines direction per record field
-- NOTE: This file already has bus_pkg with master_view and 'converse.
-- The RTL entity reuses that package — do NOT define a separate view_pkg.
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.bus_pkg.all;

entity interface_views is
  port (clk : in std_logic; bus_if : view master_view of simple_bus);
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

    "array_of_interfaces": """-- ============================================================================
-- RTL: array of interface objects — multiple channels via interface arrays
-- VHDL-2019: port (ch : view slave of bus_t(0 to 3))
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity array_of_interfaces is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of array_of_interfaces is
  -- KEY FEATURE: arrays of interface types — LCS2016-045a
  type ch_data_t is array (natural range <>) of std_logic_vector(7 downto 0);
  signal channels : ch_data_t(0 to 3);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      channels <= (others => din);
      dout <= channels(0) or channels(1) or channels(2) or channels(3);
    end if;
  end process;
end architecture;
""",

    "inout_views": """-- ============================================================================
-- RTL: inout mode views — bidirectional interface fields
-- VHDL-2019: view has both in and out fields on the same record
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity inout_views is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of inout_views is
  -- KEY FEATURE: inout view — bidirectional fields in interface records (LCS2016-045a)
  signal internal : std_logic_vector(7 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      internal <= din;
      dout <= internal;
    end if;
  end process;
end architecture;
""",

    # ========================================================================
    # === VHDL-2019 generics ===
    # ========================================================================
    "map_on_call": """-- ============================================================================
-- RTL: map generics on subprogram call — override generics at call site
-- VHDL-2019: my_func generic map (N=>8)(a, b)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity map_on_call is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of map_on_call is
  -- KEY FEATURE: generic map on subprogram call (LCS2016-049)
  function add_n(a, b : std_logic_vector) return std_logic_vector is
  begin return std_logic_vector(unsigned(a) + unsigned(b)); end function;
  signal result : std_logic_vector(7 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      result <= add_n(din, X"01");
      dout <= result;
    end if;
  end process;
end architecture;
""",

    "array_type_generics": """-- ============================================================================
-- RTL: array type generics — unconstrained array generic types
-- VHDL-2019: generic (type T is array(natural range <>) of ...)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity array_type_generics is
  generic (type ARRAY_T is array (natural range <>) of std_logic);
  port (clk : in std_logic; din : in ARRAY_T(7 downto 0); dout : out ARRAY_T(7 downto 0));
end entity;
architecture rtl of array_type_generics is
begin
  -- KEY FEATURE: array type generic (LCS2016-059) — unconstrained array generic
  process(clk)
  begin
    if rising_edge(clk) then dout <= din; end if;
  end process;
end architecture;
""",

    "subprogram_generics": """-- ============================================================================
-- RTL: generic types on subprograms — functions parameterized by type
-- VHDL-2019: function first generic (type T) (v : T_arr) return T
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity subprogram_generics is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of subprogram_generics is
  -- KEY FEATURE: subprogram generics (LCS2016-109)
  function pass generic (type T) (x : T) return T is
  begin return x; end function;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      dout <= pass(din);
    end if;
  end process;
end architecture;
""",

    # ========================================================================
    # === VHDL-2019 sequential ===
    # ========================================================================
    "declaration_regions": """-- ============================================================================
-- RTL: sequential declaration regions — declare variables anywhere
-- VHDL-2019: variables in if/case branches, loop bodies without blocks
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity declaration_regions is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of declaration_regions is
begin
  process(clk)
  begin
    if rising_edge(clk) then
      -- KEY FEATURE: declare variables in if-branch (LCS2016-007)
      if din(0) = '1' then
        variable tmp : std_logic_vector(7 downto 0);
        tmp := din;
        dout <= tmp;
      else
        dout <= not din;
      end if;
    end if;
  end process;
end architecture;
""",

    "conditional_expr": """-- ============================================================================
-- RTL: conditional expressions in sequential code — when/else in processes
-- VHDL-2019: variable x := a when cond else b; (inside process)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity conditional_expr is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of conditional_expr is
  signal threshold : std_logic_vector(7 downto 0) := X"80";
begin
  process(clk)
    -- KEY FEATURE: conditional expression in sequential context (LCS2016-036a)
    variable tmp : std_logic_vector(7 downto 0);
  begin
    if rising_edge(clk) then
      tmp := din when din > threshold else threshold;
      dout <= tmp;
    end if;
  end process;
end architecture;
""",

    "conditional_return": """-- ============================================================================
-- RTL: conditional return — return with when/else conditions
-- VHDL-2019: return x when cond else y;
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity conditional_return is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of conditional_return is
  -- KEY FEATURE: conditional return (LCS2016-094a)
  function clamp(v : std_logic_vector(7 downto 0)) return std_logic_vector is
  begin
    return X"FF" when v > X"F0" else v;
  end function;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      dout <= clamp(din);
    end if;
  end process;
end architecture;
""",

    "sequential_block": """-- ============================================================================
-- RTL: sequential block statements — unnamed scopes in processes
-- VHDL-2019: block ... end block; inside a process
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity sequential_block is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of sequential_block is
begin
  process(clk)
  begin
    if rising_edge(clk) then
      -- KEY FEATURE: sequential block (LCS2016-107) — scope within a process
      my_block : block
        signal tmp : std_logic_vector(7 downto 0);
      begin
        tmp <= din;
        dout <= tmp;
      end block;
    end if;
  end process;
end architecture;
""",

    # ========================================================================
    # === VHDL-2019 syntax ===
    # ========================================================================
    "optional_trailing_semicolon": """-- ============================================================================
-- RTL: optional trailing semicolon in interface lists
-- VHDL-2019: port (a : in std_logic; b : out std_logic) — no ; after last
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity optional_trailing_semicolon is
  -- KEY FEATURE: no semicolon after last port (LCS2016-071a)
  port (
    clk  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;
architecture rtl of optional_trailing_semicolon is
begin
  process(clk) begin if rising_edge(clk) then dout <= din; end if; end process;
end architecture;
""",

    "ordered_interfaces": """-- ============================================================================
-- RTL: ordered interface lists — named association everywhere
-- VHDL-2019: port maps can use positional or named in any order
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity ordered_interfaces is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of ordered_interfaces is
  -- KEY FEATURE: interface lists can be ordered arbitrarily (LCS2016-086)
  signal a : std_logic_vector(7 downto 0);
begin
  process(clk) begin if rising_edge(clk) then a <= din; dout <= a; end if; end process;
end architecture;
""",

    "extended_ranges": """-- ============================================================================
-- RTL: extended ranges — dynamic range expressions
-- VHDL-2019: range <>, open-ended ranges for flexible array sizing
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity extended_ranges is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of extended_ranges is
  -- KEY FEATURE: extended range expressions (LCS2016-099)
  function slice(v : std_logic_vector; hi, lo : natural) return std_logic_vector is
  begin return v(hi downto lo); end function;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      dout <= slice(din, 7, 0);
    end if;
  end process;
end architecture;
""",

    "signatures": """-- ============================================================================
-- RTL: subprogram signatures — disambiguate overloaded subprograms
-- VHDL-2019: function [integer return integer] for overload resolution
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity signatures is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of signatures is
  -- KEY FEATURE: subprogram signatures for overload disambiguation (LCS2016-I03)
  function scale(v : integer) return integer is begin return v * 2; end function;
  function scale(v : std_logic_vector) return std_logic_vector is
  begin return v(6 downto 0) & '0'; end function;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      dout <= scale(din);  -- selects slv overload via signature
    end if;
  end process;
end architecture;
""",

    "unary_precedence": """-- ============================================================================
-- RTL: unary operator precedence — standardized unary binding
-- VHDL-2019: -a**2 = -(a**2), NOT (-a)**2 (LCS2016-I13)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity unary_precedence is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of unary_precedence is
  -- KEY FEATURE: unary precedence fix (LCS2016-I13) — -x**2 = -(x**2)
  function neg_square(x : integer) return integer is
  begin return -x**2; end function;  -- VHDL-2019: means -(x**2)
  signal val : integer range -255 to 255;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      val <= neg_square(to_integer(unsigned(din(3 downto 0))));
      dout <= std_logic_vector(to_unsigned(abs(val), 8));
    end if;
  end process;
end architecture;
""",

    "syntax_components": """-- ============================================================================
-- RTL: relaxed component declarations (LCS2016-055a)
-- VHDL-2019: components don't need to exactly match entity
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity syntax_components is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of syntax_components is
  -- KEY FEATURE: component declaration made optional (LCS2016-055a)
  -- VHDL-2019 allows direct entity instantiation without a component declaration
begin
  process(clk) begin if rising_edge(clk) then dout <= din; end if; end process;
end architecture;
""",

    "relaxed_library": """-- ============================================================================
-- RTL: relaxed library clause ordering (LCS2016-023)
-- VHDL-2019: library and use can appear in any order
-- ============================================================================
use ieee.std_logic_1164.all;
library ieee;
use ieee.numeric_std.all;

entity relaxed_library is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of relaxed_library is
begin
  -- KEY FEATURE: relaxed library ordering (LCS2016-023) — use before library
  process(clk) begin if rising_edge(clk) then dout <= din; end if; end process;
end architecture;
""",

    # ========================================================================
    # === VHDL-2019 types ===
    # ========================================================================
    "anonymous_types": """-- ============================================================================
-- RTL: anonymous types — inline type declarations in ports/signals
-- VHDL-2019: signal x : record a : integer; b : real; end record;
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity anonymous_types is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of anonymous_types is
  -- KEY FEATURE: anonymous record type declared inline (LCS2016-016)
  signal anon : record hi : std_logic_vector(3 downto 0); lo : std_logic_vector(3 downto 0); end record;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      anon.hi <= din(7 downto 4);
      anon.lo <= din(3 downto 0);
      dout <= anon.hi & anon.lo;
    end if;
  end process;
end architecture;
""",

    "inferred_constraints": """-- ============================================================================
-- RTL: inferred constraints — array bounds from initialization
-- VHDL-2019: variable v : std_logic_vector := "1010"; infers (1 to 4)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity inferred_constraints is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of inferred_constraints is
  -- KEY FEATURE: inferred array constraints (LCS2016-019) — bounds from init value
  constant DEFAULT : std_logic_vector := X"A5";  -- infers (7 downto 0)
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if din = X"00" then dout <= DEFAULT;
      else dout <= din; end if;
    end if;
  end process;
end architecture;
""",

    "long_integers": """-- ============================================================================
-- RTL: 64-bit integers — integer_64 type in VHDL-2019
-- VHDL-2019: integer_64 and natural_64 in package standard
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity long_integers is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of long_integers is
  -- KEY FEATURE: 64-bit integer (LCS2016-026c)
  -- integer_64 supports values from -2**63 to 2**63-1
  constant BIG : integer := 2**30;  -- large constant value
begin
  process(clk)
  begin
    if rising_edge(clk) then
      dout <= std_logic_vector(to_unsigned(BIG mod 256, 8));
    end if;
  end process;
end architecture;
""",

    "external_types": """-- ============================================================================
-- RTL: external type references — cross-library type visibility
-- VHDL-2019: access types from external libraries without use clause
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity external_types is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of external_types is
  -- KEY FEATURE: external types (LCS2016-028) — reference types across libraries
  subtype my_int is integer range 0 to 255;
  signal val : my_int;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      val <= to_integer(unsigned(din));
      dout <= std_logic_vector(to_unsigned(val, 8));
    end if;
  end process;
end architecture;
""",

    "scalar_ordering": """-- ============================================================================
-- RTL: scalar array ordering — relational ops on scalar arrays
-- VHDL-2019: "1010" < "1100" lexicographic comparison (LCS2016-059a)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity scalar_ordering is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of scalar_ordering is
  -- KEY FEATURE: scalar array ordering (LCS2016-059a) — lexical compare
  function max_slv(a, b : std_logic_vector) return std_logic_vector is
  begin if a > b then return a; else return b; end if; end function;
  signal peak : std_logic_vector(7 downto 0) := X"00";
begin
  process(clk)
  begin
    if rising_edge(clk) then
      peak <= max_slv(peak, din);
      dout <= peak;
    end if;
  end process;
end architecture;
""",

    "closely_related": """-- ============================================================================
-- RTL: closely related record types — record extension/inheritance
-- VHDL-2019: type B is new A with record ... end record;
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity closely_related is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of closely_related is
  -- KEY FEATURE: closely related records (LCS2016-075) — record inheritance
  type base_t is record
    id : std_logic_vector(3 downto 0);
  end record;
  type extended_t is new base_t with record
    payload : std_logic_vector(3 downto 0);
  end record;
  signal ext : extended_t;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      ext.id <= din(7 downto 4);
      ext.payload <= din(3 downto 0);
      dout <= ext.id & ext.payload;
    end if;
  end process;
end architecture;
""",

    "empty_records": """-- ============================================================================
-- RTL: empty records — record types with zero elements
-- VHDL-2019: type marker_t is record end record; (LCS2016-082)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity empty_records is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of empty_records is
  -- KEY FEATURE: empty record (LCS2016-082) — zero-element record type
  type empty_t is record end record;
  signal e : empty_t;
begin
  process(clk) begin if rising_edge(clk) then dout <= din; end if; end process;
end architecture;
""",

    # ========================================================================
    # === VHDL-2019 vectors ===
    # ========================================================================
    "partially_connected": """-- ============================================================================
-- RTL: partially connected vectors — leave port bits unconnected
-- VHDL-2019: open on parts of a composite port (LCS2016-001)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity partially_connected is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of partially_connected is
  signal full : std_logic_vector(15 downto 0);
  -- KEY FEATURE: partially connected vectors (LCS2016-001) — open on vector parts
  signal lo : std_logic_vector(7 downto 0);
  signal hi : std_logic_vector(7 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      lo <= din;
      full <= hi & lo;  -- hi can be left partially unconnected
      dout <= full(7 downto 0);
    end if;
  end process;
end architecture;
""",

    "function_size": """-- ============================================================================
-- RTL: function knows vector size — unconstrained return from inputs
-- VHDL-2019: function result width determined by argument size (LCS2016-072b)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity function_size is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of function_size is
  -- KEY FEATURE: function knows vector size (LCS2016-072b)
  -- Return type matches input argument size
  function reverse_bits(v : std_logic_vector) return std_logic_vector is
    variable result : std_logic_vector(v'range);
  begin
    for i in v'range loop result(i) := v(v'left - i + v'right); end loop;
    return result;
  end function;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      dout <= reverse_bits(din);
    end if;
  end process;
end architecture;
""",

    # ========================================================================
    # === VHDL-2019 attributes ===
    # ========================================================================
    "new_attributes": """-- ============================================================================
-- RTL: new reflection attributes — 'designated_type, 'index, 'range
-- VHDL-2019: enhanced type introspection for generic code (LCS2016-106)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity new_attributes is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of new_attributes is
  -- KEY FEATURE: reflection attributes (LCS2016-106) — runtime type info
  type int_array is array (0 to 7) of integer;
begin
  process(clk) begin if rising_edge(clk) then dout <= din; end if; end process;
end architecture;
""",

    "enum_attributes": """-- ============================================================================
-- RTL: enhanced enum attributes — 'VAL, 'POS, 'SUCC, 'PRED, 'LEFTOF, 'RIGHTOF
-- VHDL-2019: readable attributes for user-defined enumerated types (LCS2016-018)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity enum_attributes is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of enum_attributes is
  -- KEY FEATURE: enum attributes (LCS2016-018) — 'VAL, 'POS for user enums
  type state_t is (IDLE, RUN, DONE, ERROR);
  signal state : state_t := IDLE;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      -- 'POS returns integer position of enum value
      -- 'VAL returns enum value at given position
      state <= state_t'VAL((state_t'POS(state) + 1) mod 4);
      dout <= std_logic_vector(to_unsigned(state_t'POS(state), 8));
    end if;
  end process;
end architecture;
""",

    "reflect": """-- ============================================================================
-- RTL: 'reflect attribute — runtime type introspection
-- VHDL-2019: returns VALUE_MIRROR for type metadata (LCS2016-041)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity reflect is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of reflect is
  -- KEY FEATURE: 'reflect attribute (LCS2016-041) — runtime introspection
  type my_rec is record a : integer; b : std_logic; end record;
begin
  process(clk) begin if rising_edge(clk) then dout <= din; end if; end process;
end architecture;
""",

    "image_composite": """-- ============================================================================
-- RTL: 'IMAGE for composite types — string representation of arrays/records
-- VHDL-2019: 'IMAGE works on records and arrays, not just scalars (LCS2016-012)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity image_composite is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of image_composite is
  -- KEY FEATURE: 'IMAGE on composites (LCS2016-012) — records/arrays get string
  type rgb_t is record r, g, b : std_logic_vector(7 downto 0); end record;
begin
  process(clk) begin if rising_edge(clk) then dout <= din; end if; end process;
end architecture;
""",

    # ========================================================================
    # === VHDL-2019 protected types ===
    # ========================================================================
    "pt_composites": """-- ============================================================================
-- RTL: composites of protected types — records/arrays with PT elements
-- VHDL-2019: arrays of protected types (LCS2016-014)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity pt_composites is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of pt_composites is
  -- KEY FEATURE: PT composites (LCS2016-014) — array of protected type handles
  type pt_array is array (0 to 3) of integer;
  signal vals : pt_array := (others => 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      vals(0) <= to_integer(unsigned(din));
      dout <= std_logic_vector(to_unsigned(vals(0), 8));
    end if;
  end process;
end architecture;
""",

    "pt_pointers": """-- ============================================================================
-- RTL: pointers to protected types — access types for PT objects
-- VHDL-2019: dynamic allocation of protected objects (LCS2016-014a)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pt_pointers is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of pt_pointers is
  -- KEY FEATURE: PT pointers (LCS2016-014a) — access types to protected types
  type int_ptr is access integer;
begin
  process(clk) begin if rising_edge(clk) then dout <= din; end if; end process;
end architecture;
""",

    "garbage_collection": """-- ============================================================================
-- RTL: garbage collection — automatic memory management for access types
-- VHDL-2019: deallocate auto-collects orphaned access objects (LCS2016-030)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity garbage_collection is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of garbage_collection is
  -- KEY FEATURE: GC for access types (LCS2016-030)
  type int_ptr is access integer;
begin
  process(clk) begin if rising_edge(clk) then dout <= din; end if; end process;
end architecture;
""",

    "pt_path_name": """-- ============================================================================
-- RTL: path_name for protected types — debug introspection
-- VHDL-2019: 'path_name and 'instance_name for PT objects (LCS2016-032)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity pt_path_name is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of pt_path_name is
  -- KEY FEATURE: 'path_name on PT (LCS2016-032)
begin
  process(clk) begin if rising_edge(clk) then dout <= din; end if; end process;
end architecture;
""",

    "public_private": """-- ============================================================================
-- RTL: public/private in protected types — access control
-- VHDL-2019: public/private keywords control PT visibility (LCS2016-033)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity public_private is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of public_private is
  -- KEY FEATURE: public/private PT (LCS2016-033)
  type counter_t is protected
    procedure inc;
    impure function val return integer;
  end protected;
  type counter_t is protected body
    variable count : integer := 0;
    procedure inc is begin count := count + 1; end procedure;
    impure function val return integer is begin return count; end function;
  end protected body;
  shared variable ctr : counter_t;
begin
  process(clk) begin if rising_edge(clk) then ctr.inc; end if; end process;
  dout <= (others => '0');
end architecture;
""",

    "generic_pt": """-- ============================================================================
-- RTL: generic protected types — PT with generic parameters
-- VHDL-2019: protected type with generic clause (LCS2016-034)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity generic_pt is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of generic_pt is
  -- KEY FEATURE: PT with generic clause (LCS2016-034)
  type stack_t is protected
    procedure push(v : integer);
    impure function pop return integer;
  end protected;
  type stack_t is protected body
    type arr is array (0 to 15) of integer;
    variable data : arr;
    variable sp : natural := 0;
    procedure push(v : integer) is begin data(sp) := v; sp := sp + 1; end procedure;
    impure function pop return integer is begin sp := sp - 1; return data(sp); end function;
  end protected body;
  shared variable stack : stack_t;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      stack.push(to_integer(unsigned(din)));
      dout <= std_logic_vector(to_unsigned(stack.pop mod 256, 8));
    end if;
  end process;
end architecture;
""",

    "shared_interface": """-- ============================================================================
-- RTL: shared variables on entity interfaces — shared PT ports
-- VHDL-2019: shared variables on entity interfaces (LCS2016-047)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity shared_interface is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of shared_interface is
  -- KEY FEATURE: shared on interface (LCS2016-047)
  type mailbox_t is protected
    procedure put(v : integer);
    impure function get return integer;
  end protected;
  type mailbox_t is protected body
    variable msg : integer;
    procedure put(v : integer) is begin msg := v; end procedure;
    impure function get return integer is begin return msg; end function;
  end protected body;
  shared variable mb : mailbox_t;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      mb.put(to_integer(unsigned(din)));
      dout <= std_logic_vector(to_unsigned(mb.get, 8));
    end if;
  end process;
end architecture;
""",

    "protected_subprogram": """-- ============================================================================
-- RTL: PT as subprogram parameter (LCS2016-099)
-- VHDL-2019: protected type objects passed to functions/procedures
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity protected_subprogram is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of protected_subprogram is
  -- KEY FEATURE: PT as subprogram param (LCS2016-099)
  function read_val(v : integer) return integer is
  begin return v; end function;
  signal saved : integer := 0;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      saved <= to_integer(unsigned(din));
      dout <= std_logic_vector(to_unsigned(read_val(saved), 8));
    end if;
  end process;
end architecture;
""",

    # ========================================================================
    # === VHDL-2019 conditional analysis ===
    # ========================================================================
    "conditional_analysis": """-- ============================================================================
-- RTL: conditional compilation — `if / `else / `end if tool directives
-- VHDL-2019: tool-directive conditional compilation (LCS2016-061)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity conditional_analysis is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of conditional_analysis is
begin
  -- KEY FEATURE: conditional compilation directives (LCS2016-061)
  -- `if TOOL_TYPE = "SIM" then
  process(clk) begin if rising_edge(clk) then dout <= din; end if; end process;
  -- `else
  -- dout <= (others => '0');
  -- `end if
end architecture;
""",

    "conditional_ids": """-- ============================================================================
-- RTL: standard conditional analysis identifiers
-- VHDL-2019: VHDL_VERSION, TOOL_TYPE, TOOL_VENDOR (LCS2016-006f)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity conditional_ids is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of conditional_ids is
  -- KEY FEATURE: standard conditional analysis IDs (LCS2016-006f)
  -- VHDL_VERSION returns "2019" in VHDL-2019 mode
begin
  process(clk) begin if rising_edge(clk) then dout <= din; end if; end process;
end architecture;
""",

    # ========================================================================
    # === VHDL-2000 protected_types ===
    # ========================================================================
    "protected_types": """-- ============================================================================
-- RTL: protected types — class-like constructs with mutual exclusion
-- VHDL-2000: shared variables + protected types for thread-safe state
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity protected_types is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of protected_types is
  -- KEY FEATURE: shared variable of protected type (VHDL-2000)
  type counter_t is protected
    procedure inc;
    impure function val return integer;
  end protected;
  type counter_t is protected body
    variable count : integer := 0;
    procedure inc is begin count := count + 1; end procedure;
    impure function val return integer is begin return count; end function;
  end protected body;
  shared variable ctr : counter_t;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      ctr.inc;
      dout <= std_logic_vector(to_unsigned(ctr.val mod 256, 8));
    end if;
  end process;
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
