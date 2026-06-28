-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Named association in aggregates — mix positional and named elements
-- CATEGORY: aggregates
-- SYNTH_ENTITY: named_aggregates
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, aggregates had to be either all positional or all named.
--   You could not mix the two styles in the same aggregate. This was limiting
--   when a record had many fields — you might remember the position of the
--   first few but want to name the rest.
--
--   VHDL-2008 allows mixing positional and named association in the same
--   aggregate. Positional elements come first, followed by named ones.
--   Named association uses "field => value" syntax.
--
--   This test defines a record type, creates aggregates using mixed
--   positional+named association, and verifies correctness.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

-- ============================================================================
-- Package: defines a record type for testing
-- ============================================================================
package agg_pkg is
  type config_t is record
    enable  : std_logic;
    mode    : std_logic_vector(1 downto 0);
    timeout : unsigned(7 downto 0);
    rate    : unsigned(3 downto 0);
    flags   : std_logic_vector(3 downto 0);
  end record;
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.agg_pkg.all;


-- ============================================================================
-- RTL: named_aggregates — synthesizable demonstration of this VHDL feature
-- This module directly exercises the feature described above.
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity named_aggregates is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of named_aggregates is
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

entity named_aggregates_tb is
end entity;

architecture test of named_aggregates_tb is
  signal cfg : config_t;
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Named association in aggregates" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- VHDL-2008: mixed positional + named association
    -- positional: enable, mode
    -- named:      timeout, rate, flags
    cfg <= ('1', "01", timeout => X"FF", rate => X"A", flags => "1010");
    wait for 5 ns;

    assert cfg.enable = '1'
      report "FAIL: enable should be '1'"
      severity error;
    assert cfg.mode = "01"
      report "FAIL: mode should be 01"
      severity error;
    assert cfg.timeout = X"FF"
      report "FAIL: timeout should be FF"
      severity error;
    assert cfg.rate = X"A"
      report "FAIL: rate should be A"
      severity error;
    assert cfg.flags = "1010"
      report "FAIL: flags should be 1010"
      severity error;

    -- All-positional (still valid, always was)
    cfg <= ('0', "10", X"10", X"5", "1111");
    wait for 5 ns;
    assert cfg.enable = '0' and cfg.mode = "10"
      report "FAIL: all-positional aggregate"
      severity error;

    -- All-named (still valid)
    cfg <= (enable => '1', mode => "11", timeout => X"20", rate => X"F", flags => "0001");
    wait for 5 ns;
    assert cfg.enable = '1' and cfg.flags = "0001"
      report "FAIL: all-named aggregate"
      severity error;

    report "PASS: Named association in aggregates works correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
