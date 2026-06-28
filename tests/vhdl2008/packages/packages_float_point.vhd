-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Floating-point package (float_pkg) — IEEE 754 floating-point types
-- CATEGORY: packages
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2008, the only floating-point type was REAL, which is not
--   synthesizable and has no bit-level representation. For hardware floating
--   point, designers used custom VHDL or third-party IP.
--
--   VHDL-2008 incorporates IEEE 1076.3 which defines float_pkg with IEEE 754
--   compliant floating-point types:
--     float32  — single precision (1 sign, 8 exponent, 23 mantissa)
--     float64  — double precision
--     float128 — quad precision
--
--   These types have a defined bit representation, can be synthesized,
--   and support standard arithmetic, comparison, and conversion to/from
--   std_logic_vector for register-level access.
--
--   This test verifies float32 declaration, conversion, and basic arithmetic.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.float_pkg.all;
use std.env.all;

entity tb_float_point is
end entity;

architecture test of tb_float_point is
  -- VHDL-2008: IEEE 754 single-precision float
  signal a : float32 := to_float(2.5);
  signal b : float32 := to_float(1.5);
  signal sum : float32;
  signal prod : float32;
begin

  sum  <= a + b;
  prod <= a * b;

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Floating-point package (float_pkg)" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    wait for 5 ns;

    -- Verify addition: 2.5 + 1.5 = 4.0
    assert sum = to_float(4.0)
      report "FAIL: 2.5 + 1.5 should be 4.0"
      severity error;

    -- Verify multiplication: 2.5 * 1.5 = 3.75
    assert prod = to_float(3.75)
      report "FAIL: 2.5 * 1.5 should be 3.75"
      severity error;

    -- Verify we can convert to std_logic_vector (bit-level access)
    assert to_slv(a)'length = 32
      report "FAIL: float32 should be 32 bits"
      severity error;

    -- Comparison
    assert (a < b) = false
      report "FAIL: 2.5 should not be < 1.5"
      severity error;

    report "PASS: Floating-point package works correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
