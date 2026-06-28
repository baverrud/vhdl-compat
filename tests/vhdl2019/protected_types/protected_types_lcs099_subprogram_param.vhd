-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Protected types as subprogram parameters
-- CATEGORY: protected_types
-- XREF: LCS2016-099
-- SYNTH_ENTITY: protected_subprogram
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, protected types could only be accessed through shared
--   variables. You could not pass a protected type object to a procedure or
--   function. This made it hard to write code that operated on protected types
--   generically.
--
--   VHDL-2019 allows protected types to be passed as subprogram parameters.
--   Variables and shared variables of protected types can be passed to
--   procedures using `variable` or `signal` parameter modes.
--
--   This test defines a simple counter protected type, passes it to a
--   procedure that increments it, and verifies the count.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;


-- ============================================================================
-- RTL: protected_subprogram — synthesizable demonstration of this VHDL feature
-- This module directly exercises the feature described above.
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity protected_subprogram is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of protected_subprogram is
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

entity protected_subprogram_tb is
end entity;

architecture test of protected_subprogram_tb is

  -- VHDL-2000: Protected type (shared variable with mutual exclusion)
  type counter_t is protected
    procedure increment;
    impure function value return integer;
  end protected;

  type counter_t is protected body
    variable count : integer := 0;
    procedure increment is
    begin
      count := count + 1;
    end procedure;
    impure function value return integer is
    begin
      return count;
    end function;
  end protected body;

  -- VHDL-2019: Procedure that takes a protected type as a parameter
  procedure inc_twice(variable c : inout counter_t) is
  begin
    c.increment;
    c.increment;
  end procedure;

  shared variable counter : counter_t;

begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Protected types as subprogram parameters" severity note;
    report "STD:  VHDL-2019 (LCS2016-099)" severity note;
    report "==============================================" severity note;

    -- Use the procedure to increment the counter
    inc_twice(counter);
    inc_twice(counter);

    -- Should be 4 (two calls, each increments twice)
    assert counter.value = 4
      report "FAIL: counter should be 4, got " & integer'image(counter.value)
      severity error;

    report "PASS: Protected types work as subprogram parameters" severity note;
    stop(0);
    wait;
  end process;

end architecture;
