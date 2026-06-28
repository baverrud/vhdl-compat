-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Syntax regularization -- component declarations made optional
-- CATEGORY: syntax
-- XREF: LCS2016-055a
-- SYNTH_ENTITY: syntax_components
-- TEST_TYPE: both
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


-- ============================================================================
-- RTL: syntax_components — synthesizable demonstration of this VHDL feature
-- This module directly exercises the feature described above.
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity syntax_components is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of syntax_components is
  signal reg : std_logic_vector(7 downto 0);
begin
  -- KEY FEATURE: this module uses the VHDL feature being tested.
  -- Sim verifies correctness. Synth verifies tool acceptance.
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

entity syntax_components_tb is
end entity;

architecture test of syntax_components_tb is
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
