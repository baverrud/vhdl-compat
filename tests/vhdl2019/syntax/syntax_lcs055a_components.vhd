-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Syntax regularization -- component declarations made optional
-- CATEGORY: syntax
-- XREF: LCS2016-055a
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2019, direct entity instantiation required either:
--     1. A component declaration matching the entity's ports
--     2. Using the `entity work.name` syntax (VHDL-93)
--   The component declaration was redundant boilerplate.
--
--   VHDL-2019 makes component declarations truly optional. Direct entity
--   instantiation with `entity work.name` is the recommended style, and
--   the language removes several restrictions around component/entity
--   matching.
--
--   This test verifies direct entity instantiation works without a
--   component declaration.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

-- Simple sub-entity
entity syntax_sub is
  port (
    input  : in  std_logic;
    output : out std_logic
  );
end entity;

architecture rtl of syntax_sub is
begin
  output <= not input;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_syntax_components is
end entity;

architecture test of tb_syntax_components is
  signal a, b : std_logic := '0';
begin

  -- VHDL-2019: Direct entity instantiation -- no component declaration needed
  uut : entity work.syntax_sub
    port map (
      input  => a,
      output => b
    );

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Syntax regularization -- components" severity note;
    report "STD:  VHDL-2019 (LCS2016-055a)" severity note;
    report "==============================================" severity note;

    a <= '0';  wait for 5 ns;
    assert b = '1'
      report "FAIL: NOT(0) should be 1"
      severity error;

    a <= '1';  wait for 5 ns;
    assert b = '0'
      report "FAIL: NOT(1) should be 0"
      severity error;

    report "PASS: Direct entity instantiation works correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
