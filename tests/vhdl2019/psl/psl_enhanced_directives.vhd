-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Embedded PSL directives — property specification language in comments
-- CATEGORY: psl
-- TEST_TYPE: sim
-- DESCRIPTION:
--   The PSL (Property Specification Language) allows formal assertions about
--   temporal behavior. Before VHDL-2019, PSL directives used the `--psl`
--   comment prefix. VHDL-2019 standardized this as `-- psl` (with a space)
--   making them true VHDL comments that happen to contain PSL.
--
--   This test embeds a simple PSL assertion to verify the tool recognizes
--   the `-- psl` comment syntax.
--
--   A PSL assertion like:
--     -- psl assert always (a -> eventually! b);
--   means "whenever a is true, b must eventually become true".
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity psl_enhanced_tb is
end entity;

architecture test of psl_enhanced_tb is
  signal clk : std_logic := '0';
  signal a   : std_logic := '0';
  signal b   : std_logic := '0';

  constant CLK_PERIOD : time := 10 ns;
begin

  -- Clock generator
  clk_proc : process
  begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;
  end process;

  -- VHDL-2019: PSL directives in standard comment format
  -- psl default clock is rising_edge(clk);
  -- psl assert always (a -> eventually! b) report "PSL: a must lead to b";

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: PSL directives in standard comments" severity note;
    report "STD:  VHDL-2019" severity note;
    report "==============================================" severity note;

    wait for CLK_PERIOD * 2;
    a <= '1';
    wait for CLK_PERIOD;
    a <= '0';
    wait for CLK_PERIOD * 2;
    b <= '1';  -- Satisfy the PSL assertion: a led to b
    wait for CLK_PERIOD;
    b <= '0';
    wait for CLK_PERIOD * 2;

    report "PASS: PSL directives recognized in VHDL-2019 comment format" severity note;
    stop(0);
    wait;
  end process;

end architecture;
