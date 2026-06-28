-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Sequential declaration regions — declare variables anywhere in sequential code
-- CATEGORY: sequential
-- XREF: LCS2016-007
-- SYNTH_ENTITY: declaration_regions
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, all variable declarations in a process or subprogram
--   had to appear at the top, before the first sequential statement. This
--   was a remnant of VHDL's Ada heritage. Variables used late in a long
--   process had to be declared far from their use.
--
--   VHDL-2019 allows variable declarations anywhere in sequential code,
--   not just at the top. This enables:
--     - Declaring variables near their first use
--     - Limiting variable scope for readability
--     - Re-declaring the same name in different scopes (shadowing)
--
--   This test verifies that variables can be declared mid-process.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;


-- ============================================================================
-- RTL: sequential declaration regions — declare variables anywhere
-- VHDL-2019: variables in if/case branches, loop bodies without blocks
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity declaration_regions is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of declaration_regions is
begin
  process(clk)
  begin
    if rising_edge(clk) then
      -- KEY FEATURE: declare variables in if-branch (LCS2016-007)
      if din(0) = '1' then
        variable tmp : std_logic_vector(7 downto 0);
        tmp := din;
        dout <= tmp;
      else
        dout <= not din;
      end if;
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity declaration_regions_tb is
end entity;

architecture test of declaration_regions_tb is
begin

  stim_proc : process
    variable outer_var : integer := 10;
  begin
    report "==============================================" severity note;
    report "TEST: Sequential declaration regions" severity note;
    report "STD:  VHDL-2019 (LCS2016-007)" severity note;
    report "==============================================" severity note;

    -- Use top-level variable
    outer_var := outer_var + 5;
    assert outer_var = 15
      report "FAIL: outer_var should be 15"
      severity error;

    -- VHDL-2019: Declare a variable mid-process (not at the top)
    variable inner_var : integer := 100;
    inner_var := inner_var + outer_var;
    assert inner_var = 115
      report "FAIL: inner_var should be 115, got " & integer'image(inner_var)
      severity error;

    -- Another mid-process declaration
    variable another : string(1 to 5) := "hello";
    assert another = "hello"
      report "FAIL: another should be 'hello'"
      severity error;

    report "PASS: Sequential declaration regions work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
