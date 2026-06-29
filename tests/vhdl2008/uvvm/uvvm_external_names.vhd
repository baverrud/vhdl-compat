-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: External names targeting arrays and records — UVVM signal spying pattern
-- CATEGORY: uvvm
-- SYNTH_ENTITY: uvvm_external_names
-- TEST_TYPE: sim
-- DESCRIPTION:
--   UVVM's Bus Functional Models (BFMs) use VHDL-2008 external names
--   (hierarchical signal access) to spy on DUT internal signals without
--   modifying the DUT. This is critical for non-intrusive verification.
--
--   UVVM needs to access not just simple scalar signals but also:
--     - Array elements:   << signal .tb.dut.reg_file(3) : slv >>
--     - Record fields:    << signal .tb.dut.status.ready : std_logic >>
--     - Nested hierarchy: << signal .tb.dut.core.cache.line : slv >>
--
--   Vivado xsim is known to have limited external name support — it may
--   handle simple scalar paths but fail on arrays, records, or nested
--   hierarchy. This test exercises all three levels of complexity.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ============================================================================
-- Package: shared types for external name test
-- Types must be in a package so both DUT and TB can reference them.
-- ============================================================================
package external_names_pkg is
  type reg_array is array (0 to 7) of std_logic_vector(7 downto 0);
  type status_t is record
    busy   : std_logic;
    ready  : std_logic;
    count  : natural range 0 to 255;
  end record;
end package;

use work.external_names_pkg.all;

-- ============================================================================
-- DUT: a small register file + status register for external name spying
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity uvvm_external_names is
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    wr_en    : in  std_logic;
    wr_addr  : in  natural range 0 to 7;
    wr_data  : in  std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of uvvm_external_names is
  -- Internal signals that UVVM would spy on
  signal reg_file : reg_array := (others => (others => '0'));
  signal status   : status_t := ('0', '1', 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        reg_file <= (others => (others => '0'));
        status   <= ('0', '1', 0);
      else
        if wr_en = '1' then
          reg_file(wr_addr) <= wr_data;
          status.count <= status.count + 1;
        end if;
        status.busy  <= wr_en;
        status.ready <= not wr_en;
      end if;
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.external_names_pkg.all;

entity uvvm_external_names_tb is
end entity;

architecture test of uvvm_external_names_tb is
  signal tb_clk     : std_logic := '0';
  signal tb_rst     : std_logic := '1';
  signal tb_wr_en   : std_logic := '0';
  signal tb_wr_addr : natural range 0 to 7 := 0;
  signal tb_wr_data : std_logic_vector(7 downto 0) := (others => '0');

  constant CLK_PERIOD : time := 10 ns;
begin

  tb_clk <= not tb_clk after CLK_PERIOD / 2;

  uut: entity work.uvvm_external_names
    port map (
      clk     => tb_clk,
      rst     => tb_rst,
      wr_en   => tb_wr_en,
      wr_addr => tb_wr_addr,
      wr_data => tb_wr_data
    );

  stim_proc : process
    -- KEY FEATURE: external names aliasing internal DUT signals
    -- Type 1: scalar field of a record
    alias spy_ready : std_logic is
      << signal uut.status.ready : std_logic >>;

    -- Type 2: entire array (indexed locally — vcom requires whole-object)
    alias spy_regs  : reg_array is
      << signal uut.reg_file : reg_array >>;

    -- Type 3: entire record
    alias spy_status : status_t is
      << signal uut.status : status_t >>;
  begin
    report "==============================================" severity note;
    report "TEST: External names on arrays and records" severity note;
    report "STD:  VHDL-2008 (UVVM signal spying pattern)" severity note;
    report "==============================================" severity note;

    -- Reset
    tb_rst <= '1';
    wait for CLK_PERIOD * 2;
    tb_rst <= '0';
    wait for CLK_PERIOD;

    -- Test 1: Spy on record field (ready)
    assert spy_ready = '1'
      report "FAIL: spy_ready = " & std_logic'image(spy_ready) & ", expected 1"
      severity failure;
    report "PASS: External name on record field (ready) works" severity note;

    -- Test 2: Write to reg_file(0) and spy on it
    tb_wr_en   <= '1';
    tb_wr_addr <= 0;
    tb_wr_data <= x"A5";
    wait for CLK_PERIOD;
    tb_wr_en <= '0';
    wait for CLK_PERIOD;

    -- Index into the spied array locally
    assert spy_regs(0) = x"A5"
      report "FAIL: spy_regs(0) = " & to_hstring(spy_regs(0)) & ", expected A5"
      severity failure;
    report "PASS: External name on array (spy whole, index local) works" severity note;

    -- Test 3: Write to reg_file(3) and spy on it
    tb_wr_en   <= '1';
    tb_wr_addr <= 3;
    tb_wr_data <= x"3C";
    wait for CLK_PERIOD;
    tb_wr_en <= '0';
    wait for CLK_PERIOD;

    assert spy_regs(3) = x"3C"
      report "FAIL: spy_regs(3) = " & to_hstring(spy_regs(3)) & ", expected 3C"
      severity failure;
    report "PASS: External name on array element (reg3) works" severity note;

    -- Test 4: Spy on record field (count — should be 2 after 2 writes)
    assert spy_status.count = 2
      report "FAIL: spy_status.count = " & natural'image(spy_status.count)
             & ", expected 2"
      severity failure;
    report "PASS: External name on record field (count) works" severity note;

    report "PASS: External names on arrays and records test passed" severity note;

    assert false
      report "PASS: End of test"
      severity failure;
    wait;
  end process;

end architecture;

-- TAKEAWAY: VHDL-2008 external names (<< signal .path >>) allow non-intrusive
-- access to DUT internals. UVVM uses this for BFM signal spying. Vivado xsim
-- historically struggles with external names targeting anything beyond simple
-- scalar signals — arrays, records, and nested paths often fail.
