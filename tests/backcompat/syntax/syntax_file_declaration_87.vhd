-- ============================================================================
-- STD: VHDL-93
-- FEATURE: File declaration syntax changed from VHDL-87
-- CATEGORY: syntax
-- TEST_TYPE: backcompat
-- VALID_IN: VHDL-87
-- INVALID_IN: VHDL-93, VHDL-2000, VHDL-2002, VHDL-2008, VHDL-2019
-- BREAK_REASON: VHDL-93 completely overhauled the file declaration and opening
--               syntax. VHDL-87 file declarations are incompatible with
--               VHDL-93 and later.
-- DESCRIPTION:
--   VHDL-87 file declaration syntax looked like:
--       file my_file : text is in "data.txt";
--   VHDL-93 changed this to a two-step process:
--       file my_file : text;
--       file_open(my_file, "data.txt", read_mode);
--
--   This test uses the VHDL-87 file declaration syntax. Most modern tools
--   cannot parse VHDL-87 syntax at all unless they have an explicit --std=87
--   flag (rare). This test primarily verifies that the tool REJECTS VHDL-87
--   syntax when running in VHDL-93+ mode — i.e., doesn't silently accept it.
--
--   EXPECTED RESULT:
--     VHDL-93 and later: FAIL (VHDL-87 file syntax is invalid)
-- ============================================================================

use std.textio.all;

entity tb_file_syntax_87 is
end entity;

architecture test of tb_file_syntax_87 is
  -- VHDL-87 file declaration syntax.
  -- This is illegal in VHDL-93 and all later standards.
  -- A standards-compliant VHDL-93+ tool must REJECT this.
  file my_file : text is in "nonexistent.txt";
begin
end architecture;
-- TAKEAWAY: Backwards compatibility — File declaration syntax changed from VHDL-87.
