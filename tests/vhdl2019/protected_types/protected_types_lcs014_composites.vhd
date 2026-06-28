-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Composites of protected types — records and arrays containing PT elements
-- CATEGORY: protected_types
-- XREF: LCS2016-014
-- SYNTH_ENTITY: pt_composites
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, protected types could only be used as shared variables.
--   You could not put a protected type inside a record, array, or pass it
--   as a subprogram parameter. Each protected type stood alone.
--
--   VHDL-2019 allows composites containing protected types:
--     - Records with protected type fields
--     - Arrays of protected type elements
--     - Passing composite structures that contain PTs
--
--   This enables grouping related protected resources (e.g., a scoreboard
--   with a mutex + a queue) into a single composite type.
--
--   This test defines a record containing a protected counter and verifies
--   it can be declared and used.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;


-- ============================================================================
-- RTL: composites of protected types — records/arrays with PT elements
-- VHDL-2019: arrays of protected types (LCS2016-014)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pt_composites is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of pt_composites is
  -- KEY FEATURE: PT composites (LCS2016-014) — array of integer as simple composite
  -- RTL uses a simple integer array; TB exercises full PT composite feature
  type int_array is array (0 to 3) of integer range 0 to 255;
  signal vals : int_array := (others => 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      vals(0) <= to_integer(unsigned(din));
      dout <= std_logic_vector(to_unsigned(vals(0), 8));
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity pt_composites_tb is
end entity;

architecture test of pt_composites_tb is

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

  -- VHDL-2019: Record containing a protected type field
  type pt_record is record
    tag   : string(1 to 8);
    counter : counter_t;
  end record;

  shared variable sv_rec : pt_record;

begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Composites of protected types" severity note;
    report "STD:  VHDL-2019 (LCS2016-014)" severity note;
    report "==============================================" severity note;

    -- Use the protected counter inside the record
    sv_rec.tag := "counter1";
    sv_rec.counter.increment;
    sv_rec.counter.increment;
    sv_rec.counter.increment;

    assert sv_rec.counter.value = 3
      report "FAIL: counter in record should be 3, got "
             & integer'image(sv_rec.counter.value)
      severity error;

    report "PASS: Composites of protected types work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
