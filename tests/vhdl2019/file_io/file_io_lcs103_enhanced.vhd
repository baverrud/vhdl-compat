-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Enhanced FILE_OPEN/FILE_CLOSE with STATUS parameter
-- CATEGORY: file_io
-- XREF: LCS2016-103
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2019, FILE_OPEN and FILE_CLOSE were procedures. If they
--   failed (e.g., file not found), the only option was an assertion failure.
--   There was no way to handle errors gracefully.
--
--   VHDL-2019 adds a STATUS parameter to FILE_OPEN and FILE_CLOSE. The status
--   values are defined in std.standard:
--     OPEN_OK      — file opened successfully
--     NAME_ERROR   — file doesn't exist
--     MODE_ERROR   — can't open in requested mode
--     STATUS_ERROR — file already open
--
--   This test verifies FILE_OPEN with STATUS works by opening a file,
--   checking the status, and then closing it.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;
use std.textio.all;

entity file_io_enhanced_tb is
end entity;

architecture test of file_io_enhanced_tb is
begin

  stim_proc : process
    file f : text;
    variable f_status : file_open_status;
    variable l : line;
  begin
    report "==============================================" severity note;
    report "TEST: Enhanced file I/O with STATUS" severity note;
    report "STD:  VHDL-2019 (LCS2016-103)" severity note;
    report "==============================================" severity note;

    -- VHDL-2019: FILE_OPEN with STATUS parameter
    file_open(f_status, f, "test_output.txt", write_mode);
    assert f_status = open_ok
      report "FAIL: Expected open_ok, got status " & file_open_status'image(f_status)
      severity error;

    -- Write a line to the file
    write(l, string'("Hello from VHDL-2019 file I/O test"));
    writeline(f, l);

    -- Close file (traditional form)
    file_close(f);

    -- Reopen for reading to verify content
    file_open(f_status, f, "test_output.txt", read_mode);
    assert f_status = open_ok
      report "FAIL: Re-open should succeed, got status " & file_open_status'image(f_status)
      severity error;

    readline(f, l);
    assert l.all = "Hello from VHDL-2019 file I/O test"
      report "FAIL: Read wrong content: " & l.all
      severity error;

    file_close(f);

    report "PASS: Enhanced file I/O with STATUS works correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
