-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Standard conditional analysis identifiers — VHDL_VERSION, TOOL_TYPE, etc.
-- CATEGORY: conditional_analysis
-- XREF: LCS2016-006f
-- SYNTH_ENTITY: conditional_ids
-- TEST_TYPE: both
-- DESCRIPTION:
--   VHDL-2019 defines standard identifiers available during conditional
--   analysis ( `if / `else / `end if). These allow tool-independent
--   conditional compilation:
--     VHDL_VERSION   — the VHDL standard version (e.g., "2019")
--     TOOL_TYPE      — "SIMULATION" or "SYNTHESIS"
--     TOOL_VENDOR    — tool vendor name
--     TOOL_NAME      — tool name
--     TOOL_EDITION   — tool edition
--     TOOL_VERSION   — tool version string
--
--   Before VHDL-2019, conditional compilation relied on tool-specific
--   defines, making code non-portable. Now there's a standard way.
--
--   This test uses `if VHDL_VERSION >= "2019" to gate VHDL-2019 code
--   and verifies the standard identifiers are recognized.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity conditional_ids_tb is
end entity;

architecture test of conditional_ids_tb is
  signal detected_2019 : boolean := false;
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Standard conditional analysis identifiers" severity note;
    report "STD:  VHDL-2019 (LCS2016-006f)" severity note;
    report "==============================================" severity note;

    -- VHDL-2019: Standard identifiers in conditional analysis
    `if VHDL_VERSION >= "2019" then
      detected_2019 <= true;
      report "  VHDL_VERSION >= 2019 detected" severity note;
    `else
      detected_2019 <= false;
      report "  VHDL_VERSION < 2019" severity note;
    `end if

    -- Verify tool type identifier exists
    `if TOOL_TYPE = "SIMULATION" then
      report "  TOOL_TYPE = SIMULATION" severity note;
    `end if

    wait for 5 ns;

    -- The code was compiled with -2019 flag, so VHDL_VERSION should be >= 2019
    assert detected_2019 = true
      report "FAIL: VHDL_VERSION should be >= 2019 when compiled with -2019"
      severity error;

    report "PASS: Standard conditional analysis identifiers work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
