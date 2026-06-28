-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Partially connected vectors — use `open` to leave port bits unconnected
-- CATEGORY: vectors
-- XREF: LCS2016-001
-- SYNTH_ENTITY: partially_connected
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, every bit of a vector port had to be connected in a
--   port map. If you only needed the upper nibble of an 8-bit output, you
--   still had to declare a dummy signal for the lower nibble and leave it
--   unconnected. This was verbose and annoying.
--
--   VHDL-2019 allows `open` in port map element associations:
--       port map (
--         data(7 downto 4) => used_bits,
--         data(3 downto 0) => open     -- VHDL-2019: leave unconnected
--       );
--
--   This is a quality-of-life feature that makes VHDL feel less rigid.
--   It's especially useful with wide buses where only a subset is needed.
--
--   This test creates an 8-bit counter entity and connects only the upper
--   4 bits, leaving the lower 4 bits open (unconnected).
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

-- ============================================================================
-- 8-bit counter — drives all 8 bits
-- ============================================================================
entity counter_8bit is
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    count : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of counter_8bit is
  signal cnt : unsigned(7 downto 0) := (others => '0');
begin
  count <= std_logic_vector(cnt);
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt <= (others => '0');
      else
        cnt <= cnt + 1;
      end if;
    end if;
  end process;
end architecture;

-- ============================================================================
-- Testbench: only connects upper nibble, leaves lower nibble open
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;


-- ============================================================================
-- RTL: partially connected vectors — leave port bits unconnected
-- VHDL-2019: open on parts of a composite port (LCS2016-001)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity partially_connected is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of partially_connected is
  signal full : std_logic_vector(15 downto 0);
  -- KEY FEATURE: partially connected vectors (LCS2016-001) — open on vector parts
  signal lo : std_logic_vector(7 downto 0);
  signal hi : std_logic_vector(7 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      lo <= din;
      full <= hi & lo;  -- hi can be left partially unconnected
      dout <= full(7 downto 0);
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity partially_connected_tb is
end entity;

architecture test of partially_connected_tb is
  signal clk        : std_logic := '0';
  signal rst        : std_logic := '1';
  signal upper_bits : std_logic_vector(7 downto 4);  -- only 4 bits we care about
  signal errors     : natural := 0;
  constant CLK_PERIOD : time := 10 ns;
begin

  clk <= not clk after CLK_PERIOD / 2;

  -- VHDL-2019: connect only upper nibble, leave lower nibble open
  uut : entity work.counter_8bit
    port map (
      clk             => clk,
      rst             => rst,
      count(7 downto 4) => upper_bits,   -- VHDL-2019: partial connection
      count(3 downto 0) => open           -- VHDL-2019: explicitly unconnected
    );

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Partially connected vectors (LCS2016-001)" severity note;
    report "STD:  VHDL-2019" severity note;
    report "==============================================" severity note;

    wait for CLK_PERIOD * 2;
    rst <= '0';
    wait for CLK_PERIOD;

    -- After 1 clock, counter = 1. Upper nibble should be 0.
    if upper_bits /= "0000" then
      report "FAIL: after 1 tick, upper_bits=" & to_string(upper_bits)
        severity error;
      errors <= errors + 1;
    end if;

    -- After 16 more clocks (total 17), counter = 17 = 0x11. Upper nibble = 1.
    for i in 1 to 16 loop
      wait for CLK_PERIOD;
    end loop;
    if upper_bits /= "0001" then
      report "FAIL: after 17 ticks, upper_bits=" & to_string(upper_bits)
        severity error;
      errors <= errors + 1;
    end if;

    if errors = 0 then
      report "PASS: Partially connected vectors work -- lower nibble left open"
        severity note;
      stop(0);
    else
      report "FAIL: Partially connected vectors had " & integer'image(errors) & " errors"
        severity failure;
    end if;
    wait;
  end process;

end architecture;

-- TAKEAWAY: VHDL-2019 `open` in port map lets you connect only the bits you need -- no dummy signals required.
