-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: File I/O extensions — FILE_REWIND, FILE_SEEK, FILE_TRUNCATE, FILE_STATE
-- CATEGORY: file_io
-- XREF: LCS2016-006a
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2019, file operations were limited to sequential read/write
--   via READLINE/WRITELINE. There was no way to rewind, seek, or query
--   file state.
--
--   VHDL-2019 extends file I/O with:
--     FILE_REWIND(f)   — return to beginning of file
--     FILE_SEEK(f, n)  — seek to byte position n
--     FILE_TRUNCATE(f) — truncate file at current position
--     FILE_STATE(f)    — query file state (open/closed, read/write mode)
--     FILE_MODE(f)     — query file open mode
--     FILE_SIZE(f)     — get file size in bytes
--
--   These enable random-access file processing, log rotation, and
--   file-based data structures in VHDL testbenches.
--
--   This test verifies FILE_REWIND and basic file I/O.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;
use std.textio.all;

entity file_io_ext_tb is
end entity;

architecture test of file_io_ext_tb is
begin

  stim_proc : process
    file f : text;
    variable f_status : file_open_status;
    variable l : line;
  begin
    report "==============================================" severity note;
    report "TEST: File I/O extensions (FILE_REWIND)" severity note;
    report "STD:  VHDL-2019 (LCS2016-006a)" severity note;
    report "==============================================" severity note;

    -- Open file for writing
    file_open(f_status, f, "test_ext.txt", write_mode);
    assert f_status = open_ok
      report "FAIL: open for write failed"
      severity error;

    -- Write two lines
    write(l, string'("line 1"));
    writeline(f, l);
    write(l, string'("line 2"));
    writeline(f, l);

    file_close(f);

    -- Reopen for reading
    file_open(f_status, f, "test_ext.txt", read_mode);
    assert f_status = open_ok
      report "FAIL: reopen for read failed"
      severity error;

    -- Read first line
    readline(f, l);
    assert l.all = "line 1"
      report "FAIL: first line should be 'line 1', got '" & l.all & "'"
      severity error;

    -- Read second line
    readline(f, l);
    assert l.all = "line 2"
      report "FAIL: second line should be 'line 2', got '" & l.all & "'"
      severity error;

    -- VHDL-2019: FILE_REWIND — go back to beginning
    file_rewind(f);

    -- Read first line again
    readline(f, l);
    assert l.all = "line 1"
      report "FAIL: after rewind, first line should be 'line 1' again"
      severity error;

    file_close(f);

    report "PASS: File I/O extensions work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
