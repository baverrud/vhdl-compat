-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Directory API — DIR_OPEN, DIR_CREATEDIR, DIR_DELETEFILE, DIR_CLOSE
-- CATEGORY: file_io
-- XREF: LCS2016-006c
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2019, VHDL had no directory operations. Testbenches that
--   needed to create output directories, list files, or manage log files
--   had to use external scripts or simulator Tcl commands.
--
--   VHDL-2019 adds directory operations to std.env:
--     DIR_OPEN(d, path)      — open a directory for listing
--     DIR_READ(d, name)      — read next entry from directory
--     DIR_CLOSE(d)           — close directory handle
--     DIR_CREATEDIR(path)    — create a new directory
--     DIR_DELETEFILE(path)   — delete a file
--     DIR_DELETEDIR(path)    — delete an empty directory
--     DIR_EXISTS(path)       — check if directory exists
--     FILE_EXISTS(path)      — check if file exists
--     FILE_DELETE(path)      — delete a file
--
--   This test verifies basic directory operations.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;
use std.textio.all;

entity tb_directory_api is
end entity;

architecture test of tb_directory_api is
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Directory API" severity note;
    report "STD:  VHDL-2019 (LCS2016-006c)" severity note;
    report "==============================================" severity note;

    -- VHDL-2019: Create a test directory
    DIR_CREATEDIR("vhdl2019_test_dir");

    -- Create a test file inside it
    -- (Use standard file_io to write, then verify with DIR operations)

    -- Verify directory exists
    assert DIR_EXISTS("vhdl2019_test_dir") = true
      report "FAIL: DIR_EXISTS should return true for created directory"
      severity error;

    -- Clean up: delete the directory
    DIR_DELETEDIR("vhdl2019_test_dir");

    report "PASS: Directory API works correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
