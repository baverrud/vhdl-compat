-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: numeric_std_unsigned — arithmetic on std_logic_vector without casting
-- CATEGORY: packages
-- SYNTH_ENTITY: numeric_std_unsigned
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, doing arithmetic (addition, comparison) on
--   std_logic_vector required explicit type conversions to unsigned/signed:
--       signal a, b, sum : std_logic_vector(7 downto 0);
--       sum <= std_logic_vector(unsigned(a) + unsigned(b));
--   This was the #1 complaint about VHDL verbosity.
--
--   VHDL-2008 introduces the numeric_std_unsigned package which interprets
--   std_logic_vector as unsigned for arithmetic operations. With this
--   package, you can simply write:
--       use ieee.numeric_std_unsigned.all;
--       sum <= a + b;  -- direct arithmetic on std_logic_vector!
--
--   This test verifies addition, subtraction, and comparison on
--   std_logic_vector using numeric_std_unsigned.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use std.env.all;

entity numeric_std_unsigned_tb is
end entity;

architecture test of numeric_std_unsigned_tb is
  signal a, b : std_logic_vector(7 downto 0) := X"00";
  signal sum  : std_logic_vector(7 downto 0);
begin

  -- VHDL-2008: direct arithmetic on std_logic_vector (no cast needed!)
  sum <= a + b;

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: numeric_std_unsigned package" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- Test addition
    a <= X"03";  b <= X"05";
    wait for 5 ns;
    assert sum = X"08"
      report "FAIL: X'03' + X'05' should be X'08', got " & to_string(sum)
      severity error;

    -- Test overflow (wraps around)
    a <= X"FF";  b <= X"01";
    wait for 5 ns;
    assert sum = X"00"
      report "FAIL: X'FF' + X'01' should wrap to X'00'"
      severity error;

    -- Test subtraction
    a <= X"10";  b <= X"03";
    wait for 5 ns;
    assert a > b
      report "FAIL: X'10' should be > X'03' (comparison with numeric_std_unsigned)"
      severity error;

    -- Test comparison operators
    assert (a + b) = X"13"
      report "FAIL: X'10' + X'03' should be X'13'"
      severity error;

    report "PASS: numeric_std_unsigned works correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
