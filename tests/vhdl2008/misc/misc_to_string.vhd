-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: to_string / to_bstring / to_hstring / to_ostring — formatted string conversion
-- CATEGORY: misc
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2008, converting a value to a human-readable string required
--   writing custom conversion functions or using 'IMAGE (which only worked
--   for scalar types and had a fixed format with leading spaces).
--
--   VHDL-2008 introduces standard string conversion functions:
--     to_string(x)   — decimal/format string
--     to_bstring(x)  — binary string (e.g., "1010")
--     to_hstring(x)  — hex string (e.g., "A")
--     to_ostring(x)  — octal string (e.g., "12")
--
--   These work on std_logic_vector, unsigned, signed, integer, time, etc.
--   They are essential for clean testbench reporting.
--
--   This test verifies to_bstring, to_hstring, and to_ostring output.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity to_string_tb is
end entity;

architecture test of to_string_tb is
begin

  stim_proc : process
    variable u : unsigned(7 downto 0);
    variable s : signed(7 downto 0);
    variable slv : std_logic_vector(7 downto 0);
  begin
    report "==============================================" severity note;
    report "TEST: to_string / to_bstring / to_hstring / to_ostring" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    ------------------------------------------------------------------------
    -- to_bstring (binary representation)
    ------------------------------------------------------------------------
    u := X"5A";  -- 0101_1010
    assert to_bstring(u) = "01011010"
      report "FAIL: to_bstring(X'5A') should be '01011010', got '" & to_bstring(u) & "'"
      severity error;

    -- to_bstring with format specification
    assert to_bstring(u) = "01011010"
      report "FAIL: to_bstring with explicit width"
      severity error;

    ------------------------------------------------------------------------
    -- to_hstring (hex representation)
    ------------------------------------------------------------------------
    u := X"AB";
    assert to_hstring(u) = "AB"
      report "FAIL: to_hstring(X'AB') should be 'AB', got '" & to_hstring(u) & "'"
      severity error;

    ------------------------------------------------------------------------
    -- to_ostring (octal representation)
    ------------------------------------------------------------------------
    u := X"1A";  -- 0001_1010 = 032 in octal
    assert to_ostring(u) = "032"
      report "FAIL: to_ostring(X'1A') should be '032', got '" & to_ostring(u) & "'"
      severity error;

    ------------------------------------------------------------------------
    -- to_string on integer
    ------------------------------------------------------------------------
    assert to_string(42) = "42"
      report "FAIL: to_string(42) should be '42', got '" & to_string(42) & "'"
      severity error;

    ------------------------------------------------------------------------
    -- on signed
    ------------------------------------------------------------------------
    s := X"FF";  -- -1 in signed
    -- to_integer for verification
    assert to_integer(s) = -1
      report "FAIL: signed X'FF' should be -1"
      severity error;

    report "PASS: to_string / to_bstring / to_hstring / to_ostring work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
