-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: std.env.stop / std.env.finish — standard simulation control
-- CATEGORY: verification
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2008, ending a simulation required simulator-specific
--   mechanisms. There was no standard VHDL way to stop or finish
--   simulation. Some tools used assertion failures with severity FAILURE,
--   others used Tcl commands.
--
--   VHDL-2008 introduces the std.env package with:
--     procedure stop;       — stop simulation (can be restarted)
--     procedure stop(status : integer);
--     procedure finish;     — finish simulation (cannot be restarted)
--     procedure finish(status : integer);
--     function resolution_limit return delay_length;
--
--   This is the VHDL-2008 baseline. VHDL-2019 later enhanced these.
--   This test verifies the basic stop() and finish() procedures exist
--   and can be called (though in a test context we only verify stop).
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity std_env_tb is
end entity;

architecture test of std_env_tb is
  signal test_passed : boolean := false;
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: std.env.stop / std.env.finish (VHDL-2008 baseline)" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- Verify std.env is available (stop is used throughout the test suite)
    report "  std.env package is accessible" severity note;

    -- Verify resolution_limit is available
    report "  Resolution limit: " & time'image(resolution_limit) severity note;

    test_passed <= true;
    report "PASS: std.env package is available and functional" severity note;
    stop(0);
    wait;
  end process;

end architecture;
