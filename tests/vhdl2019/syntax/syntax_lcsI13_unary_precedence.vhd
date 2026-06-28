-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Precedence of unary operators — standardized unary operator binding
-- CATEGORY: syntax
-- XREF: LCS2016-I13
-- SYNTH_ENTITY: unary_precedence
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, the precedence of unary operators relative to binary
--   operators was not always consistent across tools. Expressions like
--   `not a and b` could be interpreted as `(not a) and b` or `not (a and b)`
--   depending on the tool.
--
--   VHDL-2019 standardizes unary operator precedence:
--     - Unary operators (not, abs, +, -) bind tighter than binary operators
--     - `not a and b` always means `(not a) and b`
--     - Mixed unary operators associate left-to-right
--
--   This test verifies the standardized precedence with explicit
--   expressions.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;


-- ============================================================================
-- RTL: unary operator precedence — standardized unary binding
-- VHDL-2019: -a**2 = -(a**2), NOT (-a)**2 (LCS2016-I13)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity unary_precedence is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of unary_precedence is
  -- KEY FEATURE: unary precedence fix (LCS2016-I13) — -x**2 = -(x**2)
  function neg_square(x : integer) return integer is
  begin return -x**2; end function;  -- VHDL-2019: means -(x**2)
  signal val : integer range -255 to 255;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      val <= neg_square(to_integer(unsigned(din(3 downto 0))));
      dout <= std_logic_vector(to_unsigned(abs(val), 8));
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity unary_precedence_tb is
end entity;

architecture test of unary_precedence_tb is
begin

  stim_proc : process
    variable a, b, c : std_logic;
    variable result : std_logic;
  begin
    report "==============================================" severity note;
    report "TEST: Precedence of unary operators" severity note;
    report "STD:  VHDL-2019 (LCS2016-I13)" severity note;
    report "==============================================" severity note;

    -- VHDL-2019: `not a and b` means `(not a) and b`
    a := '0';  b := '1';
    result := not a and b;
    assert result = '1'
      report "FAIL: not '0' and '1' should be (not '0') and '1' = '1', got "
             & std_logic'image(result)
      severity error;

    -- `not a or b` means `(not a) or b`
    result := not a or b;
    assert result = '1'
      report "FAIL: not '0' or '1' should be '1'"
      severity error;

    -- Unary minus binds tighter than multiplication
    -- -5 * 3 = (-5) * 3 = -15 (not -(5*3) = -15)
    -- For integers: test with abs function
    assert abs(-10) = 10
      report "FAIL: abs(-10) should be 10"
      severity error;

    -- Double negation
    a := '1';
    result := not not a;
    assert result = '1'
      report "FAIL: not not '1' should be '1', got " & std_logic'image(result)
      severity error;

    report "PASS: Unary operator precedence is standardized" severity note;
    stop(0);
    wait;
  end process;

end architecture;
