-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Conditional return statement — return with when/else conditions
-- CATEGORY: sequential
-- XREF: LCS2016-094a
-- SYNTH_ENTITY: conditional_return
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, early return from a function or procedure required
--   wrapping the remaining body in an if statement:
--       function classify(x : integer) return string is
--       begin
--         if x < 0 then
--           return "negative";
--         else
--           if x = 0 then
--             return "zero";
--           else
--             return "positive";
--           end if;
--         end if;
--       end function;
--   This led to deeply nested if statements ("arrow anti-pattern").
--
--   VHDL-2019 introduces the conditional return statement:
--       return expression when condition;
--   This flattens the logic and makes guard clauses readable:
--       function classify(x : integer) return string is
--       begin
--         return "negative" when x < 0;
--         return "zero"     when x = 0;
--         return "positive";
--       end function;
--
--   This test defines a function with conditional returns and verifies
--   each branch.
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

entity conditional_return is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of conditional_return is
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

entity conditional_return_tb is
end entity;

architecture test of conditional_return_tb is

  -- VHDL-2019: Conditional return statement
  function classify(x : integer) return string is
  begin
    return "negative" when x < 0;
    return "zero"     when x = 0;
    return "positive";
  end function;

  function is_even(x : integer) return boolean is
  begin
    return true  when x mod 2 = 0;
    return false when x mod 2 = 1;
    return false;
  end function;

begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Conditional return statement" severity note;
    report "STD:  VHDL-2019 (LCS2016-094a)" severity note;
    report "==============================================" severity note;

    assert classify(-5) = "negative"
      report "FAIL: classify(-5) should be 'negative', got '" & classify(-5) & "'"
      severity error;
    assert classify(0) = "zero"
      report "FAIL: classify(0) should be 'zero', got '" & classify(0) & "'"
      severity error;
    assert classify(42) = "positive"
      report "FAIL: classify(42) should be 'positive', got '" & classify(42) & "'"
      severity error;

    assert is_even(0) = true
      report "FAIL: 0 should be even"
      severity error;
    assert is_even(3) = false
      report "FAIL: 3 should be odd"
      severity error;
    assert is_even(100) = true
      report "FAIL: 100 should be even"
      severity error;

    report "PASS: Conditional return statement works correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
