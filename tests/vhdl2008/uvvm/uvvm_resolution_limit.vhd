-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: std.env.resolution_limit returns a positive delay — UVVM delta-settle idiom
-- CATEGORY: uvvm
-- XREF: FT (std.env)
-- TEST_TYPE: sim
-- DESCRIPTION:
--   VHDL-2008 added the function std.env.resolution_limit, which returns the
--   simulator's smallest representable time step (the simulation resolution
--   limit) as a delay_length. By definition this value is strictly positive
--   (e.g. 1 ps when the resolution is 1 ps).
--
--   UVVM relies on this function pervasively. Every VVC contains a
--   "p_unwanted_activity" process that does:
--
--       wait for std.env.resolution_limit;
--
--   to advance simulation by exactly one resolution step so that all time-0
--   delta cycles settle before it reads a signal that was just registered
--   (entry_num_in_vvc_activity_register). The same construct is used as the
--   default value of many VVC timeout parameters.
--
--   For this idiom to work, resolution_limit MUST return a positive time.
--   A simulator that returns zero or a negative value breaks UVVM at time 0:
--   "wait for <=0" either does not defer at all (stale read -> TB_ERROR) or
--   raises a "negative time value in wait statement" error. Vivado xsim has
--   been observed to return a non-positive value (e.g. -12 ps) here.
--
--   This test does NOT merely check that the function is callable — it
--   asserts that the returned value is strictly positive, which is the
--   property UVVM actually depends on.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity uvvm_resolution_limit_tb is
end entity;

architecture test of uvvm_resolution_limit_tb is
begin

  stim_proc : process
    constant C_RES : delay_length := resolution_limit;
  begin
    report "==============================================" severity note;
    report "TEST: std.env.resolution_limit returns positive time" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;
    report "  resolution_limit = " & time'image(C_RES) severity note;

    -- The property UVVM depends on: the resolution limit is strictly positive.
    if C_RES > 0 fs then
      report "PASS: resolution_limit is positive (" & time'image(C_RES) & ")" severity note;
      stop(0);
    else
      report "FAIL: resolution_limit must be > 0 but was " & time'image(C_RES) &
             " - 'wait for std.env.resolution_limit' (UVVM p_unwanted_activity) breaks"
        severity error;
      stop(1);
    end if;
    wait;
  end process;

end architecture;
