-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: rising_edge / falling_edge for boolean signals
-- CATEGORY: misc
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2008, the edge-detection functions rising_edge() and
--   falling_edge() were defined only for std_logic (in std_logic_1164)
--   and bit (in standard). You could not use them on boolean signals.
--
--   VHDL-2008 extends rising_edge() and falling_edge() to boolean:
--     rising_edge(b)  — true when b changes from false to true
--     falling_edge(b) — true when b changes from true to false
--
--   This is useful for event-driven testbench code where conditions
--   are naturally expressed as booleans (e.g., "when enable becomes true").
--
--   This test creates a boolean signal, toggles it, and verifies edge
--   detection.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity boolean_edge_tb is
end entity;

architecture test of boolean_edge_tb is
  signal bool_sig : boolean := false;
  signal rose_detected : boolean := false;
  signal fell_detected : boolean := false;
begin

  -- Edge detection processes
  rose_check : process(bool_sig)
  begin
    if rising_edge(bool_sig) then
      rose_detected <= true;
    end if;
  end process;

  fell_check : process(bool_sig)
  begin
    if falling_edge(bool_sig) then
      fell_detected <= true;
    end if;
  end process;

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: rising_edge / falling_edge for boolean" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    wait for 5 ns;

    -- Rising edge: false -> true
    bool_sig <= true;
    wait for 5 ns;
    assert rose_detected = true
      report "FAIL: rising_edge should detect false->true transition"
      severity error;

    -- Falling edge: true -> false
    bool_sig <= false;
    wait for 5 ns;
    assert fell_detected = true
      report "FAIL: falling_edge should detect true->false transition"
      severity error;

    report "PASS: rising_edge/falling_edge for boolean work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
