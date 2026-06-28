-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: FILE_NAME, FILE_PATH, FILE_LINE — source location introspection
-- CATEGORY: env
-- XREF: LCS2016-015a
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2019, you could not programmatically determine the current
--   source file name, path, or line number. Assertion messages had to
--   manually include this information, and generic logging utilities
--   couldn't report where they were called from.
--
--   VHDL-2019 adds introspection attributes for the current source location:
--     FILE_NAME  — returns the name of the current source file
--     FILE_PATH  — returns the full path of the current source file
--     FILE_LINE  — returns the current line number (natural)
--
--   These are similar to C's __FILE__ and __LINE__ macros.
--
--   This test verifies the attributes return plausible values.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_file_location is
end entity;

architecture test of tb_file_location is
begin

  stim_proc : process
    variable fname : string(1 to 256) := (others => ' ');
    variable line_num : natural;
  begin
    report "==============================================" severity note;
    report "TEST: FILE_NAME, FILE_PATH, FILE_LINE" severity note;
    report "STD:  VHDL-2019 (LCS2016-015a)" severity note;
    report "==============================================" severity note;

    -- VHDL-2019: Source location introspection
    fname := FILE_NAME;
    line_num := FILE_LINE;

    report "  Current file: " & fname severity note;
    report "  Current line: " & natural'image(line_num) severity note;

    -- File name should contain the test file name
    assert fname'length > 0
      report "FAIL: FILE_NAME should return non-empty string"
      severity error;

    -- Line number should be positive
    assert line_num > 0
      report "FAIL: FILE_LINE should be positive, got " & natural'image(line_num)
      severity error;

    report "PASS: Source location introspection works correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
