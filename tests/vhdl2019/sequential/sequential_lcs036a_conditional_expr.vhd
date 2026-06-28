-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Conditional expressions in declarations — if/when in constant/signal defaults
-- CATEGORY: sequential
-- XREF: LCS2016-036a
-- SYNTH_ENTITY: conditional_expr
-- TEST_TYPE: both
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


-- ============================================================================
-- RTL: conditional expressions in sequential code — when/else in processes
-- VHDL-2019: variable x := a when cond else b; (inside process)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity conditional_expr is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of conditional_expr is
  signal threshold : std_logic_vector(7 downto 0) := X"80";
begin
  process(clk)
    -- KEY FEATURE: conditional expression in sequential context (LCS2016-036a)
    variable tmp : std_logic_vector(7 downto 0);
  begin
    if rising_edge(clk) then
      tmp := din when din > threshold else threshold;
      dout <= tmp;
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
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
