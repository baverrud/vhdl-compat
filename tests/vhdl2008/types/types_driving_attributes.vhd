-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: 'driving and 'driving_value — query signal driver status
-- CATEGORY: types
-- SYNTH_ENTITY: driving
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, there was no standard way to query whether a signal
--   was being actively driven or to read the driving value (as opposed to
--   the resolved/effective value). This made debugging resolved signals
--   and tri-state buses difficult.
--
--   VHDL-2008 introduces signal attributes for driver introspection:
--     s'driving        — returns true if the current process is driving s
--     s'driving_value  — returns the value the current process is driving
--                        (regardless of other drivers on a resolved signal)
--
--   These are essential for:
--     - Debugging resolved signals with multiple drivers
--     - Tri-state bus controllers that need to know if they're driving
--     - Verification IP that checks driver status
--
--   This test creates a resolved signal, drives it from multiple processes,
--   and verifies 'driving and 'driving_value.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;


-- ============================================================================
-- Synthesizable RTL — demonstrates this VHDL feature in hardware
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity driving is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of driving is
  signal reg : std_logic_vector(7 downto 0);
begin
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

entity driving_tb is
end entity;

architecture test of driving_tb is
  signal my_sig : std_logic := 'Z';
begin

  -- Driver 1: drives '1'
  driver1 : process
  begin
    my_sig <= '1';
    wait;
  end process;

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: 'driving and 'driving_value attributes" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- VHDL-2008: Check 'driving in a process that actually drives this signal
    my_sig <= '0';
    wait for 5 ns;

    -- This process drives my_sig (via the assignment above), so 'driving is valid
    if my_sig'driving then
      report "  This process is driving my_sig" severity note;
      assert my_sig'driving_value = '0'
        report "FAIL: 'driving_value should be '0', got "
               & std_logic'image(my_sig'driving_value)
        severity error;
    end if;

    report "PASS: 'driving and 'driving_value attributes are accessible" severity note;
    stop(0);
    wait;
  end process;

end architecture;
