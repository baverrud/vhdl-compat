-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Conditional expressions in declarations — if/when in constant/signal defaults
-- CATEGORY: sequential
-- XREF: LCS2016-036a
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2019, the initial value of a constant or signal had to be a
--   simple expression. Conditional initialization required a separate
--   function or an initial process:
--       function init_value(g : integer) return integer is
--       begin if g > 10 then return 10; else return g; end if; end function;
--       constant LIMIT : integer := init_value(G);
--
--   VHDL-2019 allows conditional expressions directly in declarations:
--       constant LIMIT : integer := 10 when G > 10 else G;
--
--   This is more readable and eliminates one-off initialization functions.
--   This test verifies conditional expressions in constant, signal, and
--   variable declarations.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity conditional_expr_tb is
  generic (
    G : integer := 5
  );
end entity;

architecture test of conditional_expr_tb is
  -- VHDL-2019: Conditional expression in constant declaration
  constant LIMIT : integer := 10 when G > 10 else G;
  constant MODE  : string  := "high" when G > 5 else "low";

  -- VHDL-2019: Conditional expression in signal default
  signal threshold : integer := 100 when G > 3 else 50;
begin

  stim_proc : process
    -- VHDL-2019: Conditional expression in variable declaration
    variable msg : string(1 to 10) := "positive" when G >= 0 else "negative";
  begin
    report "==============================================" severity note;
    report "TEST: Conditional expressions in declarations" severity note;
    report "STD:  VHDL-2019 (LCS2016-036a)" severity note;
    report "==============================================" severity note;

    -- Verify constant initialized with conditional expression
    assert LIMIT = 5
      report "FAIL: LIMIT should be G (5), got " & integer'image(LIMIT)
      severity error;

    -- Verify signal default
    assert threshold = 100
      report "FAIL: threshold should be 100, got " & integer'image(threshold)
      severity error;

    report "PASS: Conditional expressions in declarations work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
