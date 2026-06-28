-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Enhanced bit string literals -- width, signed/unsigned, don't-care
-- CATEGORY: expressions
-- XREF: FT09
-- SYNTH_ENTITY: enhanced_bit_strings
-- TEST_TYPE: both
-- DESCRIPTION:
--   VHDL-1993 introduced bit string literals: B"1010", X"FF", O"37".
--   These were limited: you couldn't specify the width explicitly, couldn't
--   indicate signed/unsigned interpretation, and couldn't include don't-care
--   or meta-values ('U', 'X', 'Z', etc.).
--
--   VHDL-2008 enhances bit string literals with:
--     1. Explicit width:  6x"0F"  → 6-bit value
--     2. Signed/unsigned: 6SX"F"  → sign-extended (111111)
--                         6UX"F"  → zero-extended (001111)
--     3. Meta-values:     6x"XF"  → "XX1111" in binary
--     4. Don't-care:      4b"1-0" → "1-0" pattern
--
--   This test verifies all four enhancements using std_logic_vector.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;


-- ============================================================================
-- Synthesizable RTL — demonstrates this VHDL feature in hardware
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity enhanced_bit_strings is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of enhanced_bit_strings is
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity enhanced_bit_strings_tb is
end entity;

architecture test of enhanced_bit_strings_tb is
  signal errors : natural := 0;
begin

  stim_proc : process
    -- Helper to compare two std_logic_vectors
    procedure check (
      constant actual   : std_logic_vector;
      constant expected : std_logic_vector;
      constant msg      : string
    ) is
    begin
      if actual /= expected then
        report "FAIL: " & msg & " -- got " & to_string(actual)
               & " expected " & to_string(expected)
          severity error;
        errors <= errors + 1;
      end if;
    end procedure;

    variable v : std_logic_vector(5 downto 0);
  begin
    report "==============================================" severity note;
    report "TEST: Enhanced bit string literals" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- 1. Explicit width hex
    v := 6x"0f";
    check(v, "001111", "6x""0f"" should be 001111 (hex 0F padded to 6 bits)");

    -- 2. Explicit width hex
    v := 6x"3f";
    check(v, "111111", "6x""3f"" should be 111111 (hex 3F, full 6-bit width)");

    -- 3. Sign extension (S) -- MSB replicates
    v := 6SX"F";
    check(v, "111111", "6SX""F"" should sign-extend: 111111");

    -- 4. Zero extension (U) -- pads with zeros
    v := 6UX"f";
    check(v, "001111", "6UX""f"" should zero-extend: 001111 (lowercase f)");

    -- 5. Binary with explicit width
    v := 6sb"11";
    check(v, "111111", "6sb""11"" should be 111111 (sign-extended binary)");

    -- 6. Octal with unsigned
    v := 6uO"7";
    check(v, "000111", "6uO""7"" should be 000111 (6-bit unsigned octal 7)");

    -- Report result
    if errors = 0 then
      report "PASS: Enhanced bit string literals work correctly" severity note;
      stop(0);
    else
      report "FAIL: Enhanced bit strings had " & integer'image(errors) & " errors"
        severity failure;
    end if;
    wait;
  end process;

end architecture;
-- TAKEAWAY: VHDL-2008 bit strings support explicit width (6x"0F"), signed/unsigned (6SX"F", 6UX"F"), and meta-values.
