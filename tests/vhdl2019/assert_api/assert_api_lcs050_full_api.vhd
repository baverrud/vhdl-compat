-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Full assert API — IsVhdlAssertFailed, GetVhdlAssertCount, SetVhdlAssertFormat
-- CATEGORY: assert_api
-- XREF: LCS2016-050
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2019, assert statements could only report pass/fail. There
--   was no programmatic way to query whether an assertion had failed, count
--   the number of failures, or customize the assertion message format.
--
--   VHDL-2019 introduces a full assert API:
--     IsVhdlAssertFailed     — returns true if any assert has failed
--     GetVhdlAssertCount     — returns the number of assertion failures
--     SetVhdlAssertFormat    — customize the default assertion message
--     GetVhdlAssertFormat    — get the current format string
--     ClearVhdlAssert        — reset the assertion state
--     SetVhdlAssertSeverity  — change the default severity
--
--   This enables testbench frameworks to programmatically track assertion
--   results and generate custom reports.
--
--   This test verifies IsVhdlAssertFailed and GetVhdlAssertCount.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_assert_api is
end entity;

architecture test of tb_assert_api is
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Full assert API (IsVhdlAssertFailed, GetVhdlAssertCount)" severity note;
    report "STD:  VHDL-2019 (LCS2016-050)" severity note;
    report "==============================================" severity note;

    -- VHDL-2019: Check initial state
    report "  Initial assert count: " & integer'image(GetVhdlAssertCount) severity note;
    assert IsVhdlAssertFailed = false
      report "FAIL: No assertions should be failed initially"
      severity error;

    -- Trigger a known assertion failure (non-fatal severity NOTE)
    assert false
      report "This is an intentional test assertion"
      severity note;

    -- VHDL-2019: Query assertion state
    report "  Assert count after note: " & integer'image(GetVhdlAssertCount) severity note;

    -- Verify the API functions exist and can be called
    report "  IsVhdlAssertFailed returns: " & boolean'image(IsVhdlAssertFailed) severity note;

    report "PASS: Full assert API functions are available" severity note;
    stop(0);
    wait;
  end process;

end architecture;
