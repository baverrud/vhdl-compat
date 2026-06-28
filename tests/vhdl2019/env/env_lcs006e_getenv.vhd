-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Environment variables — GETENV for reading system environment
-- CATEGORY: env
-- XREF: LCS2016-006e
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2019, VHDL testbenches had no portable way to read
--   environment variables. Configuration (paths, modes, seeds) had to
--   be hard-coded or passed via simulator-specific Tcl scripts.
--
--   VHDL-2019 adds the GETENV function to std.env:
--     function GETENV(name : string) return string;
--   It returns the value of the named environment variable, or an empty
--   string if the variable is not set.
--
--   This enables CI/CD-friendly testbenches that adapt to their execution
--   environment without simulator-specific scripting.
--
--   This test reads a known environment variable (PATH on Windows, HOME
--   on Unix) and verifies GETENV returns a non-empty string.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_getenv is
end entity;

architecture test of tb_getenv is
begin

  stim_proc : process
    variable path_val : string(1 to 512);
    variable path_len : natural;
    variable missing   : string(1 to 512);
    variable miss_len  : natural;
  begin
    report "==============================================" severity note;
    report "TEST: Environment variables (GETENV)" severity note;
    report "STD:  VHDL-2019 (LCS2016-006e)" severity note;
    report "==============================================" severity note;

    -- VHDL-2019: Read a system environment variable
    -- PATH always exists on all OS
    path_val(1 to 512) := (others => ' ');
    path_val := GETENV("PATH");
    -- If PATH is not empty, GETENV works
    path_len := 0;
    for i in 1 to 512 loop
      exit when path_val(i) = ' ';
      path_len := path_len + 1;
    end loop;

    assert path_len > 0
      report "FAIL: GETENV('PATH') returned empty string"
      severity error;
    report "  GETENV('PATH') returned " & integer'image(path_len) & " characters" severity note;

    -- Non-existent variable should return empty string
    missing(1 to 512) := (others => ' ');
    missing := GETENV("VHDL_COMPAT_NONEXISTENT_VAR_XYZ123");
    miss_len := 0;
    for i in 1 to 512 loop
      exit when missing(i) = ' ';
      miss_len := miss_len + 1;
    end loop;

    assert miss_len = 0
      report "FAIL: GETENV of nonexistent var should return empty string"
      severity error;

    report "PASS: Environment variables (GETENV) work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
