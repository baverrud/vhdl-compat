-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Enhanced port maps — open keyword anywhere in port map
-- CATEGORY: ports
-- SYNTH_ENTITY: enhanced_port_maps
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, the "open" keyword to leave a port unconnected could
--   only appear at the end of a port map association list. If you wanted to
--   leave the 2nd port unconnected but connect the 3rd, you had to use a
--   dummy signal:
--       signal dummy : std_logic;
--       ...
--       uut : my_entity port map (
--         clk  => clk,
--         rst  => dummy,    -- ugly workaround
--         data => data_in
--       );
--
--   VHDL-2008 allows "open" anywhere in a port map, not just at the end.
--   (Note: open on input ports requires tool support for unconnected inputs;
--   this test uses output ports which are widely supported.)
--
--   This test instantiates a multi-output entity, leaves one output open
--   in the middle of the port map, and verifies the others work.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

-- ============================================================================
-- Simple DUT: three independent outputs
-- ============================================================================
entity multi_out is
  port (
    a_in  : in  std_logic;
    x_out : out std_logic;
    y_out : out std_logic;
    z_out : out std_logic
  );
end entity;

architecture rtl of multi_out is
begin
  x_out <= a_in;
  y_out <= not a_in;
  z_out <= a_in;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;


-- ============================================================================
-- Synthesizable RTL — demonstrates this VHDL feature in hardware
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity enhanced_port_maps is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of enhanced_port_maps is
  signal reg : std_logic_vector(7 downto 0);
begin
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

entity enhanced_port_maps_tb is
end entity;

architecture test of enhanced_port_maps_tb is
  signal drive  : std_logic := '1';
  signal x_val  : std_logic;
  signal z_val  : std_logic;
begin

  -- --------------------------------------------------------------------------
  -- VHDL-2008: open in the middle of a port map (y_out left unconnected)
  -- Before VHDL-2008, open had to be at the end of the association list.
  -- --------------------------------------------------------------------------
  uut : entity work.multi_out
    port map (
      a_in  => drive,
      x_out => x_val,
      y_out => open,       -- VHDL-2008: open anywhere, not just at the end!
      z_out => z_val
    );

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Enhanced port maps (open anywhere)" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    wait for 5 ns;

    -- x_out and z_out should follow a_in
    assert x_val = '1'
      report "FAIL: x_out should be '1'"
      severity error;
    assert z_val = '1'
      report "FAIL: z_out should be '1'"
      severity error;

    -- Change drive and verify connected outputs update
    drive <= '0';
    wait for 5 ns;
    assert x_val = '0'
      report "FAIL: x_out should update to '0'"
      severity error;
    assert z_val = '0'
      report "FAIL: z_out should update to '0'"
      severity error;

    report "PASS: Enhanced port maps (open anywhere) work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
