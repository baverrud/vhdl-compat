-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: std_logic_vector redefined as subtype of std_ulogic_vector
-- CATEGORY: types
-- TEST_TYPE: backcompat
-- VALID_IN: VHDL-93, VHDL-2000, VHDL-2002
-- INVALID_IN: VHDL-2008, VHDL-2019
-- BREAK_REASON: In VHDL-2008, std_logic_vector was redefined as a subtype of
--               std_ulogic_vector rather than a distinct type. This breaks
--               code that had separate overloaded subprograms for both types,
--               because they now resolve to the same type (homograph conflict).
-- DESCRIPTION:
--   Before VHDL-2008, std_logic_vector and std_ulogic_vector were completely
--   independent types. A package could legally define:
--       function to_string(x : std_logic_vector) return string;
--       function to_string(x : std_ulogic_vector) return string;
--
--   In VHDL-2008, std_logic_vector became a subtype of std_ulogic_vector.
--   Now these two function declarations are homographs — they have the same
--   name, same parameter profile (since the types are now the same), but
--   different return types or bodies. A VHDL-2008-compliant tool must flag
--   this as an error.
--
--   This test defines a package with overloaded functions for both types.
--   It should compile under VHDL-93/2000/2002 but fail under VHDL-2008/2019.
--
--   EXPECTED RESULT:
--     VHDL-93 mode:  PASS (types are distinct — no conflict)
--     VHDL-2002 mode: PASS (types are distinct — no conflict)
--     VHDL-2008 mode: FAIL (homograph conflict — types are now the same)
--     VHDL-2019 mode: FAIL (homograph conflict)
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;

-- Package with overloaded functions for std_logic_vector and std_ulogic_vector.
-- Legal in VHDL-93/2002 because the types are distinct.
-- Illegal in VHDL-2008/2019 because std_logic_vector is a subtype of
-- std_ulogic_vector, creating a homograph conflict.
package slv_ulogic_overload is
  function describe(v : std_logic_vector) return string;
  function describe(v : std_ulogic_vector) return string;
end package;

package body slv_ulogic_overload is
  function describe(v : std_logic_vector) return string is
  begin
    return "slv: " & to_string(v);
  end function;

  function describe(v : std_ulogic_vector) return string is
  begin
    return "ulogic: " & to_string(v);
  end function;
end package body;

-- Testbench that uses the package
entity tb_slv_subtype_change is
end entity;

architecture test of tb_slv_subtype_change is
  signal s : std_logic_vector(3 downto 0) := "1010";
begin
  process
  begin
    report describe(s);
    wait;
  end process;
end architecture;
-- TAKEAWAY: Backwards compatibility — std_logic_vector redefined as subtype of std_ulogic_vector.
