-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: others => in record aggregates — shorthand for unmentioned record fields
-- CATEGORY: aggregates
-- SYNTH_ENTITY: others_record
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, record aggregates had to specify every field
--   explicitly. You could not use `others =>` to fill in the remaining
--   fields with a default value. This was verbose for records with many
--   fields where most had the same default.
--
--   VHDL-2008 allows `others =>` in record aggregates for the fields
--   not explicitly named:
--     signal cfg : config_t;
--     cfg <= (enable => '1', others => '0');
--
--   This is the record equivalent of `others =>` in array aggregates.
--   This test verifies `others =>` works in record aggregates.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity others_record_tb is
end entity;

architecture test of others_record_tb is
  -- All-integer record: others => works because all fields share type
  type point3d_t is record
    x : integer;
    y : integer;
    z : integer;
  end record;

  signal pt : point3d_t;
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: others => in record aggregates" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- VHDL-2008: others => fills all unmentioned fields with the given value
    pt <= (x => 10, others => 0);
    wait for 5 ns;

    assert pt.x = 10
      report "FAIL: x should be 10, got " & integer'image(pt.x)
      severity error;
    assert pt.y = 0
      report "FAIL: y should be 0 from others"
      severity error;
    assert pt.z = 0
      report "FAIL: z should be 0 from others"
      severity error;

    -- others with a different value
    pt <= (x => 5, y => 3, others => 99);
    wait for 5 ns;
    assert pt.x = 5 and pt.y = 3
      report "FAIL: named fields not set correctly"
      severity error;
    assert pt.z = 99
      report "FAIL: z should be 99 from others"
      severity error;

    report "PASS: others => in record aggregates works correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
