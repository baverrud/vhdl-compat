-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Default value of a composite inout port driver — UVVM BFM/VVC interface pattern
-- CATEGORY: uvvm
-- XREF: FT (unconstrained record elements + port default)
-- TEST_TYPE: sim
-- DESCRIPTION:
--   UVVM VVCs expose their DUT interface as a single record port of mode
--   inout, whose element subtypes are VHDL-2008 unconstrained arrays and
--   whose default value comes from an init function, e.g. (bitvis_vip_sbi):
--
--       sbi_vvc_master_if : inout t_sbi_if(addr(...), wdata(...), rdata(...))
--                             := init_sbi_if_signals(GC_ADDR_WIDTH, GC_DATA_WIDTH);
--
--   init_sbi_if_signals sets the "from DUT" members (ready, rdata) to 'Z' so
--   that the DUT / test harness wins the resolution. The VVC then passes the
--   WHOLE record to its BFM as an `inout` subprogram parameter. Per the LRM,
--   that gives the VVC process a driver for EVERY element of the record —
--   including `ready` — even though the BFM only ever READS `ready` and never
--   assigns it. That never-assigned driver must keep the port's default value
--   ('Z'), so a harness assignment `ready <= '1'` resolves to '1' (Z + 1 = 1).
--
--   UVVM's SBI BFM relies on exactly this: it sanity-checks
--   "ready = '1' or ready = '0'" before every access. If the inout port
--   default is not applied to the driver, that driver contributes a forcing
--   value instead of 'Z', the harness '1' collides with it (1 + 0 = 'X'), and
--   the check fails. Vivado xsim has been observed to fail here.
--
--   This test reproduces the pattern minimally: a record with an unconstrained
--   element, an inout port defaulted via an init function, a BFM that only
--   reads the 'ready' element but is passed the whole record as `inout`, and a
--   harness that drives 'ready' to '1'. It asserts that 'ready' resolves to '1'
--   — i.e. that the composite inout port default 'Z' reached the driver.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;

-- ----------------------------------------------------------------------------
-- Package: interface record (unconstrained element) + init + BFM procedure
-- ----------------------------------------------------------------------------
package uvvm_ifdrv_pkg is

  type t_if is record
    cs    : std_logic;          -- "to DUT"   — driven by the BFM
    ready : std_logic;          -- "from DUT" — read-only for the BFM
    data  : std_logic_vector;   -- unconstrained (VHDL-2008)
  end record;

  -- Init function used as the inout port's default value.
  function init_if(data_width : natural) return t_if;

  -- BFM: takes the WHOLE record as inout, but only DRIVES cs and READS ready.
  procedure bfm_access(
    signal   sif       : inout t_if;
    variable ready_out : out   std_logic
  );

end package;

package body uvvm_ifdrv_pkg is

  function init_if(data_width : natural) return t_if is
    variable v : t_if(data(data_width - 1 downto 0));
  begin
    v.cs    := '0';                        -- "to DUT" driven low
    v.ready := 'Z';                        -- "from DUT" high-Z so the harness wins
    v.data  := (v.data'range => '0');
    return v;
  end function;

  procedure bfm_access(
    signal   sif       : inout t_if;
    variable ready_out : out   std_logic
  ) is
  begin
    sif.cs    <= '1';                      -- drive a "to DUT" member
    ready_out := sif.ready;                -- ONLY read ready — never drive it
  end procedure;

end package body;

-- ----------------------------------------------------------------------------
-- Child: exposes the interface as an inout record port defaulted via init_if.
-- Its process passes the whole port to the BFM (creating a driver on 'ready').
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.uvvm_ifdrv_pkg.all;

entity uvvm_ifdrv_child is
  generic (data_width : natural := 8);
  port (
    intf : inout t_if(data(data_width - 1 downto 0)) := init_if(data_width)
  );
end entity;

architecture behave of uvvm_ifdrv_child is
begin
  p_bfm : process
    variable v_ready : std_logic;
  begin
    -- Passing the whole record as an inout parameter makes this process hold a
    -- driver for every element, including 'ready', which the BFM never assigns.
    bfm_access(intf, v_ready);
    wait for 5 ns;
    bfm_access(intf, v_ready);
    wait;
  end process;
end architecture;

-- ----------------------------------------------------------------------------
-- Self-checking testbench
-- ----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use std.env.all;
use work.uvvm_ifdrv_pkg.all;

entity uvvm_inout_default_driver_tb is
end entity;

architecture test of uvvm_inout_default_driver_tb is
  signal cs    : std_logic;
  signal ready : std_logic;                       -- no initializer -> 'U'
  signal data  : std_logic_vector(7 downto 0);
begin

  dut : entity work.uvvm_ifdrv_child
    generic map (data_width => 8)
    port map (
      intf.cs    => cs,
      intf.ready => ready,
      intf.data  => data
    );

  -- Test harness drives 'ready' high, exactly like UVVM demo harnesses
  -- (e.g. `ready <= '1';` in uart_vvc_demo_th.vhd).
  ready <= '1';

  check_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: composite inout port default driver value" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    wait for 20 ns;
    report "  resolved ready = '" & std_logic'image(ready) & "'" severity note;

    -- The VVC-side driver on 'ready' must retain the port default 'Z', so the
    -- harness '1' wins: Z + 1 = '1'. If the default is lost, a forcing value
    -- collides with '1' and resolves to 'X'.
    if ready = '1' then
      report "PASS: inout port default 'Z' reached the driver (Z + 1 = 1)" severity note;
      stop(0);
    else
      report "FAIL: composite inout port default not applied - ready='" &
             std_logic'image(ready) & "' (expected '1'). Driver conflicts with harness '1'."
        severity error;
      stop(1);
    end if;
    wait;
  end process;

end architecture;
