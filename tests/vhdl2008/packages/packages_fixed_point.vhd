-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Fixed-point package (fixed_pkg) — IEEE 1076.3 fixed-point arithmetic
-- CATEGORY: packages
-- SYNTH_ENTITY: fixed_point
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, there was no standard fixed-point type. DSP and
--   filter designers had to use integer arithmetic with manual scaling
--   (error-prone) or use third-party libraries.
--
--   VHDL-2008 incorporates IEEE 1076.3 which defines:
--     fixed_pkg  — ufixed (unsigned fixed) and sfixed (signed fixed) types
--     float_pkg  — float type (IEEE 754)
--
--   Fixed-point types have a specified range and resolution:
--     signal x : ufixed(3 downto -4);  -- 4 integer bits, 4 fractional bits
--   The value is integer_part * 2^fractional_bits resolution.
--
--   This test verifies basic ufixed/sfixed declaration, assignment,
--   arithmetic, and comparison.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.fixed_pkg.all;
use std.env.all;


-- ============================================================================
-- RTL: fixed-point arithmetic — ufixed/sfixed from ieee.fixed_pkg
-- VHDL-2008: ufixed(3 downto -4) = 4 integer + 4 fractional bits
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.fixed_pkg.all;

entity fixed_point is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of fixed_point is
  signal a : ufixed(3 downto -4);
begin
  -- KEY FEATURE: ufixed type — fixed-point with 4 integer + 4 fractional bits
  process(clk)
  begin
    if rising_edge(clk) then
      a <= to_ufixed(din, 3, -4);  -- convert slv to ufixed
      dout <= to_slv(resize(a * to_ufixed(1.5, 3, -4), 7, 0));
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.fixed_pkg.all;
use std.env.all;

entity fixed_point_tb is
end entity;

architecture test of fixed_point_tb is
  -- VHDL-2008: Fixed-point types from fixed_pkg
  -- ufixed(3 downto -4): 4 integer bits, 4 fractional bits
  -- Range: 0 to 15.9375, resolution: 0.0625
  signal a : ufixed(3 downto -4) := to_ufixed(2.5, 3, -4);
  signal b : ufixed(3 downto -4) := to_ufixed(1.25, 3, -4);
  signal sum : ufixed(3 downto -4);
  signal prod : ufixed(7 downto -8);  -- wider for multiplication

  -- signed fixed: -8 to +7.9375
  signal sa : sfixed(3 downto -4) := to_sfixed(-2.5, 3, -4);
  signal sb : sfixed(3 downto -4) := to_sfixed(1.25, 3, -4);
  signal ssum : sfixed(3 downto -4);
begin

  -- Fixed-point arithmetic
  sum  <= a + b;
  prod <= a * b;
  ssum <= sa + sb;

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Fixed-point package (fixed_pkg)" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    wait for 5 ns;

    -- Verify addition: 2.5 + 1.25 = 3.75
    assert sum = to_ufixed(3.75, 3, -4)
      report "FAIL: 2.5 + 1.25 should be 3.75"
      severity error;

    -- Verify multiplication: 2.5 * 1.25 = 3.125
    assert prod = to_ufixed(3.125, 7, -8)
      report "FAIL: 2.5 * 1.25 should be 3.125"
      severity error;

    -- Verify signed addition: -2.5 + 1.25 = -1.25
    assert ssum = to_sfixed(-1.25, 3, -4)
      report "FAIL: -2.5 + 1.25 should be -1.25"
      severity error;

    -- Verify initial values
    assert a = to_ufixed(2.5, 3, -4)
      report "FAIL: a should be 2.5"
      severity error;

    report "PASS: Fixed-point package works correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
