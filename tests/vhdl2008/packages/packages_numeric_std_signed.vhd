-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: numeric_std_signed — signed arithmetic on std_logic_vector without casting
-- CATEGORY: packages
-- SYNTH_ENTITY: numeric_std_signed
-- TEST_TYPE: both
-- DESCRIPTION:
--   numeric_std_signed is the signed counterpart to numeric_std_unsigned.
--   It interprets std_logic_vector as signed (2's complement) for
--   arithmetic operations, comparisons, and conversions.
--
--   Without it, signed arithmetic on std_logic_vector requires casting:
--       sum <= std_logic_vector(signed(a) + signed(b));
--   With numeric_std_signed:
--       use ieee.numeric_std_signed.all;
--       sum <= a + b;  -- direct signed arithmetic!
--
--   This test verifies addition, subtraction, and comparison using
--   numeric_std_signed.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_signed.all;
use std.env.all;

entity numeric_std_signed_tb is
end entity;

architecture test of numeric_std_signed_tb is
  signal a, b : std_logic_vector(7 downto 0) := X"00";
  signal sum  : std_logic_vector(7 downto 0);
begin

  sum <= a + b;

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: numeric_std_signed package" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- Positive + Positive
    a <= X"03";  b <= X"05";
    wait for 5 ns;
    assert sum = X"08"
      report "FAIL: 3 + 5 should be 8, got " & to_string(sum)
      severity error;

    -- Negative + Positive: -1 + 3 = 2
    a <= X"FF";  b <= X"03";   -- FF = -1 in signed, 03 = 3
    wait for 5 ns;
    assert sum = X"02"
      report "FAIL: -1 + 3 should be 2, got " & to_string(sum)
      severity error;

    -- Comparison: signed ordering
    a <= X"FF";  b <= X"01";   -- FF = -1, 01 = 1
    wait for 1 ns;
    assert (a < b) = true      -- -1 < 1 should be true (signed comparison)
      report "FAIL: -1 should be < 1 in signed comparison"
      severity error;

    -- Negative + Negative: -2 + -3 = -5
    a <= X"FE";  b <= X"FD";   -- FE = -2, FD = -3
    wait for 5 ns;
    assert sum = X"FB"         -- -5 in 8-bit signed
      report "FAIL: -2 + -3 should be -5 (FB), got " & to_string(sum)
      severity error;

    report "PASS: numeric_std_signed works correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
