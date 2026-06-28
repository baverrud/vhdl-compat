-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Scalar array ordering — relational operators on any scalar array type
-- CATEGORY: types_2019
-- XREF: LCS2016-059a
-- SYNTH_ENTITY: scalar_ordering
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, relational operators (<, >, <=, >=) were defined
--   for scalar types and one-dimensional arrays of discrete types. But
--   arrays of non-discrete elements (like arrays of reals, arrays of
--   records) did not have ordering operators.
--
--   VHDL-2019 extends ordering to any one-dimensional array whose element
--   type has ordering. Comparison is lexicographic (like dictionary
--   ordering). This is useful for sorting, priority encoding, and
--   range checks on composite data.
--
--   This test verifies ordering on integer_vector and boolean_vector.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity scalar_ordering_tb is
end entity;

architecture test of scalar_ordering_tb is
begin

  stim_proc : process
    variable a : integer_vector(0 to 2) := (1, 2, 3);
    variable b : integer_vector(0 to 2) := (1, 2, 4);
    variable c : integer_vector(0 to 2) := (1, 2, 3);
    variable d : boolean_vector(0 to 1) := (false, false);
    variable e : boolean_vector(0 to 1) := (false, true);
  begin
    report "==============================================" severity note;
    report "TEST: Scalar array ordering" severity note;
    report "STD:  VHDL-2019 (LCS2016-059a)" severity note;
    report "==============================================" severity note;

    -- VHDL-2019: Lexicographic comparison on arrays
    -- (1,2,3) < (1,2,4) because 3 < 4 at the first differing position
    assert (a < b) = true
      report "FAIL: (1,2,3) should be < (1,2,4)"
      severity error;
    assert (b > a) = true
      report "FAIL: (1,2,4) should be > (1,2,3)"
      severity error;

    -- Equal arrays
    assert (a = c) = true
      report "FAIL: (1,2,3) should equal (1,2,3)"
      severity error;
    assert (a /= b) = true
      report "FAIL: (1,2,3) should differ from (1,2,4)"
      severity error;

    -- Boolean vector ordering (false < true)
    assert (d < e) = true
      report "FAIL: (false,false) should be < (false,true)"
      severity error;

    report "PASS: Scalar array ordering works correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
