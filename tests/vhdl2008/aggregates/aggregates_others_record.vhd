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


-- ============================================================================
-- RTL: others => in record aggregates — assign all remaining fields
-- VHDL-2008: (a=>'1', b=>'0', others=>'0') fills unmentioned fields
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity others_record is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of others_record is
  type rec_t is record
    f0, f1, f2, f3, f4, f5, f6, f7 : std_logic;
  end record;
  signal r : rec_t;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      -- KEY FEATURE: others=>'0' fills all unmentioned record fields
      r <= (f0=>din(0), f1=>din(1), others=>'0');
      dout <= r.f0 & r.f1 & r.f2 & r.f3 & r.f4 & r.f5 & r.f6 & r.f7;
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
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
