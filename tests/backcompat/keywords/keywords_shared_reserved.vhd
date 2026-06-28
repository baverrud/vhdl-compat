-- ============================================================================
-- STD: VHDL-93
-- FEATURE: New VHDL-93 reserved keywords (shared, xnor, etc.)
-- CATEGORY: keywords
-- TEST_TYPE: backcompat
-- VALID_IN: VHDL-87
-- INVALID_IN: VHDL-93, VHDL-2000, VHDL-2002, VHDL-2008, VHDL-2019
-- BREAK_REASON: VHDL-93 introduced many new reserved keywords: group, impure,
--               inertial, literal, postponed, pure, reject, rol, ror, shared,
--               sla, sll, sra, srl, unaffected, xnor. Any VHDL-87 code using
--               these as identifiers broke under VHDL-93.
-- DESCRIPTION:
--   VHDL-93 was historically the most disruptive update for legacy VHDL-87
--   code. It introduced over 15 new reserved keywords. A VHDL-87 design that
--   used "shared" or "xnor" as a signal name would suddenly fail.
--
--   This test declares a signal named "shared" -- legal in VHDL-87, but a
--   reserved keyword from VHDL-93 onward. Note: most modern tools default to
--   VHDL-93 or later, so testing VHDL-87 compatibility requires explicit
--   `--std=87` flag support (not all tools have this).
--
--   EXPECTED RESULT:
--     VHDL-87 mode:  PASS (if supported by tool)
--     VHDL-93+ mode: FAIL (correctly rejected -- "shared" is reserved)
-- ============================================================================

entity tb_keyword_shared is
end entity;

architecture test of tb_keyword_shared is
  -- "shared" was a legal VHDL-87 identifier.
  -- VHDL-93 made it a reserved keyword for shared variables.
  signal shared : integer := 0;
begin
  shared <= 1;
end architecture;
-- TAKEAWAY: Backwards compatibility -- New VHDL-93 reserved keywords (shared, xnor, etc.).
