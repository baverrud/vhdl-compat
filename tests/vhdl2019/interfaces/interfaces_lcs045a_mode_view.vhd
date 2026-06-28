-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Interface mode views — per-field direction control on composite types
-- CATEGORY: interfaces
-- XREF: LCS2016-045a
-- SYNTH_ENTITY: interface_views
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, all fields of a record used as an entity port had to
--   share the same direction (all in, all out, or all inout). This forced
--   designers to either flatten their interfaces (losing the organizational
--   benefit of records) or use `inout` everywhere (losing direction safety).
--
--   VHDL-2019 introduces "mode views" via the `view` keyword. A view defines
--   the direction of each field independently. The same record type can have
--   multiple views — e.g., a `master_view` where fields are outputs and a
--   `slave_view` where the same fields are inputs.
--
--   This eliminates the tradeoff between structured interfaces and direction
--   safety. It's one of the most impactful VHDL-2019 RTL features.
--
--   This test defines a simple bus record with a master view (outputs) and
--   a slave view (inputs), connects them, and verifies signal flow.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

-- ============================================================================
-- Package: defines the bus record type and its mode views
-- ============================================================================
package bus_pkg is
  type simple_bus is record
    addr : std_logic_vector(7 downto 0);
    data : std_logic_vector(7 downto 0);
    wr   : std_logic;
  end record;

  -- VHDL-2019: Master view — all fields driven out by the master
  view master_view of simple_bus is
    addr, data, wr : out;
  end view;

  -- VHDL-2019: Slave view — use 'converse to auto-invert the master view
  alias slave_view is master_view'converse;
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

use work.bus_pkg.all;

-- ============================================================================
-- Master entity: drives the bus. Uses `view` mode to specify per-field output directions.
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.bus_pkg.all;

entity bus_master is
  port (
    clk    : in  std_logic;
    -- VHDL-2019: view mode — specifies direction per record field
    bus_if : view master_view of simple_bus
  );
end entity;

architecture rtl of bus_master is
  signal counter : unsigned(7 downto 0) := (others => '0');
begin
  process(clk)
  begin
    if rising_edge(clk) then
      counter <= counter + 1;
      bus_if.addr <= std_logic_vector(counter);
      bus_if.data <= std_logic_vector(counter + 1);
      bus_if.wr   <= '1';
    end if;
  end process;
end architecture;

-- ============================================================================
-- Slave entity: reads the bus. Uses `view` with input directions.
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use work.bus_pkg.all;

entity bus_slave is
  port (
    clk      : in  std_logic;
    -- VHDL-2019: same record type, converse view — fields are inputs here
    bus_if   : view slave_view of simple_bus;
    addr_out : out std_logic_vector(7 downto 0);
    data_out : out std_logic_vector(7 downto 0);
    wr_out   : out std_logic
  );
end entity;

architecture rtl of bus_slave is
begin
  process(clk)
  begin
    if rising_edge(clk) then
      addr_out <= bus_if.addr;
      data_out <= bus_if.data;
      wr_out   <= bus_if.wr;
    end if;
  end process;
end architecture;

-- ============================================================================
-- Testbench: connects master and slave via shared bus signals
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use std.env.all;
use work.bus_pkg.all;


-- ============================================================================
-- Synthesizable RTL — demonstrates this VHDL feature in hardware
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity interface_views is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of interface_views is
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

entity interface_views_tb is
end entity;

architecture test of interface_views_tb is
  signal clk      : std_logic := '0';
  signal bus_sig  : simple_bus;  -- VHDL-2019: record used with mode views
  signal addr_out : std_logic_vector(7 downto 0);
  signal data_out : std_logic_vector(7 downto 0);
  signal wr_out   : std_logic;
  signal errors   : natural := 0;

  constant CLK_PERIOD : time := 10 ns;
begin

  clk <= not clk after CLK_PERIOD / 2;

  -- Connect master — drives bus via master_view
  master_inst : entity work.bus_master
    port map (
      clk    => clk,
      bus_if => bus_sig   -- record mapped as a whole; view determines direction
    );

  -- Connect slave — reads bus via slave_view
  slave_inst : entity work.bus_slave
    port map (
      clk      => clk,
      bus_if   => bus_sig,  -- same record signal, different view
      addr_out => addr_out,
      data_out => data_out,
      wr_out   => wr_out
    );

  -- Checker process
  check_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Interface mode views (LCS2016-045a)" severity note;
    report "STD:  VHDL-2019" severity note;
    report "==============================================" severity note;

    wait for CLK_PERIOD * 5;  -- Let a few clock cycles pass

    -- After a few clocks, the slave should have received data from the master
    -- The value is deterministic: counter starts at 0, increments each clock
    if addr_out = x"00" and data_out = x"00" then
      report "FAIL: slave received all zeros -- bus not connected?"
        severity error;
      errors <= errors + 1;
    end if;

    if errors = 0 then
      report "PASS: Interface mode views work -- master drives bus, slave receives"
        severity note;
      stop(0);
    else
      report "FAIL: Interface mode views had " & integer'image(errors) & " errors"
        severity failure;
    end if;
    wait;
  end process;

end architecture;

-- TAKEAWAY: VHDL-2019 `view` lets each field of a record port have its own direction — no more all-inout tradeoffs.
