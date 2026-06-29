-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Unconstrained arrays of unconstrained vectors — UVVM data type pattern
-- CATEGORY: uvvm
-- SYNTH_ENTITY: uvvm_unconstrained_array
-- TEST_TYPE: both
-- DESCRIPTION:
--   UVVM uses generic VVC (VHDL Verification Component) packages that define
--   array types whose elements are themselves unconstrained arrays. This
--   pattern is critical for UVVM's t_generic_package, which passes dynamic
--   data structures through the verification hierarchy.
--
--   Specifically, this test defines:
--     type slv_array is array (natural range <>) of std_logic_vector;
--
--   where std_logic_vector is unconstrained. Each element can have a
--   different width — they're only constrained at instantiation.
--
--   Vivado xsim is known to throw XSIM 43-4187 on this pattern, making
--   it the single most commonly cited blocker for UVVM on xsim.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;

-- ============================================================================
-- Package: uvvm_types_pkg
-- Defines the unconstrained-array-of-unconstrained-vectors pattern
-- that UVVM uses for generic data types.
-- ============================================================================
package uvvm_types_pkg is

  -- KEY FEATURE: array of unconstrained vectors
  -- Each element of slv_array is a std_logic_vector of potentially
  -- different width. UVVM uses this for t_generic_package.
  type slv_array is array (natural range <>) of std_logic_vector;

  -- A record containing an unconstrained array
  type data_record is record
    id   : natural;
    data : std_logic_vector;
  end record;

  type data_record_array is array (natural range <>) of data_record;

end package;


-- ============================================================================
-- RTL: unconstrained arrays of unconstrained vectors
-- Demonstrates synthesizable usage of the UVVM data type pattern.
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.uvvm_types_pkg.all;

entity uvvm_unconstrained_array is
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    sel   : in  natural range 0 to 3;
    -- KEY FEATURE: unconstrained array port — elements constrained at
    -- instantiation to 8 bits each
    arr   : in  slv_array(0 to 3)(7 downto 0);
    dout  : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of uvvm_unconstrained_array is
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        dout <= (others => '0');
      else
        -- Index into the unconstrained-array-of-vectors
        dout <= arr(sel);
      end if;
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.uvvm_types_pkg.all;

entity uvvm_unconstrained_array_tb is
end entity;

architecture test of uvvm_unconstrained_array_tb is

  -- KEY FEATURE: array of unconstrained vectors, constrained at declaration
  signal tb_arr : slv_array(0 to 3)(7 downto 0) := (
    0 => x"AA",
    1 => x"BB",
    2 => x"CC",
    3 => x"DD"
  );

  signal tb_sel  : natural range 0 to 3 := 0;

  signal tb_clk  : std_logic := '0';
  signal tb_rst  : std_logic := '1';
  signal tb_dout : std_logic_vector(7 downto 0);

  constant CLK_PERIOD : time := 10 ns;
begin

  tb_clk <= not tb_clk after CLK_PERIOD / 2;

  -- DUT instantiation with constrained array elements (8 bits each)
  uut: entity work.uvvm_unconstrained_array
    port map (
      clk  => tb_clk,
      rst  => tb_rst,
      sel  => tb_sel,
      arr  => tb_arr,
      dout => tb_dout
    );

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Unconstrained arrays of unconstrained vectors" severity note;
    report "STD:  VHDL-2008 (UVVM pattern)" severity note;
    report "==============================================" severity note;

    -- Reset
    tb_rst <= '1';
    wait for CLK_PERIOD * 2;
    tb_rst <= '0';
    wait for CLK_PERIOD;

    -- Test that we can index into the unconstrained array
    tb_sel <= 0;
    wait for CLK_PERIOD;
    assert tb_dout = x"AA"
      report "FAIL: arr(0) = " & to_hstring(tb_dout) & ", expected AA"
      severity failure;
    report "PASS: arr(0) = " & to_hstring(tb_dout) & " (expected AA)" severity note;

    tb_sel <= 1;
    wait for CLK_PERIOD;
    assert tb_dout = x"BB"
      report "FAIL: arr(1) = " & to_hstring(tb_dout) & ", expected BB"
      severity failure;
    report "PASS: arr(1) = " & to_hstring(tb_dout) & " (expected BB)" severity note;

    tb_sel <= 2;
    wait for CLK_PERIOD;
    assert tb_dout = x"CC"
      report "FAIL: arr(2) = " & to_hstring(tb_dout) & ", expected CC"
      severity failure;
    report "PASS: arr(2) = " & to_hstring(tb_dout) & " (expected CC)" severity note;

    tb_sel <= 3;
    wait for CLK_PERIOD;
    assert tb_dout = x"DD"
      report "FAIL: arr(3) = " & to_hstring(tb_dout) & ", expected DD"
      severity failure;
    report "PASS: arr(3) = " & to_hstring(tb_dout) & " (expected DD)" severity note;

    report "PASS: Unconstrained array of unconstrained vectors test passed" severity note;

    assert false
      report "PASS: End of test"
      severity failure;
    wait;
  end process;

end architecture;

-- TAKEAWAY: The type "array (natural range <>) of std_logic_vector" is a
-- VHDL-2008 feature that UVVM depends on for generic data packages.
-- Vivado xsim is known to fail on this pattern (XSIM 43-4187).
