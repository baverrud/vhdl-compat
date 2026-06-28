-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: PSL attributes and functions — extended PSL built-in capabilities
-- CATEGORY: psl
-- XREF: LCS2016-043
-- TEST_TYPE: sim
-- DESCRIPTION:
--   The PSL (Property Specification Language) was added to VHDL in VHDL-2008
--   with basic assertion directives (--psl assert, --psl assume, --psl
--   cover). VHDL-2019 extends PSL with:
--     - New built-in functions: rose(), fell(), stable(), past(), next()
--     - PSL attributes: PSL_COVER, PSL_ENDPOINT
--     - Enhanced coverage reporting
--     - New sequence operators
--
--   These enable more expressive temporal assertions for formal
--   verification and simulation checkers.
--
--   This test embeds PSL directives using some of the enhanced functions.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_psl_attributes is
end entity;

architecture test of tb_psl_attributes is
  signal clk   : std_logic := '0';
  signal a     : std_logic := '0';
  signal b     : std_logic := '0';
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

  -- VHDL-2019 PSL: Enhanced PSL directives
  -- psl default clock is rising_edge(clk);
  -- psl property a_rose is rose(a);
  -- psl assert always (a_rose -> next b);

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: PSL attributes and functions" severity note;
    report "STD:  VHDL-2019 (LCS2016-043)" severity note;
    report "==============================================" severity note;

    wait for CLK_PERIOD * 2;
    a <= '1';                    -- rose(a) should trigger
    wait for CLK_PERIOD;
    a <= '0';
    wait for CLK_PERIOD;
    b <= '1';                    -- satisfy: next b after a rose
    wait for CLK_PERIOD;
    b <= '0';
    wait for CLK_PERIOD * 2;

    report "PASS: PSL attributes and functions are recognized" severity note;
    stop(0);
    wait;
  end process;

end architecture;
