-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: open in aggregates — leave aggregate elements unconnected
-- CATEGORY: aggregates
-- SYNTH_ENTITY: open_aggregates
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, every element in an aggregate had to be specified.
--   You could not leave any element "unconnected" (like `open` in port maps).
--
--   VHDL-2008 allows `open` in aggregates, particularly useful for:
--     - Record aggregates where some fields don't need initialization
--     - Array aggregates with don't-care positions
--
--   Elements left as `open` retain their previous value (for signals)
--   or are left undefined (for variables). This is similar to `open`
--   in port maps.
--
--   This test verifies `open` in record and array aggregates.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity open_aggregates_tb is
end entity;

architecture test of open_aggregates_tb is
  type packet_t is record
    addr : std_logic_vector(7 downto 0);
    data : std_logic_vector(7 downto 0);
    crc  : std_logic_vector(7 downto 0);
  end record;

  signal pkt : packet_t := (addr => X"11", data => X"22", crc => X"33");
  signal vec : std_logic_vector(3 downto 0) := "1111";
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: open in aggregates" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- VHDL-2008: open in record aggregate — leave data and crc unchanged
    pkt <= (addr => X"AB", data => open, crc => open);
    wait for 5 ns;

    -- addr should be updated
    assert pkt.addr = X"AB"
      report "FAIL: addr should be AB, got " & to_string(pkt.addr)
      severity error;

    -- data and crc should retain previous values (X"22", X"33")
    assert pkt.data = X"22"
      report "FAIL: data should retain 22 when open, got " & to_string(pkt.data)
      severity error;
    assert pkt.crc = X"33"
      report "FAIL: crc should retain 33 when open, got " & to_string(pkt.crc)
      severity error;

    -- VHDL-2008: open in array aggregate — leave some bits unchanged
    vec <= (3 downto 2 => '1', 1 downto 0 => open);
    wait for 5 ns;

    -- High bits updated, low bits retain previous value
    assert vec(3 downto 2) = "11"
      report "FAIL: high bits should be 11"
      severity error;
    assert vec(1 downto 0) = "11"   -- retained from "1111"
      report "FAIL: low bits should retain 11 when open"
      severity error;

    report "PASS: open in aggregates works correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
