-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Reading output ports — out-mode ports can be read in the same entity
-- CATEGORY: ports
-- SYNTH_ENTITY: read_output_ports
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, an out-mode port could only be driven; you could NOT read
--   its value back. This was a major annoyance in RTL design. To read back an
--   output value, you had to either:
--     1. Use buffer mode (which had connection restrictions)
--     2. Create an internal signal and duplicate the assignment
--       signal internal : std_logic;
--       internal <= some_expression;
--       out_port <= internal;
--       if internal = '1' then ...  -- read from internal copy
--
--   VHDL-2008 allows reading out-mode ports directly. The value read is the
--   value driven to the port (not the resolved value at the port boundary).
--   This eliminates the need for buffer mode and internal copy signals.
--
--   This test defines an entity with an out port, reads it back in the
--   architecture, and verifies the read-back value matches.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

-- ============================================================================
-- Counter DUT with an out port that its own logic reads back
-- ============================================================================
entity readable_counter is
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    count : out unsigned(3 downto 0)      -- VHDL-2008: out port, readable!
  );
end entity;

architecture rtl of readable_counter is
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        count <= (others => '0');
      else
        -- VHDL-2008: read the out port directly!
        if count = 9 then
          count <= (others => '0');  -- wrap at 10
        else
          count <= count + 1;        -- read current value, drive next
        end if;
      end if;
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity read_output_ports_tb is
end entity;

architecture test of read_output_ports_tb is
  signal clk   : std_logic := '0';
  signal rst   : std_logic := '1';
  signal count : unsigned(3 downto 0);
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

  uut : entity work.readable_counter
    port map (clk => clk, rst => rst, count => count);

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Reading output ports" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- Reset
    wait for CLK_PERIOD * 2;
    rst <= '0';
    wait for CLK_PERIOD;

    -- After 3 clocks, count should be 3
    wait for CLK_PERIOD * 3;
    assert count = 3
      report "FAIL: count should be 3 after 3 clocks, got " & to_string(count)
      severity error;

    -- After 10 total clocks (wraps at 10), check wrap
    wait for CLK_PERIOD * 7;  -- 3 + 7 = 10
    assert count = 0
      report "FAIL: count should wrap to 0 after 10, got " & to_string(count)
      severity error;

    report "PASS: Reading output ports works correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
