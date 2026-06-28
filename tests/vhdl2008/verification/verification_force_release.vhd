-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Force / Release — override signal values for verification
-- CATEGORY: verification
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2008, overriding a signal value for verification purposes
--   required simulator-specific commands (Tcl force/release in ModelSim).
--   There was no portable way to force a value in pure VHDL.
--
--   VHDL-2008 introduces `force` and `release` as sequential statements
--   for verification:
--     signal_name <= force value;     -- override signal
--     signal_name <= release;          -- release override
--     signal_name <= force in value;  -- force in resolved signal
--     signal_name <= force out value; -- force out of resolved signal
--
--   Force overrides the normal drivers on a signal. Release restores them.
--   This is a simulation-only feature (not synthesizable).
--
--   This test forces a counter output to a specific value, verifies it
--   takes effect, then releases it and verifies normal operation resumes.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity force_release_tb is
end entity;

architecture test of force_release_tb is
  signal clk   : std_logic := '0';
  signal rst   : std_logic := '1';
  signal count : unsigned(3 downto 0) := X"0";
  constant CLK_PERIOD : time := 10 ns;
begin

  -- Clock generator
  clk_proc : process
  begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;
  end process;

  -- Simple counter as DUT
  counter_proc : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        count <= X"0";
      else
        count <= count + 1;
      end if;
    end if;
  end process;

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Force / Release" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- Let the counter run normally for a few cycles
    rst <= '1';
    wait for CLK_PERIOD * 2;
    rst <= '0';
    wait for CLK_PERIOD * 3;

    -- Counter should be at 3 now
    assert count = 3
      report "FAIL: count should be 3 before force, got " & to_string(count)
      severity error;

    -- VHDL-2008: Force the counter to a specific value
    count <= force X"F";
    wait for CLK_PERIOD;

    -- Counter should stay at F despite clock edges
    assert count = X"F"
      report "FAIL: force should hold count at F, got " & to_string(count)
      severity error;

    wait for CLK_PERIOD * 2;
    assert count = X"F"
      report "FAIL: force should persist across clock edges"
      severity error;

    -- VHDL-2008: Release the force — normal operation resumes
    count <= release;
    wait for CLK_PERIOD;

    -- Counter resumes from where it was forced
    assert count = X"0"   -- F + 1 wraps to 0
      report "FAIL: after release, count should resume (F+1=0), got " & to_string(count)
      severity error;

    report "PASS: Force / Release works correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
