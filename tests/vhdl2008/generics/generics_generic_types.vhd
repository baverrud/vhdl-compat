-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Generic types -- entities/functions parameterizable by type
-- CATEGORY: generics
-- SYNTH_ENTITY: generic_types
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, generics on entities could only be constants (integers,
--   times, etc.). If you wanted a component that worked with multiple data
--   types, you had to copy-paste the code or use complex workarounds.
--
--   VHDL-2008 allows generics to be TYPES and SUBPROGRAMS. This means you can
--   write a single entity (e.g., a FIFO, a multiplexer, a pipeline stage)
--   that is parameterized by the data type it operates on. The type is
--   provided when the component is instantiated.
--
--   This test defines a generic "incrementer" entity that works with any
--   type supporting a "+" operation, then instantiates it for both integer
--   and std_logic_vector, verifying each.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

-- ============================================================================
-- A generic incrementer -- works with any type that has a "+" operator
-- The type and the increment function are provided as generics.
-- ============================================================================
entity generic_incrementer is
  generic (
    type data_type;                                       -- The data type
    function increment (x : data_type) return data_type   -- How to increment
  );
  port (
    input  : in  data_type;
    output : out data_type
  );
end entity;

architecture rtl of generic_incrementer is
begin
  output <= increment(input);
end architecture;

-- ============================================================================
-- Testbench
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;


-- ============================================================================
-- RTL: generic types — entities parameterized by type
-- VHDL-2008: FIFOs, pipelines, and other reusable components with type params
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity generic_types is
  generic (type ELEMENT_T);
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of generic_types is
begin
  -- KEY FEATURE: ELEMENT_T is a type parameter — works for any type
  process(clk)
  begin
    if rising_edge(clk) then dout <= din; end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity generic_types_tb is
end entity;

architecture test of generic_types_tb is
  signal errors : natural := 0;

  -- Increment function for integer
  function inc_int (x : integer) return integer is
  begin
    return x + 1;
  end function;

  -- Increment function for std_logic_vector (treat as unsigned)
  function inc_slv (x : std_logic_vector(7 downto 0)) return std_logic_vector is
  begin
    return std_logic_vector(unsigned(x) + 1);
  end function;

  -- Test signals
  signal int_in  : integer := 0;
  signal int_out : integer;
  signal slv_in  : std_logic_vector(7 downto 0) := (others => '0');
  signal slv_out : std_logic_vector(7 downto 0);
begin

  -- Instantiate incrementer for integer type
  incr_int_inst : entity work.generic_incrementer
    generic map (
      data_type => integer,
      increment => inc_int
    )
    port map (
      input  => int_in,
      output => int_out
    );

  -- Instantiate incrementer for std_logic_vector type
  incr_slv_inst : entity work.generic_incrementer
    generic map (
      data_type => std_logic_vector(7 downto 0),
      increment => inc_slv
    )
    port map (
      input  => slv_in,
      output => slv_out
    );

  -- --------------------------------------------------------------------------
  -- Stimulus + Checker
  -- --------------------------------------------------------------------------
  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Generic types on entities" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- Test integer incrementer
    int_in <= 0;
    wait for 1 ns;
    if int_out /= 1 then
      report "FAIL: int incrementer -- got " & integer'image(int_out)
             & " expected 1" severity error;
      errors <= errors + 1;
    end if;

    int_in <= 41;
    wait for 1 ns;
    if int_out /= 42 then
      report "FAIL: int incrementer -- got " & integer'image(int_out)
             & " expected 42" severity error;
      errors <= errors + 1;
    end if;

    -- Test std_logic_vector incrementer
    slv_in <= "00000000";
    wait for 1 ns;
    if slv_out /= "00000001" then
      report "FAIL: slv incrementer -- got " & to_string(slv_out)
             & " expected 00000001" severity error;
      errors <= errors + 1;
    end if;

    slv_in <= "11111111";
    wait for 1 ns;
    if slv_out /= "00000000" then
      report "FAIL: slv incrementer wraparound -- got " & to_string(slv_out)
             & " expected 00000000" severity error;
      errors <= errors + 1;
    end if;

    -- Report result
    if errors = 0 then
      report "PASS: Generic types work with both integer and std_logic_vector"
        severity note;
      stop(0);
    else
      report "FAIL: Generic types had " & integer'image(errors) & " errors"
        severity failure;
    end if;
    wait;
  end process;

end architecture;
-- TAKEAWAY: VHDL-2008 generic types let you write one entity that works with any data type -- instantiate it for integer, slv, or your own type.
