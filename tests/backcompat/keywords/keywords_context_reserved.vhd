-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Reserved keyword "context" -- breaks VHDL-93 identifiers named "context"
-- CATEGORY: keywords
-- TEST_TYPE: backcompat
-- VALID_IN: VHDL-93, VHDL-2000, VHDL-2002
-- INVALID_IN: VHDL-2008, VHDL-2019
-- BREAK_REASON: VHDL-2008 added "context" as a reserved keyword for context
--               declarations. Any legacy VHDL-93/2000/2002 code that used
--               "context" as an identifier (signal, variable, port name) will
--               fail to compile under VHDL-2008 or later.
-- DESCRIPTION:
--   Each VHDL revision adds reserved keywords. If older code used one of these
--   words as a user-defined identifier, it becomes illegal in the new standard.
--
--   This test declares a signal named "context" -- a perfectly legal identifier
--   in VHDL-93 through VHDL-2002. Under VHDL-2008 and VHDL-2019, "context" is
--   a reserved keyword and this file must be rejected by the compiler.
--
--   This is the most common class of backwards-compatibility break. Other
--   VHDL-2008 keywords that can break VHDL-93 code: force, release, default,
--   parameter, property, sequence, assume, restrict, strong, cover.
--
--   EXPECTED RESULT:
--     VHDL-93 mode:  PASS (compiles -- "context" is a legal identifier)
--     VHDL-2002 mode: PASS (compiles -- "context" is a legal identifier)
--     VHDL-2008 mode: FAIL (correctly rejected -- "context" is a reserved word)
--     VHDL-2019 mode: FAIL (correctly rejected -- "context" is a reserved word)
-- ============================================================================

entity tb_keyword_context is
end entity;

architecture test of tb_keyword_context is
  -- "context" was a legal identifier in VHDL-93 through VHDL-2002.
  -- In VHDL-2008, it became a reserved keyword for context declarations.
  -- A standards-compliant VHDL-2008 tool must REJECT this file.
  signal context : integer := 0;
begin
  context <= 42;
end architecture;
-- TAKEAWAY: Backwards compatibility -- Reserved keyword "context" -- breaks VHDL-93 identifiers named "context".
