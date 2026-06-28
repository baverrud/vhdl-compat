-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Function knows vector size — result type depends on input sizes
-- CATEGORY: vectors
-- XREF: LCS2016-072b
-- SYNTH_ENTITY: function_size
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, function result types had to be fixed or depend on
--   generic parameters. A function that concatenated two vectors could not
--   return a result whose size was the sum of the input sizes — you had
--   to use a fixed return type or pass the size as a generic.
--
--   VHDL-2019 introduces "size-respecting functions" where the return type
--   can depend on the sizes of the actual parameters. The function can
--   compute the return array bounds from the input bounds.
--
--   This enables writing functions like:
--     function concat(a, b : std_logic_vector) return std_logic_vector;
--   where the return length is a'length + b'length, determined at call time.
--
--   This test defines a concat function that returns a vector whose size
--   depends on the inputs, and verifies it works for different sizes.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity function_size_tb is
end entity;

architecture test of function_size_tb is

  -- VHDL-2019: Function whose result size depends on actual parameter sizes
  function concat(
    a : std_logic_vector;
    b : std_logic_vector
  ) return std_logic_vector is
    variable result : std_logic_vector(a'length + b'length - 1 downto 0);
  begin
    result(a'length + b'length - 1 downto b'length) := a;
    result(b'length - 1 downto 0) := b;
    return result;
  end function;

begin

  stim_proc : process
    variable a4 : std_logic_vector(3 downto 0) := X"A";
    variable b4 : std_logic_vector(3 downto 0) := X"5";
    variable a2 : std_logic_vector(1 downto 0) := "11";
    variable b6 : std_logic_vector(5 downto 0) := "111000";
    variable r8 : std_logic_vector(7 downto 0);
    variable r_expected : std_logic_vector(7 downto 0);
  begin
    report "==============================================" severity note;
    report "TEST: Function knows vector size" severity note;
    report "STD:  VHDL-2019 (LCS2016-072b)" severity note;
    report "==============================================" severity note;

    -- Concatenate 4-bit + 4-bit = 8-bit
    r_expected := X"A5";
    r8 := concat(a4, b4);
    assert r8 = r_expected
      report "FAIL: concat(A, 5) should be A5, got " & to_string(r8)
      severity error;

    -- Concatenate 2-bit + 6-bit = 8-bit
    r_expected := "11" & "111000";
    r8 := concat(a2, b6);
    assert r8 = r_expected
      report "FAIL: concat(11, 111000) should be 11111000"
      severity error;

    report "PASS: Function knows vector size works correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
