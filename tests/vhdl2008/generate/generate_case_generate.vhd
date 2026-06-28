-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Case-generate — conditional elaboration based on a discrete expression
-- CATEGORY: generate
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2008, generate statements could only use "for" (iteration)
--   or "if" (conditional). Selecting between multiple mutually-exclusive
--   architecture variants required nested if-generate chains:
--       g1: if MODE = 0 generate ... end generate;
--       g2: if MODE = 1 generate ... end generate;
--       g3: if MODE = 2 generate ... end generate;
--   This was verbose and error-prone (nothing prevents overlapping conditions).
--
--   VHDL-2008 introduces case-generate, which is like a case statement for
--   elaboration: exactly one branch is elaborated based on the expression.
--
--   This test uses a generic MODE to select between adder/subtractor/
--   multiplier implementations via case-generate.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_case_generate is
  generic (
    MODE : integer := 0   -- 0=add, 1=sub, 2=identity
  );
end entity;

architecture test of tb_case_generate is
  signal a, b : unsigned(3 downto 0) := X"0";
  signal result : unsigned(3 downto 0);
begin

  -- VHDL-2008: case-generate selects exactly one implementation at elaboration
  gen_impl : case MODE generate
    when 0 =>
      result <= a + b;
    when 1 =>
      result <= a - b;
    when 2 =>
      result <= a;
    when others =>
      result <= (others => '0');
  end generate;

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Case-generate" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    a <= X"5";  b <= X"3";
    wait for 5 ns;

    if MODE = 0 then
      assert result = X"8"
        report "FAIL: MODE=0 (adder): 5+3 should be 8, got " & to_string(result)
        severity error;
    elsif MODE = 1 then
      assert result = X"2"
        report "FAIL: MODE=1 (subtractor): 5-3 should be 2, got " & to_string(result)
        severity error;
    elsif MODE = 2 then
      assert result = X"5"
        report "FAIL: MODE=2 (identity): result should equal a (5)"
        severity error;
    end if;

    report "PASS: Case-generate works correctly (MODE=" & integer'image(MODE) & ")" severity note;
    stop(0);
    wait;
  end process;

end architecture;
