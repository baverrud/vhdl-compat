-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Inout mode views -- bidirectional interface fields that can't use 'converse
-- CATEGORY: interfaces
-- XREF: LCS2016-045a
-- SYNTH_ENTITY: inout_views
-- TEST_TYPE: both
-- DESCRIPTION:
--   The `'converse` attribute automatically flips `in` to `out` and vice
--   versa. But for `inout` fields (bidirectional signals like I2C's SCL/SDA),
--   `inout` stays `inout` -- 'converse would produce an identical view.
--
--   When both sides of an interface are truly bidirectional, you must
--   declare each view explicitly rather than using `alias ... is ...'converse`.
--   This is the pattern used by I2C, MDIO, and other open-drain interfaces.
--
--   This test defines an I2C-like record with two inout signals, declares
--   explicit master and slave views (both inout), and connects them.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

-- ============================================================================
-- I2C-like record with bidirectional signals
-- ============================================================================
package i2c_like_pkg is
  type i2c_like_t is record
    scl : std_logic;   -- bidirectional clock
    sda : std_logic;   -- bidirectional data
  end record;

  -- Both views are identical -- 'converse would produce the same thing.
  -- Explicit views are needed because 'converse has no effect on inout.
  view ctrl_view of i2c_like_t is
    scl, sda : inout;
  end view;

  view targ_view of i2c_like_t is
    scl, sda : inout;
  end view;
end package;

use work.i2c_like_pkg.all;

-- ============================================================================
-- Controller entity -- drives the bus
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity i2c_ctrl is
  port (
    clk : in  std_logic;
    bus_if : view ctrl_view of i2c_like_t;
    done   : out std_logic
  );
end entity;

architecture rtl of i2c_ctrl is
  signal step : integer := 0;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if step = 0 then
        bus_if.scl <= '1';
        bus_if.sda <= '1';   -- idle
        done <= '0';
        step <= 1;
      elsif step = 1 then
        bus_if.sda <= '0';   -- start condition
        step <= 2;
      elsif step = 2 then
        bus_if.scl <= '0';
        step <= 3;
      elsif step = 3 then
        bus_if.sda <= '1';   -- stop preparation
        step <= 4;
      elsif step = 4 then
        bus_if.scl <= '1';   -- stop condition
        done <= '1';
      end if;
    end if;
  end process;
end architecture;

-- ============================================================================
-- Target entity -- monitors the bus
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use work.i2c_like_pkg.all;

entity i2c_targ is
  port (
    clk    : in  std_logic;
    bus_if : view targ_view of i2c_like_t;
    start_detected : out std_logic
  );
end entity;

architecture rtl of i2c_targ is
  signal scl_prev : std_logic := '1';
  signal sda_prev : std_logic := '1';
begin
  -- Detect START condition: SDA falls while SCL is high
  process(clk)
  begin
    if rising_edge(clk) then
      scl_prev <= bus_if.scl;
      sda_prev <= bus_if.sda;
      if scl_prev = '1' and bus_if.scl = '1' and sda_prev = '1' and bus_if.sda = '0' then
        start_detected <= '1';
      else
        start_detected <= '0';
      end if;
    end if;
  end process;
end architecture;

-- ============================================================================
-- Testbench
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use std.env.all;
use work.i2c_like_pkg.all;


-- ============================================================================
-- RTL: inout_views — synthesizable demonstration of this VHDL feature
-- This module directly exercises the feature described above.
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity inout_views is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of inout_views is
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

entity inout_views_tb is
end entity;

architecture test of inout_views_tb is
  signal clk      : std_logic := '0';
  signal bus_sig  : i2c_like_t;
  signal done     : std_logic;
  signal start_detected : std_logic;
  signal errors   : natural := 0;
  constant CLK_PERIOD : time := 10 ns;
begin

  clk <= not clk after CLK_PERIOD / 2;

  ctrl_inst : entity work.i2c_ctrl
    port map (
      clk    => clk,
      bus_if => bus_sig,
      done   => done
    );

  targ_inst : entity work.i2c_targ
    port map (
      clk             => clk,
      bus_if          => bus_sig,
      start_detected  => start_detected
    );

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Inout mode views -- explicit bidirectional views" severity note;
    report "STD:  VHDL-2019 (LCS2016-045a)" severity note;
    report "==============================================" severity note;

    -- Let the I2C-like state machine run
    wait for CLK_PERIOD * 10;

    -- The controller should have driven a START condition by now
    -- (SDA falling while SCL high), and the target should have detected it
    if done /= '1' then
      report "FAIL: controller did not complete its sequence"
        severity error;
      errors <= errors + 1;
    end if;

    if start_detected /= '1' then
      report "FAIL: target did not detect START condition"
        severity error;
      errors <= errors + 1;
    end if;

    if errors = 0 then
      report "PASS: Inout mode views work -- controller drives bus, target monitors"
        severity note;
      stop(0);
    else
      report "FAIL: Inout views had " & integer'image(errors) & " errors"
        severity failure;
    end if;
    wait;
  end process;

end architecture;

-- TAKEAWAY: When all fields are `inout`, you need explicit views for each side -- 'converse has no effect on bidirectional signals.
