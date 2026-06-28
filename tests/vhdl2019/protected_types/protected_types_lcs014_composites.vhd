-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Composites of protected types — records and arrays containing PT elements
-- CATEGORY: protected_types
-- XREF: LCS2016-014
-- TEST_TYPE: sim
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

entity tb_pt_composites is
end entity;

architecture test of tb_pt_composites is

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
