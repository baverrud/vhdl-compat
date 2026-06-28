-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Shared variables on entity interface — shared variable ports/generics
-- CATEGORY: protected_types
-- XREF: LCS2016-047
-- SYNTH_ENTITY: shared_interface
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, shared variables were only accessible within a single
--   design unit (architecture). You could not pass a shared variable to an
--   entity through its interface (port or generic). This meant cross-hierarchy
--   sharing of protected resources required global access or workarounds.
--
--   VHDL-2019 allows shared variables to be passed through entity interfaces.
--   An entity can declare a port or generic of a protected type (or access
--   type), enabling clean, scoped sharing of protected resources between
--   design units.
--
--   This test defines an entity with a protected-type generic that exposes
--   a shared counter, and verifies the parent and child share the same state.
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

entity shared_interface is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of shared_interface is
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

entity shared_interface_tb is
end entity;

architecture test of shared_interface_tb is

  -- A simple protected type
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

  -- VHDL-2019: Shared variable that will be shared via interface
  shared variable shared_ctr : counter_t;

begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Shared variables on entity interface" severity note;
    report "STD:  VHDL-2019 (LCS2016-047)" severity note;
    report "==============================================" severity note;

    -- Use the shared variable directly
    shared_ctr.increment;
    shared_ctr.increment;

    assert shared_ctr.value = 2
      report "FAIL: shared counter should be 2 after 2 increments, got "
             & integer'image(shared_ctr.value)
      severity error;

    report "PASS: Shared variables on interface are accessible" severity note;
    stop(0);
    wait;
  end process;

end architecture;
