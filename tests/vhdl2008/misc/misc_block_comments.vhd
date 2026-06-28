-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Block comments /* ... */
-- CATEGORY: misc
-- TEST_TYPE: sim
-- DESCRIPTION:
--   VHDL-1993 only supported single-line comments with "--". Commenting out
--   a large block of code required prefixing every line with "--", which was
--   tedious and error-prone.
--
--   VHDL-2008 added block comments delimited by /* and */, similar to C and
--   Verilog. These can span multiple lines and can be nested inside code.
--
--   Warning: some VHDL-2008 tools support /* */ but not nested block comments.
--
--   This test verifies that the tool accepts /* */ block comment syntax.
--   Since /* */ is purely a lexical feature (the compiler strips comments
--   before parsing), the test simply verifies that a file containing block
--   comments compiles cleanly.
-- ============================================================================

/*
 * This entire block is a multi-line comment.
 * It would have required "--" on every line in VHDL-1993.
 * VHDL-2008 allows C-style block comments.
 */

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_block_comments is
end entity;

/*
 * Architecture with block comments used throughout.
 * Notice that /* nested block comments */ may or may not be supported
 * depending on the tool -- this test only checks non-nested /* */.
 */
architecture test of tb_block_comments is
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Block comments /* */" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    /*
       This code is inside a block comment and should be ignored:
       report "This should never print" severity failure;
       errors <= 99;
    */

    -- If we reach here, the block comment was correctly ignored
    report "PASS: Block comments /* */ compiled without errors" severity note;
    stop(0); /* stop with success code 0 */
    wait;
  end process;

end architecture;
-- TAKEAWAY: VHDL-2008 block comments /* ... */ let you comment out large sections without prefixing every line with --.
