-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Predefined functions to_string, minimum, maximum clash with user code
-- CATEGORY: functions
-- TEST_TYPE: backcompat
-- VALID_IN: VHDL-93, VHDL-2000, VHDL-2002
-- INVALID_IN: VHDL-2008, VHDL-2019
-- BREAK_REASON: VHDL-2008 added built-in functions to_string, to_hstring,
--               to_ostring, minimum, and maximum. If user code defined custom
--               functions with the same name and compatible signatures, the
--               compiler would detect a namespace collision.
-- DESCRIPTION:
--   Before VHDL-2008, users often wrote their own "to_string" function for
--   std_logic_vector because no standard one existed. When VHDL-2008 added a
--   built-in to_string, user code that defined their own version could clash.
--
--   This test defines a local "minimum" function with the same signature as
--   the VHDL-2008 built-in. Under VHDL-93/2000/2002 it's fine (no built-in).
--   Under VHDL-2008/2019, the compiler must detect the conflict.
--
--   Note: Some tools handle this by making the local definition shadow the
--   built-in (which is arguably correct per scope rules). The expected behavior
--   varies by tool interpretation. This test checks whether the tool ACCEPTS
--   the redefinition or flags it as an error.
--
--   EXPECTED RESULT:
--     VHDL-93/2000/2002: PASS (no built-in to conflict with)
--     VHDL-2008/2019:    Varies -- some tools accept (shadowing), some reject
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity tb_predefined_collision is
end entity;

architecture test of tb_predefined_collision is

  -- Define a local "minimum" function -- same name and signature as the
  -- VHDL-2008 built-in. This was perfectly legal before VHDL-2008.
  function minimum(a, b : integer) return integer is
  begin
    if a < b then return a; else return b; end if;
  end function;

  signal result : integer;
begin
  result <= minimum(10, 5);  -- Should return 5

  process
  begin
    wait for 1 ns;
    assert result = 5
      report "FAIL: custom minimum returned " & integer'image(result)
      severity error;
    report "PASS: local 'minimum' function works in this standard mode";
    wait;
  end process;
end architecture;
-- TAKEAWAY: Backwards compatibility -- Predefined functions to_string, minimum, maximum clash with user code.
