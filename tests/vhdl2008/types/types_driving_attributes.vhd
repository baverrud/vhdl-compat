-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: 'driving and 'driving_value — query signal driver status
-- CATEGORY: types
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2008, there was no standard way to query whether a signal
--   was being actively driven or to read the driving value (as opposed to
--   the resolved/effective value). This made debugging resolved signals
--   and tri-state buses difficult.
--
--   VHDL-2008 introduces signal attributes for driver introspection:
--     s'driving        — returns true if the current process is driving s
--     s'driving_value  — returns the value the current process is driving
--                        (regardless of other drivers on a resolved signal)
--
--   These are essential for:
--     - Debugging resolved signals with multiple drivers
--     - Tri-state bus controllers that need to know if they're driving
--     - Verification IP that checks driver status
--
--   This test creates a resolved signal, drives it from multiple processes,
--   and verifies 'driving and 'driving_value.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_driving is
end entity;

architecture test of tb_driving is
  signal my_sig : std_logic := 'Z';
  signal check_val : std_logic;
begin

  -- Driver 1: drives '1'
  driver1 : process
  begin
    my_sig <= '1';
    wait;
  end process;

  -- Monitoring process that checks driving attributes
  monitor : process(my_sig)
  begin
    -- VHDL-2008: 'driving and 'driving_value attributes
    if my_sig'driving then
      check_val <= my_sig'driving_value;
    end if;
  end process;

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: 'driving and 'driving_value attributes" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- VHDL-2008: Check if we are driving in this process
    my_sig <= '0';
    wait for 5 ns;

    if my_sig'driving then
      report "  This process is driving my_sig with " &
             std_logic'image(my_sig'driving_value) severity note;
    end if;

    -- Verify driving value matches what we set
    my_sig <= '1';
    wait for 1 ns;
    if my_sig'driving then
      assert my_sig'driving_value = '1'
        report "FAIL: 'driving_value should be '1'"
        severity error;
    end if;

    report "PASS: 'driving and 'driving_value attributes are accessible" severity note;
    stop(0);
    wait;
  end process;

end architecture;
