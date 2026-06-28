-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Enhanced enumerated type attributes — 'VAL, 'POS, 'SUCC, 'PRED, 'LEFTOF, 'RIGHTOF
-- CATEGORY: attributes
-- XREF: LCS2016-018/018a/018d
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2019, enumerated types had basic attributes like 'POS, 'VAL,
--   'SUCC, 'PRED, 'LEFTOF, 'RIGHTOF, 'IMAGE, 'VALUE. However, they were not
--   defined for all enumerated types consistently, especially for types with
--   non-contiguous ranges or for array-of-enum types.
--
--   VHDL-2019 standardizes and extends these attributes:
--     'VAL(N)     — returns the Nth value (0-based)
--     'POS(V)     — returns the position index of value V
--     'SUCC(V)    — returns the next value (wraps or errors at end)
--     'PRED(V)    — returns the previous value
--     'LEFTOF(V)  — returns the value left of V
--     'RIGHTOF(V) — returns the value right of V
--     'IMAGE(V)   — returns a string representation
--     'VALUE(S)   — returns the value for a given string
--     'LENGTH     — returns the number of enumeration values
--     'RANGE      — returns the range of the type
--
--   This test verifies core enum attributes on a user-defined type.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_enum_attributes is
end entity;

architecture test of tb_enum_attributes is
  type color_t is (red, green, blue, yellow, purple);

  constant test_color : color_t := blue;
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Enhanced enumerated type attributes" severity note;
    report "STD:  VHDL-2019 (LCS2016-018)" severity note;
    report "==============================================" severity note;

    -- 'POS: position index (0-based)
    assert color_t'pos(red) = 0
      report "FAIL: 'pos(red) should be 0, got " & integer'image(color_t'pos(red))
      severity error;
    assert color_t'pos(blue) = 2
      report "FAIL: 'pos(blue) should be 2"
      severity error;

    -- 'VAL: value at position
    assert color_t'val(0) = red
      report "FAIL: 'val(0) should be red"
      severity error;
    assert color_t'val(3) = yellow
      report "FAIL: 'val(3) should be yellow"
      severity error;

    -- 'SUCC: successor
    assert color_t'succ(red) = green
      report "FAIL: 'succ(red) should be green"
      severity error;

    -- 'PRED: predecessor
    assert color_t'pred(green) = red
      report "FAIL: 'pred(green) should be red"
      severity error;

    -- 'LEFTOF / 'RIGHTOF
    assert color_t'leftof(green) = red
      report "FAIL: 'leftof(green) should be red"
      severity error;
    assert color_t'rightof(red) = green
      report "FAIL: 'rightof(red) should be green"
      severity error;

    -- 'IMAGE
    assert color_t'image(blue) = "blue"
      report "FAIL: 'image(blue) should be 'blue', got '" & color_t'image(blue) & "'"
      severity error;

    -- 'VALUE
    assert color_t'value("yellow") = yellow
      report "FAIL: 'value('yellow') should be yellow"
      severity error;

    -- 'LENGTH — number of enumeration literals
    assert color_t'length = 5
      report "FAIL: color_t should have 5 values, got " & integer'image(color_t'length)
      severity error;

    report "PASS: Enhanced enumerated type attributes work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
