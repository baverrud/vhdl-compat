-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Optional report clause in assert — assert without message string
-- CATEGORY: assert_api
-- XREF: LCS2016-081
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2019, every assert statement required a report clause with a
--   message string. You had to write:
--       assert sig = '1' report "sig must be '1'" severity error;
--   This was verbose and often the message was boilerplate that added no value.
--
--   VHDL-2019 makes the report clause optional. If omitted, the default report
--   message is "Assertion violation". The severity also becomes optional and
--   defaults to ERROR. You can now write simply:
--       assert sig = '1';
--
--   This test verifies all four forms of the simplified assert.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity assert_no_message_tb is
end entity;

architecture test of assert_no_message_tb is
  signal valid : std_logic := '1';
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Optional report clause in assert" severity note;
    report "STD:  VHDL-2019 (LCS2016-081)" severity note;
    report "==============================================" severity note;

    -- Test 1: assert without report clause (VHDL-2019 only)
    -- Default message: "Assertion violation", default severity: ERROR
    assert valid = '1';
    report "  assert without report clause passed" severity note;

    -- Test 2: assert with report but without severity (VHDL-2019 only)
    assert valid = '1' report "valid was '0'";
    report "  assert without severity clause passed" severity note;

    -- Test 3: assert with severity but without report (VHDL-2019 only)
    assert valid = '1' severity note;
    report "  assert with severity but no report passed" severity note;

    -- Test 4: traditional full assert (works in all standards)
    assert valid = '1' report "fail" severity error;
    report "  traditional assert passed" severity note;

    report "PASS: Optional report/severity clauses work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
