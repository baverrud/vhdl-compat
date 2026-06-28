-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Optional trailing semicolon in interface lists
-- CATEGORY: syntax (LCS2016-071a)
-- XREF: LCS2016-071a
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2019, every element in a port list or generic list EXCEPT the
--   last one required a semicolon. The last element could NOT have a trailing
--   semicolon. This was a constant source of trivial syntax errors: you'd
--   remove the last port, forget to delete the now-trailing semicolon on the
--   second-to-last port, and the compiler would complain.
--
--   VHDL-2019 makes the trailing semicolon OPTIONAL. You can now write:
--       port (
--         a : std_logic;
--         b : integer;   -- this trailing semicolon is now legal
--       );
--
--   This is a small change, but it eliminates one of the most common
--   VHDL syntax annoyances.
--
--   This test verifies that the tool accepts a trailing semicolon after the
--   last element in an interface list. It also serves as the BASELINE
--   VERIFICATION that the tool is actually running in VHDL-2019 mode --
--   if this test fails, the tool is likely in VHDL-2008 or earlier mode.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

-- ============================================================================
-- Entity with TRAILING SEMICOLON after the last port
-- This would be illegal in VHDL-2008 and earlier.
-- ============================================================================
entity entity_with_trailing_semicolon is
  port (
    a : in  std_logic;
    b : in  std_logic;
    y : out std_logic;   -- <-- VHDL-2019: trailing semicolon is now OPTIONAL
  );
end entity;

architecture rtl of entity_with_trailing_semicolon is
begin
  y <= a and b;
end architecture;

-- ============================================================================
-- Testbench
-- ============================================================================
entity tb_optional_trailing_semicolon is
end entity;

architecture test of tb_optional_trailing_semicolon is
  signal a, b, y : std_logic := '0';
  signal errors  : natural := 0;
begin

  -- Instantiate the entity that uses the trailing semicolon
  uut : entity work.entity_with_trailing_semicolon
    port map (
      a => a,
      b => b,
      y => y
    );

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Optional trailing semicolon in interface lists" severity note;
    report "STD:  VHDL-2019 (LCS2016-071a)" severity note;
    report "==============================================" severity note;

    -- Basic functional check: the entity should work as an AND gate
    a <= '0'; b <= '0'; wait for 1 ns;
    if y /= '0' then
      report "FAIL: 0 AND 0 = " & std_logic'image(y) & " expected 0"
        severity error;
      errors <= errors + 1;
    end if;

    a <= '0'; b <= '1'; wait for 1 ns;
    if y /= '0' then
      report "FAIL: 0 AND 1 = " & std_logic'image(y) & " expected 0"
        severity error;
      errors <= errors + 1;
    end if;

    a <= '1'; b <= '0'; wait for 1 ns;
    if y /= '0' then
      report "FAIL: 1 AND 0 = " & std_logic'image(y) & " expected 0"
        severity error;
      errors <= errors + 1;
    end if;

    a <= '1'; b <= '1'; wait for 1 ns;
    if y /= '1' then
      report "FAIL: 1 AND 1 = " & std_logic'image(y) & " expected 1"
        severity error;
      errors <= errors + 1;
    end if;

    if errors = 0 then
      report "PASS: Trailing semicolon in interface list is accepted" severity note;
      stop(0);
    else
      report "FAIL: Trailing semicolon test had " & integer'image(errors)
             & " errors" severity failure;
    end if;
    wait;
  end process;

end architecture;
-- TAKEAWAY: VHDL-2019 optional trailing semicolons eliminate the "expecting IDENTIFIER" error -- a common syntax annoyance.
