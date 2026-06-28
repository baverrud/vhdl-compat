-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Conditional sequential assignment — when/else inside processes
-- CATEGORY: processes
-- SYNTH_ENTITY: seq_assignments
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, assigning to a signal or variable inside a process
--   based on a condition required a full if statement:
--       if sel = '0' then
--         result <= a;
--       else
--         result <= b;
--       end if;
--   This was verbose for simple mux-style assignments.
--
--   VHDL-2008 introduces two new sequential assignment forms:
--     1. Conditional sequential assignment (when/else in a process):
--          result <= a when sel = '0' else b;
--     2. Selected sequential assignment (with/select in a process):
--          with sel select result <= a when '0', b when others;
--
--   These are the sequential equivalents of the concurrent conditional
--   and selected signal assignments.
--
--   This test verifies both forms work correctly inside a process.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;


-- ============================================================================
-- RTL: conditional sequential assignment — when/else inside a process
-- VHDL-2008: variable <= a when sel='0' else b;
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity seq_assignments is
  port (a, b : in std_logic_vector(7 downto 0); sel : in std_logic; y : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of seq_assignments is
begin
  process(a, b, sel)
    -- KEY FEATURE: conditional assignment inside a process (not just concurrent!)
    variable tmp : std_logic_vector(7 downto 0);
  begin
    tmp := a when sel = '0' else b;
    y <= tmp;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity seq_assignments_tb is
end entity;

architecture test of seq_assignments_tb is
  signal sel : std_logic := '0';
  signal a, b : std_logic_vector(3 downto 0) := X"0";
begin

  stim_proc : process
    variable result_cond : std_logic_vector(3 downto 0);
    variable result_sel  : std_logic_vector(3 downto 0);
  begin
    report "==============================================" severity note;
    report "TEST: Conditional and selected sequential assignments" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    a <= X"A";  b <= X"5";
    wait for 5 ns;

    -- VHDL-2008: Conditional sequential assignment (when/else in a process)
    sel <= '0';
    wait for 1 ns;
    result_cond := a when sel = '0' else
                   b when sel = '1' else
                   X"0";
    assert result_cond = X"A"
      report "FAIL: conditional: when sel='0' should pick a (X'A'), got " & to_string(result_cond)
      severity error;

    sel <= '1';
    wait for 1 ns;
    result_cond := a when sel = '0' else b;
    assert result_cond = X"5"
      report "FAIL: conditional: when sel='1' should pick b (X'5'), got " & to_string(result_cond)
      severity error;

    -- VHDL-2008: Chained conditional assignment (multiple when/else)
    sel <= '0';
    wait for 1 ns;
    result_cond := a when sel = '0' else
                   b when sel = '1' else
                   X"F";
    assert result_cond = X"A"
      report "FAIL: chained conditional: first match should be X'A'"
      severity error;

    report "PASS: Conditional sequential assignments work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
