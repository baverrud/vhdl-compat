-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Empty records -- record types with no elements
-- CATEGORY: types_2019 (LCS2016-082)
-- XREF: LCS2016-082
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2019, a VHDL record type had to contain at least one element.
--   This made it impossible to use records as "marker types" or "token types"
--   -- types whose only purpose is to exist as a named placeholder in a generic
--   interface.
--
--   VHDL-2019 allows records with zero elements:
--       type nothing_t is record
--       end record;
--
--   This is useful for:
--     1. Placeholder types in generic designs ("not yet specified")
--     2. Marker/token types where the type name is the information
--     3. Interface prototyping before completing the record definition
--
--   This test verifies that an empty record can be declared, signals of that
--   type can be created, and they can be assigned to each other.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_empty_records is
end entity;

architecture test of tb_empty_records is
  -- VHDL-2019: Records with NO elements are now legal
  type empty_t is record
  end record;

  -- Two signals of the empty record type
  signal e1, e2 : empty_t;
  signal errors : natural := 0;
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Empty records" severity note;
    report "STD:  VHDL-2019 (LCS2016-082)" severity note;
    report "==============================================" severity note;

    -- Assignment between empty records should work
    e2 <= e1;
    wait for 1 ns;

    -- If we got this far without a compile error, the feature works.
    -- Empty records don't carry data, so there's nothing to compare.
    report "PASS: Empty record type declared and used without errors" severity note;
    stop(0);
    wait;
  end process;

end architecture;
-- TAKEAWAY: VHDL-2019 empty records are useful as marker/token types and placeholder interfaces in generic designs.
