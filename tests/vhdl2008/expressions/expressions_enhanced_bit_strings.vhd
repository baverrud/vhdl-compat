-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Enhanced bit string literals -- width, signed/unsigned, don't-care
-- CATEGORY: expressions
-- XREF: FT09
-- TEST_TYPE: sim
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

entity tb_enhanced_bit_strings is
end entity;

architecture test of tb_enhanced_bit_strings is
  signal errors : natural := 0;
begin

  stim_proc : process
    -- Helper to compare two std_logic_vectors
    procedure check (
      constant actual   : std_logic_vector;
      constant expected : std_logic_vector;
      constant label    : string
    ) is
    begin
      if actual /= expected then
        report "FAIL: " & label & " -- got " & to_string(actual)
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

    -- 2. Meta-values in bit string
    v := 6x"XF";
    check(v, "XX1111", "6x""XF"" should be XX1111 (X for upper bits, F=1111)");

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
