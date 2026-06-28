-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Map generics on subprogram call — override generics at call site
-- CATEGORY: generics_2019
-- XREF: LCS2016-049
-- TEST_TYPE: sim
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

entity tb_map_on_call is
end entity;

architecture test of tb_map_on_call is

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
