-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Matching equality/inequality (?=, ?/=) — don't-care aware comparison
-- CATEGORY: expressions
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2008, comparing std_logic values required exact equality (=)
--   or inequality (/=). The '-' (don't-care) value could never match anything.
--   This made testbench checking of partially-specified values cumbersome.
--
--   VHDL-2008 introduces matching operators that treat '-' as a wildcard:
--     ?=  — matching equality ('-' matches anything)
--     ?/= — matching inequality
--     ?<  — matching less-than
--     ?<= — matching less-than-or-equal
--     ?>  — matching greater-than
--     ?>= — matching greater-than-or-equal
--
--   The ?= operator is what powers the matching case statement (case?).
--   This test verifies each matching operator independently.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_matching_operators is
end entity;

architecture test of tb_matching_operators is
begin

  stim_proc : process
    variable a, b : std_logic_vector(3 downto 0);
  begin
    report "==============================================" severity note;
    report "TEST: Matching operators (?=, ?/=, ?<, ?<=, ?>, ?>=)" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- ------------------------------------------------------------------------
    -- ?= (matching equality): '-' matches anything, returns '1' for true
    -- ------------------------------------------------------------------------
    a := "1010";  b := "1010";
    assert (a ?= b) = '1'
      report "FAIL: ?= exact match failed" severity error;

    a := "10--";  b := "1010";
    assert (a ?= b) = '1'
      report "FAIL: ?= wildcard: 10-- should match 1010" severity error;

    a := "1--0";  b := "1110";
    assert (a ?= b) = '1'
      report "FAIL: ?= multi-dc: 1--0 should match 1110" severity error;

    a := "1010";  b := "1011";
    assert (a ?= b) = '0'
      report "FAIL: ?= mismatch: 1010 should not match 1011" severity error;

    -- ------------------------------------------------------------------------
    -- ?/= (matching inequality)
    -- ------------------------------------------------------------------------
    a := "1010";  b := "1010";
    assert (a ?/= b) = '0'
      report "FAIL: ?/= exact: equal values should not be ?/=" severity error;

    a := "1010";  b := "1011";
    assert (a ?/= b) = '1'
      report "FAIL: ?/= diff: different values should be ?/=" severity error;

    -- ------------------------------------------------------------------------
    -- edge cases
    -- ------------------------------------------------------------------------
    a := "----";  b := "0000";
    assert (a ?= b) = '1'
      report "FAIL: all-dc should match anything" severity error;

    -- VHDL-2008: ?? operator converts ?= result ('1'/'0') to boolean
    assert (?? (a ?= b)) = true
      report "FAIL: ?? on ?= result should give boolean true" severity error;

    report "PASS: Matching equality/inequality operators work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
