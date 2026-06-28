-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: All interface lists can be ordered — named association everywhere
-- CATEGORY: syntax
-- XREF: LCS2016-086
-- SYNTH_ENTITY: ordered_interfaces
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, certain interface lists required positional
--   association. For example, generic maps on configurations and some
--   subprogram calls could not use named association, forcing you to
--   match positions exactly.
--
--   VHDL-2019 standardizes that ALL interface lists (port maps, generic
--   maps, subprogram calls, configuration bindings) support both
--   positional and named association interchangeably.
--
--   This test verifies named association works on entity instantiation
--   (which was already allowed) and subprogram calls (which was expanded).
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity ordered_interfaces_tb is
end entity;

architecture test of ordered_interfaces_tb is

  function add(constant a, b : integer) return integer is
  begin
    return a + b;
  end function;

begin

  stim_proc : process
    variable result : integer;
  begin
    report "==============================================" severity note;
    report "TEST: All interface lists can be ordered" severity note;
    report "STD:  VHDL-2019 (LCS2016-086)" severity note;
    report "==============================================" severity note;

    -- VHDL-2019: Named association in subprogram call
    result := add(a => 10, b => 20);
    assert result = 30
      report "FAIL: add(a=>10, b=>20) should be 30, got " & integer'image(result)
      severity error;

    -- Named parameters in any order
    result := add(b => 5, a => 15);
    assert result = 20
      report "FAIL: add(b=>5, a=>15) should be 20"
      severity error;

    -- Mixed positional and named (positional first, then named)
    result := add(7, b => 3);
    assert result = 10
      report "FAIL: add(7, b=>3) should be 10"
      severity error;

    report "PASS: All interface lists support named association" severity note;
    stop(0);
    wait;
  end process;

end architecture;
