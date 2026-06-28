-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Context declarations — reusable sets of library/use clauses
-- CATEGORY: packages
-- SYNTH_ENTITY: context
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, every design unit had to repeat the same library and
--   use clauses. A typical file started with:
--       library ieee;
--       use ieee.std_logic_1164.all;
--       use ieee.numeric_std.all;
--       use std.env.all;
--   This was tedious and error-prone (forgetting a use clause was a common bug).
--
--   VHDL-2008 introduces context declarations: named collections of library
--   and use clauses that can be imported with a single line:
--       context work.common_context;
--
--   This test defines a context with common libraries, imports it, and
--   verifies all the names are visible.
-- ============================================================================

-- Define a context with commonly-used libraries
context common_context is
  library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use std.env.all;
end context;

-- Use the context — all names above are now visible
context work.common_context;


-- ============================================================================
-- Synthesizable RTL — demonstrates this VHDL feature in hardware
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity context is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of context is
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

entity context_tb is
end entity;

architecture test of context_tb is
  -- All of these should be visible via the context:
  --   std_logic (from std_logic_1164)
  --   unsigned  (from numeric_std)
  --   stop()    (from std.env)
  signal a : std_logic := '0';
  signal b : unsigned(3 downto 0) := X"0";
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Context declarations" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- Verify std_logic_1164 is visible via context
    a <= '1';
    wait for 5 ns;
    assert a = '1'
      report "FAIL: std_logic not visible via context"
      severity error;

    -- Verify numeric_std is visible via context
    b <= X"A";
    wait for 5 ns;
    assert b = X"A"
      report "FAIL: numeric_std not visible via context"
      severity error;

    -- Verify std.env is visible via context (stop is defined there)
    report "PASS: Context declarations work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
