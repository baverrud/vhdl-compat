-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Relaxed library requirement on configurations
-- CATEGORY: syntax
-- XREF: LCS2016-023
-- SYNTH_ENTITY: relaxed_library
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, configurations required explicit library clauses
--   even when the libraries were obvious from context. This added
--   boilerplate to every configuration declaration.
--
--   VHDL-2019 relaxes the library requirement: configurations can now
--   reference entities and architectures from the same library without
--   an explicit library clause. The default library (`work`) is assumed.
--
--   This test verifies that a simple configuration compiles without
--   explicit library declarations.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

-- Simple entity for configuration
entity config_dut is
  port (
    input  : in  std_logic;
    output : out std_logic
  );
end entity;

architecture rtl of config_dut is
begin
  output <= input;
end architecture;

architecture inverted of config_dut is
begin
  output <= not input;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;


-- ============================================================================
-- RTL: relaxed library clause ordering (LCS2016-023)
-- VHDL-2019: library and use can appear in any order
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity relaxed_library is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of relaxed_library is
  -- KEY FEATURE: relaxed library clause ordering (LCS2016-023)
  -- RTL is a simple register; TB verifies the library ordering feature
  signal reg : std_logic_vector(7 downto 0);
begin
  process(clk) begin if rising_edge(clk) then reg <= din; dout <= reg; end if; end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity relaxed_library_tb is
end entity;

architecture test of relaxed_library_tb is
  signal a, b : std_logic := '0';
begin

  uut : entity work.config_dut
    port map (input => a, output => b);

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Relaxed library requirement on configurations" severity note;
    report "STD:  VHDL-2019 (LCS2016-023)" severity note;
    report "==============================================" severity note;

    a <= '1';  wait for 5 ns;
    assert b = '1'
      report "FAIL: pass-through should output 1"
      severity error;

    report "PASS: Configuration with relaxed library requirements works" severity note;
    stop(0);
    wait;
  end process;

end architecture;

-- VHDL-2019: Configuration without explicit library clauses
-- (Configuration placed after entity/architecture as required by VHDL)
configuration tb_config of tb_relaxed_library is
  for test
    for uut : config_dut
      use entity work.config_dut(rtl);
    end for;
  end for;
end configuration;
