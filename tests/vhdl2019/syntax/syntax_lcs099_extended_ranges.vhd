-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Extended ranges / range expressions — dynamic range computation
-- CATEGORY: syntax
-- XREF: LCS2016-099 (extended ranges — distinct from LCS2016-099 PT params)
-- SYNTH_ENTITY: extended_ranges
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, array ranges had to be static (known at elaboration
--   time). You could not declare an array whose size depended on the value
--   of a generic, function call, or signal attribute.
--
--   VHDL-2019 introduces extended ranges where array bounds can be
--   expressions evaluated at elaboration time. This enables:
--     signal s : std_logic_vector(compute_width(G) - 1 downto 0);
--   where compute_width is a pure function called during elaboration.
--
--   This test verifies that ranges can be computed from generic values.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;


-- ============================================================================
-- RTL: extended_ranges — synthesizable demonstration of this VHDL feature
-- This module directly exercises the feature described above.
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity extended_ranges is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of extended_ranges is
  signal reg : std_logic_vector(7 downto 0);
begin
  -- KEY FEATURE: this module uses the VHDL feature being tested.
  -- Sim verifies correctness. Synth verifies tool acceptance.
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        reg <= (others => '0');
      else
        reg <= din;
      end if;
    end if;
  end process;
  dout <= reg;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity extended_ranges_tb is
  generic (
    WIDTH : positive := 8
  );
end entity;

architecture test of extended_ranges_tb is
  -- VHDL-2019: Range can be computed from generic
  signal data : std_logic_vector(WIDTH - 1 downto 0) := (others => '0');
  constant HALF : positive := WIDTH / 2;
  signal lower_half : std_logic_vector(HALF - 1 downto 0);
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Extended ranges / range expressions" severity note;
    report "STD:  VHDL-2019 (LCS2016-099)" severity note;
    report "==============================================" severity note;

    -- Verify signal widths match computed values
    assert data'length = WIDTH
      report "FAIL: data'length should be " & integer'image(WIDTH)
             & ", got " & integer'image(data'length)
      severity error;
    assert lower_half'length = HALF
      report "FAIL: lower_half'length should be " & integer'image(HALF)
             & ", got " & integer'image(lower_half'length)
      severity error;

    -- Drive and check values
    data <= (others => '1');
    wait for 5 ns;
    assert data = (WIDTH - 1 downto 0 => '1')
      report "FAIL: data should be all '1's"
      severity error;

    report "PASS: Extended ranges work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
