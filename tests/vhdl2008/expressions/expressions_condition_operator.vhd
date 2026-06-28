-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: ?? (condition operator) -- convert std_logic to boolean
-- CATEGORY: expressions
-- SYNTH_ENTITY: condition_operator
-- TEST_TYPE: both
-- DESCRIPTION:
--   In VHDL-1993, you could not use a std_logic signal directly in an "if"
--   statement because "if" requires a boolean expression. You had to write:
--       if sig = '1' then
--   This was verbose and error-prone (forgetting the = '1' is a common bug).
--
--   VHDL-2008 introduced the "?? condition operator" which converts a
--   std_ulogic or std_logic value to boolean:
--     - '1' and 'H' → TRUE
--     - Everything else ('0', 'L', 'U', 'X', 'Z', 'W', '-') → FALSE
--
--   Furthermore, "??" is applied implicitly in "if" conditions, "while"
--   conditions, and "assert" conditions when the expression is not already
--   boolean. So you can now write:
--       if my_signal then   -- equivalent to: if ?? my_signal then
--
--   This test verifies both explicit ?? and implicit conversion.
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

entity condition_operator is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of condition_operator is
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

entity condition_operator_tb is
end entity;

architecture test of condition_operator_tb is
  signal errors : natural := 0;
begin

  stim_proc : process
    -- ------------------------------------------------------------------------
    -- Helper: check that ?? gives the expected boolean for each std_logic value
    -- ------------------------------------------------------------------------
    procedure check_condition (
      constant value    : std_logic;
      constant expected : boolean;
      constant msg      : string
    ) is
    begin
      -- Test explicit ?? operator
      if (?? value) /= expected then
        report "FAIL: ?? '" & std_logic'image(value) & "' returned "
               & boolean'image(?? value) & " but expected "
               & boolean'image(expected)
          severity error;
        errors <= errors + 1;
      end if;
    end procedure;

    -- ------------------------------------------------------------------------
    -- Helper: check implicit ?? in an if-statement
    -- ------------------------------------------------------------------------
    procedure check_implicit (
      constant value    : std_logic;
      constant expected : boolean;
      constant msg      : string
    ) is
      variable if_taken : boolean := false;
    begin
      -- VHDL-2008: "if value" implicitly applies ?? to the std_logic
      if value then
        if_taken := true;
      end if;

      if if_taken /= expected then
        report "FAIL: implicit ?? for '" & std_logic'image(value) & "'"
               & " entered if=" & boolean'image(if_taken)
               & " but expected " & boolean'image(expected)
          severity error;
        errors <= errors + 1;
      end if;
    end procedure;

  begin
    report "==============================================" severity note;
    report "TEST: ?? condition operator" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- '1' and 'H' are TRUE; everything else is FALSE
    check_condition('1',  true,  "'1' is TRUE");
    check_condition('H',  true,  "'H' is TRUE");
    check_condition('0',  false, "'0' is FALSE");
    check_condition('L',  false, "'L' is FALSE");
    check_condition('U',  false, "'U' is FALSE");
    check_condition('X',  false, "'X' is FALSE");
    check_condition('Z',  false, "'Z' is FALSE");
    check_condition('W',  false, "'W' is FALSE");
    check_condition('-',  false, "'-' is FALSE");

    -- Verify implicit conversion in if-statements
    check_implicit('1', true,   "implicit ?? for '1'");
    check_implicit('0', false,  "implicit ?? for '0'");
    check_implicit('H', true,   "implicit ?? for 'H'");
    check_implicit('X', false,  "implicit ?? for 'X'");

    -- Report result
    if errors = 0 then
      report "PASS: ?? condition operator works correctly" severity note;
      stop(0);
    else
      report "FAIL: ?? had " & integer'image(errors) & " errors"
        severity failure;
    end if;
    wait;
  end process;

end architecture;
-- TAKEAWAY: ?? converts std_logic to boolean -- write `if my_signal then` instead of `if my_signal = '1' then`.
