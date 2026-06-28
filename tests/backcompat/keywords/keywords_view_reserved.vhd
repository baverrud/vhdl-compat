-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Reserved keyword "view" -- breaks VHDL-2008 identifiers named "view"
-- CATEGORY: keywords
-- TEST_TYPE: backcompat
-- VALID_IN: VHDL-93, VHDL-2000, VHDL-2002, VHDL-2008
-- INVALID_IN: VHDL-2019
-- BREAK_REASON: VHDL-2019 added "view" as a reserved keyword for interface mode
--               views. Any legacy code that used "view" as an identifier will
--               fail to compile under VHDL-2019.
-- DESCRIPTION:
--   VHDL-2019 introduced the concept of mode views for composite interface
--   types (LCS2016-045a). This required the new reserved keyword "view".
--
--   This test declares a signal named "view" -- a legal identifier in all
--   standards up through VHDL-2008. Under VHDL-2019, "view" is a reserved
--   keyword and this file must be rejected.
--
--   EXPECTED RESULT:
--     VHDL-2008 mode: PASS (compiles -- "view" is a legal identifier)
--     VHDL-2019 mode: FAIL (correctly rejected -- "view" is a reserved word)
-- ============================================================================

entity tb_keyword_view is
end entity;

architecture test of tb_keyword_view is
  -- "view" was a legal identifier in VHDL-93 through VHDL-2008.
  -- In VHDL-2019, it became a reserved keyword for interface mode views.
  signal view : integer := 0;
begin
  view <= 7;
end architecture;
-- TAKEAWAY: Backwards compatibility -- Reserved keyword "view" -- breaks VHDL-2008 identifiers named "view".
