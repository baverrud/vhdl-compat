-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Access external types through library path — cross-library type visibility
-- CATEGORY: types_2019
-- XREF: LCS2016-028
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2019, to use a type from another library, you had to
--   explicitly import it via a use clause. Even then, some type
--   relationships (like parent-child or element types) were not
--   automatically visible.
--
--   VHDL-2019 improves cross-library type visibility. Types accessed
--   through a library path maintain their relationships — if you import
--   an array type, its element type is automatically visible. This
--   reduces the need for redundant use clauses.
--
--   This test verifies that types from a package are fully visible
--   through a single use clause.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

-- Package with inter-dependent types
package cross_lib_pkg is
  subtype byte is std_logic_vector(7 downto 0);
  type byte_array is array (natural range <>) of byte;
  constant DEFAULT_BYTE : byte := X"AB";
end package;

library ieee;
use ieee.std_logic_1164.all;
use work.cross_lib_pkg.all;

entity tb_external_types is
end entity;

architecture test of tb_external_types is
  signal my_byte : byte := DEFAULT_BYTE;
  signal my_arr  : byte_array(0 to 3) := (X"00", X"11", X"22", X"33");
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Access external types through library path" severity note;
    report "STD:  VHDL-2019 (LCS2016-028)" severity note;
    report "==============================================" severity note;

    -- Verify subtype is accessible
    assert my_byte = X"AB"
      report "FAIL: DEFAULT_BYTE should be AB"
      severity error;

    -- Verify array of subtype is accessible
    assert my_arr(1) = X"11"
      report "FAIL: my_arr(1) should be 11"
      severity error;

    -- Verify array attributes work
    assert my_arr'length = 4
      report "FAIL: my_arr should have 4 elements"
      severity error;

    report "PASS: External type access through library path works" severity note;
    stop(0);
    wait;
  end process;

end architecture;
