-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Expressions in port maps — use arbitrary expressions (not just signals) in associations
-- CATEGORY: ports
-- SYNTH_ENTITY: port_expressions
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, port map associations could only be:
--     - A signal name: port => my_signal
--     - A conversion function: port => to_std_logic(my_signal)
--     - open
--   You could NOT use arbitrary expressions like `a and b` directly.
--
--   VHDL-2008 allows any expression in a port map's actual part:
--     uut : my_entity port map (
--       input => a and b,          -- expression, not a signal!
--       output => open
--     );
--
--   The expression is evaluated whenever any of its inputs change.
--   This eliminates dummy signals used solely for simple logic before
--   a port input.
--
--   This test wires an AND gate expression directly into a port map.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

-- Simple DUT: passes input to output
entity passthrough is
  port (
    d : in  std_logic;
    q : out std_logic
  );
end entity;

architecture rtl of passthrough is
begin
  q <= d;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;


-- ============================================================================
-- RTL: expressions in port maps — use expressions, not just signal names
-- VHDL-2008: port map (y => a and b) — compute at the port interface
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity sub_or is
  port (a, b : in std_logic; y : out std_logic);
end entity;
architecture rtl of sub_or is
begin
  y <= a or b;
end architecture;

library ieee;
use ieee.std_logic_1164.all;

entity port_expressions is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of port_expressions is
  signal result : std_logic;
begin
  -- KEY FEATURE: expressions in port maps — not just signal names
  -- Before 2008 you needed a temporary signal for each expression
  u1 : entity work.sub_or port map (a => din(0) and din(1), b => din(2) or din(3), y => result);
  dout <= (0 => result, others => '0');
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity port_expressions_tb is
end entity;

architecture test of port_expressions_tb is
  signal a, b : std_logic := '0';
  signal result : std_logic;
begin

  -- VHDL-2008: Expression in port map (a and b directly, no intermediate signal)
  uut : entity work.passthrough
    port map (
      d => a and b,       -- VHDL-2008: expression directly in port map!
      q => result
    );

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Expressions in port maps" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    a <= '0';  b <= '0';  wait for 5 ns;
    assert result = '0'
      report "FAIL: 0 AND 0 should be 0"
      severity error;

    a <= '0';  b <= '1';  wait for 5 ns;
    assert result = '0'
      report "FAIL: 0 AND 1 should be 0"
      severity error;

    a <= '1';  b <= '1';  wait for 5 ns;
    assert result = '1'
      report "FAIL: 1 AND 1 should be 1"
      severity error;

    -- Expression with more complex logic
    a <= '1';  b <= '0';  wait for 5 ns;
    assert result = '0'
      report "FAIL: 1 AND 0 should be 0"
      severity error;

    report "PASS: Expressions in port maps work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
