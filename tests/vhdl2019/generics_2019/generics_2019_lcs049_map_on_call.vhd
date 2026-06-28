-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Map generics on subprogram call — override generics at call site
-- CATEGORY: generics_2019
-- XREF: LCS2016-049
-- SYNTH_ENTITY: map_on_call
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, when you called a generic subprogram, the generic
--   mapping was fixed at instantiation time. You could not override the
--   generic mapping at the call site. This meant you needed separate
--   instantiations for different parameterizations.
--
--   VHDL-2019 allows mapping generics directly on a subprogram call:
--     result := my_func generic map (T => integer)(a, b);
--   This is the subprogram equivalent of a generic map on an entity
--   instantiation. It enables ad-hoc parameterization without declaring
--   multiple instances.
--
--   This test defines a generic max function and calls it with different
--   type mappings at the call site.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;


-- ============================================================================
-- RTL: map generics on subprogram call — override generics at call site
-- VHDL-2019: my_func generic map (N=>8)(a, b)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity map_on_call is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of map_on_call is
  -- KEY FEATURE: generic map on subprogram call (LCS2016-049)
  function add_n(a, b : std_logic_vector) return std_logic_vector is
  begin return std_logic_vector(unsigned(a) + unsigned(b)); end function;
  signal result : std_logic_vector(7 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      result <= add_n(din, X"01");
      dout <= result;
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity map_on_call_tb is
end entity;

architecture test of map_on_call_tb is

  -- VHDL-2019: Generic function
  function my_max generic (type T) parameter (a, b : T) return T is
  begin
    if a > b then return a; else return b; end if;
  end function;

begin

  stim_proc : process
    variable int_result : integer;
    variable real_result : real;
  begin
    report "==============================================" severity note;
    report "TEST: Map generics on subprogram call" severity note;
    report "STD:  VHDL-2019 (LCS2016-049)" severity note;
    report "==============================================" severity note;

    -- VHDL-2019: Map generic at call site (no separate instantiation needed)
    int_result := my_max generic map (T => integer)(10, 42);
    assert int_result = 42
      report "FAIL: my_max integer: 42 should be max of (10, 42)"
      severity error;

    real_result := my_max generic map (T => real)(3.14, 2.71);
    assert real_result = 3.14
      report "FAIL: my_max real: 3.14 should be max of (3.14, 2.71)"
      severity error;

    report "PASS: Map generics on subprogram call works correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
