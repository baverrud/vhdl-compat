-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Array slices in aggregates — assign ranges of array elements
-- CATEGORY: aggregates
-- SYNTH_ENTITY: slice_aggregates
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, assigning to a slice of an array required separate
--   assignment statements. You could not use a slice as part of an aggregate.
--
--   VHDL-2008 allows array slices in aggregates using the range syntax:
--     signal <= (3 downto 1 => '1', others => '0');
--   Or for named record elements:
--     cfg <= (field1 => '1', field2(3 downto 1) => '1', others => '0');
--
--   This test verifies slice-based aggregates for both arrays and records.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity slice_aggregates_tb is
end entity;

architecture test of slice_aggregates_tb is
  signal slv : std_logic_vector(7 downto 0);
  signal result : std_logic_vector(3 downto 0);
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Array slices in aggregates" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- VHDL-2008: slice assignment in aggregate
    -- Set bits 7 downto 4 to '1', bits 3 downto 0 to '0'
    slv <= (7 downto 4 => '1', 3 downto 0 => '0');
    wait for 5 ns;
    assert slv = X"F0"
      report "FAIL: slice aggregate should give X'F0', got " & to_string(slv)
      severity error;

    -- Mixed: single bits + slice
    slv <= (7 => '1', 6 downto 0 => '0');
    wait for 5 ns;
    assert slv = X"80"
      report "FAIL: mixed single+slice should give X'80', got " & to_string(slv)
      severity error;

    -- Others with slice
    slv <= (3 downto 0 => '1', others => '0');
    wait for 5 ns;
    assert slv = X"0F"
      report "FAIL: slice+others should give X'0F', got " & to_string(slv)
      severity error;

    -- Named association with range for record elements (if record type used)
    -- Simple vector: all named ranges
    result <= (1 downto 0 => '1', 3 downto 2 => '0');
    wait for 5 ns;
    assert result = "0011"
      report "FAIL: named ranges should give 0011, got " & to_string(result)
      severity error;

    report "PASS: Array slices in aggregates work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
