-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Array of interface records -- multiple channels using a single bundle type
-- CATEGORY: interfaces
-- XREF: LCS2016-045a
-- SYNTH_ENTITY: array_of_interfaces
-- TEST_TYPE: both
-- DESCRIPTION:
--   When you have multiple identical interfaces (e.g., 4 SPI slaves, 8 UART
--   channels), you can declare an array of the interface record type:
--       type channel_array is array (natural range <>) of bus_t;
--       signal channels : channel_array(0 to 3);
--
--   Combined with VHDL-2019 mode views, each array element can be connected
--   to a different entity instance, each using its own view. This scales
--   cleanly without copy-pasting port declarations.
--
--   This test creates a 4-channel counter array where each channel is an
--   independent counter, connected via an array of interface records.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

-- ============================================================================
-- Simple 4-bit counter interface
-- ============================================================================
package chan_pkg is
  type chan_t is record
    en   : std_logic;
    data : std_logic_vector(3 downto 0);
  end record;

  view source_view of chan_t is
    en, data : out;
  end view;

  view sink_view of chan_t is
    en, data : in;
  end view;

  type chan_array_t is array (natural range <>) of chan_t;
end package;

use work.chan_pkg.all;

-- ============================================================================
-- Counter source: drives a counting value on its channel
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_source is
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    ch    : view source_view of chan_t
  );
end entity;

architecture rtl of counter_source is
  signal count : unsigned(3 downto 0) := (others => '0');
begin
  ch.data <= std_logic_vector(count);
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        count <= (others => '0');
      else
        count <= count + 1;
      end if;
    end if;
  end process;
  ch.en <= not rst;
end architecture;

-- ============================================================================
-- Counter sink: reads the channel value and outputs it
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use work.chan_pkg.all;

entity counter_sink is
  port (
    clk   : in  std_logic;
    ch    : view sink_view of chan_t;
    val   : out std_logic_vector(3 downto 0);
    valid : out std_logic
  );
end entity;

architecture rtl of counter_sink is
begin
  process(clk)
  begin
    if rising_edge(clk) then
      val   <= ch.data;
      valid <= ch.en;
    end if;
  end process;
end architecture;

-- ============================================================================
-- Testbench: 4 channels via array of interface records
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.chan_pkg.all;

entity array_of_interfaces_tb is
end entity;

architecture test of array_of_interfaces_tb is
  signal clk   : std_logic := '0';
  signal rst   : std_logic := '1';
  signal errors : natural := 0;
  constant CHANNELS : positive := 4;
  constant CLK_PERIOD : time := 10 ns;

  -- VHDL-2019: array of interface records
  signal ch : chan_array_t(0 to CHANNELS - 1);
  type val_array_t is array (0 to CHANNELS - 1) of std_logic_vector(3 downto 0);
  signal vals   : val_array_t;
  signal valids : std_logic_vector(0 to CHANNELS - 1);
begin

  clk <= not clk after CLK_PERIOD / 2;

  -- Generate N sources and sinks using a for-generate
  gen_channels : for i in 0 to CHANNELS - 1 generate
    src : entity work.counter_source
      port map (
        clk => clk,
        rst => rst,
        ch  => ch(i)
      );
    snk : entity work.counter_sink
      port map (
        clk   => clk,
        ch    => ch(i),
        val   => vals(i),
        valid => valids(i)
      );
  end generate;

  stim_proc : process
    procedure check_channel (idx : integer; expected : std_logic_vector) is
    begin
      if vals(idx) /= expected then
        report "FAIL: ch" & integer'image(idx) & " val=" & to_string(vals(idx))
               & " expected " & to_string(expected)
          severity error;
        errors <= errors + 1;
      end if;
    end procedure;
  begin
    report "==============================================" severity note;
    report "TEST: Array of interface records" severity note;
    report "STD:  VHDL-2019 (LCS2016-045a)" severity note;
    report "==============================================" severity note;

    wait for CLK_PERIOD * 2;
    rst <= '0';
    wait for CLK_PERIOD * 2;

    -- Each counter started at 0 and increments. After 2 clocks with rst=0,
    -- they should be at 2.
    for i in 0 to CHANNELS - 1 loop
      check_channel(i, x"2");
    end loop;
    if valids /= "1111" then
      report "FAIL: not all channels valid"
        severity error;
      errors <= errors + 1;
    end if;

    if errors = 0 then
      report "PASS: Array of interface records works -- " & integer'image(CHANNELS) & " channels"
        severity note;
      stop(0);
    else
      report "FAIL: Array of interfaces had " & integer'image(errors) & " errors"
        severity failure;
    end if;
    wait;
  end process;

end architecture;

-- TAKEAWAY: VHDL-2019 interface records can be used in arrays -- connect N identical channels with a for-generate and a single signal array.
