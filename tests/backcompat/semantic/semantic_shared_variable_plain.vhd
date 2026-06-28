-- ============================================================================
-- STD: VHDL-2000
-- FEATURE: Shared variables must be of protected type
-- CATEGORY: semantic
-- TEST_TYPE: backcompat
-- VALID_IN: VHDL-93
-- INVALID_IN: VHDL-2000, VHDL-2002, VHDL-2008, VHDL-2019
-- BREAK_REASON: VHDL-93 allowed shared variables of any type, enabling
--               non-deterministic race conditions. VHDL-2000 mandated that all
--               shared variables must be of a protected type. This broke
--               multi-process simulation models that used shared variables
--               of plain types like integer or std_logic.
-- DESCRIPTION:
--   In VHDL-93, you could write:
--       shared variable counter : integer := 0;
--   This was dangerous because multiple processes could read/write it
--   simultaneously with no synchronization. VHDL-2000 closed this hole by
--   requiring shared variables to be of a protected type (which provides
--   mutual exclusion via methods).
--
--   This test declares a shared variable of plain integer type. It should
--   compile under VHDL-93 but be rejected under VHDL-2000 and later.
--
--   EXPECTED RESULT:
--     VHDL-93 mode:             PASS (plain shared variables legal)
--     VHDL-2000/2002/2008/2019: FAIL (must be protected type)
-- ============================================================================

entity tb_shared_variable_plain is
end entity;

architecture test of tb_shared_variable_plain is
  -- VHDL-93 allowed shared variables of any type.
  -- VHDL-2000+ requires them to be of a protected type.
  -- A standards-compliant VHDL-2000+ tool must REJECT this declaration.
  shared variable counter : integer := 0;
begin
  process
  begin
    counter := counter + 1;
    report "counter = " & integer'image(counter);
    wait;
  end process;
end architecture;
-- TAKEAWAY: Backwards compatibility -- Shared variables must be of protected type.
