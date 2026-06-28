-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Generic types on subprograms — functions/procedures parameterized by type
-- CATEGORY: generics_2019
-- XREF: LCS2016-109
-- SYNTH_ENTITY: subprogram_generics
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, generic types could only appear on entities and packages.
--   Subprograms (functions and procedures) could not have generic type
--   parameters. This meant you had to duplicate subprograms for each type or
--   use complicated workarounds with generic packages.
--
--   VHDL-2019 extends generic types to subprograms. A function can now be
--   declared as:
--       function max generic (type T) parameter (a, b : T) return T;
--
--   This test defines a generic "max" function and verifies it works with
--   both integer and real types.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity subprogram_generics_tb is
end entity;

architecture test of subprogram_generics_tb is

  -- VHDL-2019: Generic type on a function
  function my_max generic (type T) parameter (a, b : T) return T is
  begin
    if a > b then
      return a;
    else
      return b;
    end if;
  end function;

  -- Instantiate for integer
  function max_int is new my_max generic map (T => integer);

  -- Instantiate for real
  function max_real is new my_max generic map (T => real);

begin

  stim_proc : process
    variable int_result : integer;
    variable real_result : real;
  begin
    report "==============================================" severity note;
    report "TEST: Generic types on subprograms" severity note;
    report "STD:  VHDL-2019 (LCS2016-109)" severity note;
    report "==============================================" severity note;

    -- Test with integer
    int_result := max_int(10, 42);
    assert int_result = 42
      report "FAIL: max_int(10, 42) should be 42, got " & integer'image(int_result)
      severity error;

    -- Test with real
    real_result := max_real(3.14, 2.71);
    assert real_result = 3.14
      report "FAIL: max_real(3.14, 2.71) should be 3.14, got " & real'image(real_result)
      severity error;

    report "PASS: Generic types on subprograms work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
