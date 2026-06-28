-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Unary reduction operators — and, or, xor, nand, nor, xnor on vectors
-- CATEGORY: expressions
-- SYNTH_ENTITY: reduction_operators
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, computing the parity or AND-reduce of a vector required
--   a loop or a chain of gates:
--       parity <= sig(0) xor sig(1) xor sig(2) xor sig(3) xor ... ;
--   This was tedious for wide vectors and error-prone.
--
--   VHDL-2008 introduces unary reduction operators that fold a vector to a
--   single bit by applying the operator across all elements:
--     and  "1011" → '0'   (all bits ANDed together)
--     or   "1011" → '1'
--     xor  "1011" → '1'   (parity — odd number of '1's)
--     nand "1011" → '1'   (NOT of and)
--     nor  "1011" → '0'   (NOT of or)
--     xnor "1011" → '0'   (NOT of xor — even parity)
--
--   These work on std_logic_vector, unsigned, and signed types.
--   This test verifies each reduction operator.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity reduction_operators_tb is
end entity;

architecture test of reduction_operators_tb is
begin

  stim_proc : process
    variable slv : std_logic_vector(3 downto 0);
    variable u   : unsigned(3 downto 0);
  begin
    report "==============================================" severity note;
    report "TEST: Unary reduction operators (and, or, xor, nand, nor, xnor)" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    ------------------------------------------------------------------------
    -- std_logic_vector tests
    ------------------------------------------------------------------------
    slv := "1011";

    -- and reduce: 1 and 0 and 1 and 1 = '0'
    assert (and slv) = '0'
      report "FAIL: and ""1011"" should be '0', got " & std_logic'image(and slv)
      severity error;

    -- or reduce: 1 or 0 or 1 or 1 = '1'
    assert (or slv) = '1'
      report "FAIL: or ""1011"" should be '1', got " & std_logic'image(or slv)
      severity error;

    -- xor reduce: 1 xor 0 xor 1 xor 1 = '1' (odd parity)
    assert (xor slv) = '1'
      report "FAIL: xor ""1011"" should be '1' (odd parity), got " & std_logic'image(xor slv)
      severity error;

    -- nand reduce: not (1 and 0 and 1 and 1) = '1'
    assert (nand slv) = '1'
      report "FAIL: nand ""1011"" should be '1', got " & std_logic'image(nand slv)
      severity error;

    -- nor reduce: not (1 or 0 or 1 or 1) = '0'
    assert (nor slv) = '0'
      report "FAIL: nor ""1011"" should be '0', got " & std_logic'image(nor slv)
      severity error;

    -- xnor reduce: not (1 xor 0 xor 1 xor 1) = '0' (even parity)
    assert (xnor slv) = '0'
      report "FAIL: xnor ""1011"" should be '0' (even parity), got " & std_logic'image(xnor slv)
      severity error;

    ------------------------------------------------------------------------
    -- Edge cases
    ------------------------------------------------------------------------
    -- All ones
    slv := "1111";
    assert (and slv) = '1'
      report "FAIL: and ""1111"" should be '1'"
      severity error;
    assert (xor slv) = '0'
      report "FAIL: xor ""1111"" should be '0' (even # of 1s)"
      severity error;

    -- All zeros
    slv := "0000";
    assert (or slv) = '0'
      report "FAIL: or ""0000"" should be '0'"
      severity error;
    assert (nor slv) = '1'
      report "FAIL: nor ""0000"" should be '1'"
      severity error;

    ------------------------------------------------------------------------
    -- unsigned type (also supported)
    ------------------------------------------------------------------------
    u := "1011";
    assert (or u) = '1'
      report "FAIL: or on unsigned should also work"
      severity error;

    report "PASS: All unary reduction operators work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
