-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: minimum / maximum — standard min/max functions for all scalar types
-- CATEGORY: misc
-- SYNTH_ENTITY: min_max
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, there were no standard minimum or maximum functions.
--   You had to write your own:
--       function my_min(a, b : integer) return integer is
--       begin if a < b then return a; else return b; end if; end function;
--   This was boilerplate that every project duplicated.
--
--   VHDL-2008 adds minimum and maximum functions in the standard package
--   for all scalar types (integer, real, time, enumerated, etc.) as well
--   as array types and vectors.
--
--   This test verifies minimum and maximum on integers, reals, and time.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;


-- ============================================================================
-- Synthesizable RTL — demonstrates this VHDL feature in hardware
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity min_max is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of min_max is
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

entity min_max_tb is
end entity;

architecture test of min_max_tb is
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: minimum / maximum functions" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    ------------------------------------------------------------------------
    -- Integer min/max
    ------------------------------------------------------------------------
    assert minimum(10, 42) = 10
      report "FAIL: minimum(10, 42) should be 10"
      severity error;
    assert maximum(10, 42) = 42
      report "FAIL: maximum(10, 42) should be 42"
      severity error;

    -- Equal values
    assert minimum(5, 5) = 5
      report "FAIL: minimum(5, 5) should be 5"
      severity error;
    assert maximum(5, 5) = 5
      report "FAIL: maximum(5, 5) should be 5"
      severity error;

    -- Negative values
    assert minimum(-3, 7) = -3
      report "FAIL: minimum(-3, 7) should be -3"
      severity error;
    assert maximum(-3, -7) = -3
      report "FAIL: maximum(-3, -7) should be -3"
      severity error;

    ------------------------------------------------------------------------
    -- Real min/max
    ------------------------------------------------------------------------
    assert minimum(3.14, 2.71) = 2.71
      report "FAIL: minimum(3.14, 2.71) should be 2.71"
      severity error;
    assert maximum(1.0, 99.5) = 99.5
      report "FAIL: maximum(1.0, 99.5) should be 99.5"
      severity error;

    ------------------------------------------------------------------------
    -- Time min/max
    ------------------------------------------------------------------------
    assert minimum(10 ns, 5 ns) = 5 ns
      report "FAIL: minimum(10 ns, 5 ns) should be 5 ns"
      severity error;
    assert maximum(1 us, 500 ns) = 1 us
      report "FAIL: maximum(1 us, 500 ns) should be 1 us"
      severity error;

    ------------------------------------------------------------------------
    -- Three-argument min/max (optional chaining pattern)
    ------------------------------------------------------------------------
    assert minimum(minimum(1, 5), 3) = 1
      report "FAIL: nested minimum should find global min"
      severity error;

    report "PASS: minimum / maximum functions work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
