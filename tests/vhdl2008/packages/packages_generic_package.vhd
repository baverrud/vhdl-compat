-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Generic packages — packages parameterized by generics
-- CATEGORY: packages
-- SYNTH_ENTITY: generic_package
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, a package was fixed — all its constants, types, and
--   subprograms used hard-coded values. If you wanted a FIFO package that
--   worked for different widths and depths, you had to either:
--     1. Use generics on entities (which works for entities but not packages)
--     2. Copy-paste the package with different values
--
--   VHDL-2008 introduces generic packages. A package can declare generic
--   parameters (like an entity), and each instantiation creates a separate
--   version of the package. This is the package equivalent of a generic entity.
--
--   This test defines a generic package for a simple counter type parameterized
--   by width, instantiates it at two widths, and verifies both work.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

-- ============================================================================
-- Generic package: parameterized by WIDTH
-- ============================================================================
package counter_pkg is
  generic (
    WIDTH : positive := 8
  );
  constant MAX_COUNT : unsigned(WIDTH - 1 downto 0) := (others => '1');
  function increment(cnt : unsigned(WIDTH - 1 downto 0)) return unsigned;
end package;

package body counter_pkg is
  function increment(cnt : unsigned(WIDTH - 1 downto 0)) return unsigned is
  begin
    return cnt + 1;
  end function;
end package body;

-- ============================================================================
-- Instantiate the generic package at two different widths
-- ============================================================================
package counter_4 is new work.counter_pkg
  generic map (WIDTH => 4);

package counter_8 is new work.counter_pkg
  generic map (WIDTH => 8);

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity generic_package_tb is
end entity;

architecture test of generic_package_tb is
  signal cnt4 : unsigned(3 downto 0) := X"0";
  signal cnt8 : unsigned(7 downto 0) := X"00";
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Generic packages" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- Test 4-bit counter package (fully qualified name)
    cnt4 <= work.counter_4.increment(X"5");
    wait for 5 ns;
    assert cnt4 = X"6"
      report "FAIL: counter_4.increment(5) should be 6, got " & to_string(cnt4)
      severity error;

    -- Test 8-bit counter package
    cnt8 <= work.counter_8.increment(X"AB");
    wait for 5 ns;
    assert cnt8 = X"AC"
      report "FAIL: counter_8.increment(AB) should be AC, got " & to_string(cnt8)
      severity error;

    -- Verify MAX_COUNT constants differ between instantiations
    assert work.counter_4.MAX_COUNT = X"F"
      report "FAIL: counter_4.MAX_COUNT should be F"
      severity error;
    assert work.counter_8.MAX_COUNT = X"FF"
      report "FAIL: counter_8.MAX_COUNT should be FF"
      severity error;

    report "PASS: Generic packages work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
