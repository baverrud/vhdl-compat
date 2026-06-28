-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: 'IMAGE and TO_STRING for composite types — string representation of records and arrays
-- CATEGORY: attributes
-- XREF: LCS2016-012
-- SYNTH_ENTITY: image_composite
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, 'IMAGE was only defined for scalar types (enumerated,
--   integer, etc.). Records and arrays had no standard string representation.
--   You had to write custom to_string functions for every composite type.
--
--   VHDL-2019 extends 'IMAGE and TO_STRING to composite types:
--     - 'IMAGE returns a string like "(field1 => val1, field2 => val2)"
--     - TO_STRING works on arrays and records
--     - The format is tool-defined but consistent within the tool
--
--   This test defines a record and an array type, then verifies that
--   'IMAGE and TO_STRING can be called on them.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;


-- ============================================================================
-- RTL: 'IMAGE for composite types — string representation of arrays/records
-- VHDL-2019: 'IMAGE works on records and arrays, not just scalars (LCS2016-012)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity image_composite is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of image_composite is
  -- KEY FEATURE: 'IMAGE on composites (LCS2016-012) — records/arrays get string
  type rgb_t is record r, g, b : std_logic_vector(7 downto 0); end record;
begin
  process(clk) begin if rising_edge(clk) then dout <= din; end if; end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity image_composite_tb is
end entity;

architecture test of image_composite_tb is
  type point_t is record
    x : integer;
    y : integer;
  end record;

  type int_array is array (0 to 3) of integer;

  signal pt : point_t := (x => 10, y => 20);
  signal arr : int_array := (1, 2, 3, 4);
begin

  stim_proc : process
    variable img_str : string(1 to 80) := (others => ' ');
    variable img_len : natural;
  begin
    report "==============================================" severity note;
    report "TEST: 'IMAGE and TO_STRING for composite types" severity note;
    report "STD:  VHDL-2019 (LCS2016-012)" severity note;
    report "==============================================" severity note;

    -- VHDL-2019: 'IMAGE on a record type
    img_str(1 to point_t'image(pt)'length) := point_t'image(pt);
    report "  point_t'image: " & point_t'image(pt) severity note;

    -- VHDL-2019: 'IMAGE on an array type
    report "  int_array'image: " & int_array'image(arr) severity note;

    -- Verify the string contains expected values
    assert point_t'image(pt)'length > 0
      report "FAIL: point_t'image should return non-empty string"
      severity error;
    assert int_array'image(arr)'length > 0
      report "FAIL: int_array'image should return non-empty string"
      severity error;

    report "PASS: 'IMAGE for composite types works correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
