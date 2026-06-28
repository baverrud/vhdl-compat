-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: process(all) -- automatic sensitivity list inference
-- CATEGORY: processes
-- XREF: FT19
-- SYNTH_ENTITY: process_all
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, a combinational process required the designer to manually
--   list every signal read in the process body in the sensitivity list.
--   Forgetting a signal was a silent bug: simulation would miss events on that
--   signal, but synthesis would correctly infer the hardware, causing a
--   simulation/synthesis mismatch that was hard to debug.
--
--   VHDL-2008 introduced the keyword "all" in place of the signal list:
--       process(all)
--   The simulator now automatically scans the process body and includes every
--   signal that is read in the sensitivity list. This completely eliminates
--   the mismatch bug class.
--
--   This test verifies that process(all) correctly detects changes on three
--   independent input signals (a, b, c) and recomputes the output (y).
--   It also serves as the BASELINE VERIFICATION that the tool is actually
--   running in VHDL-2008 mode -- if this test fails, the tool is likely in
--   VHDL-1993 mode.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;


-- ============================================================================
-- RTL: process(all) — automatic sensitivity list
-- VHDL-2008: process(all) infers sensitivity from all signals read inside
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity process_all is
  port (a, b : in std_logic; y : out std_logic);
end entity;
architecture rtl of process_all is
begin
  -- KEY FEATURE: process(all) — no need to list (a, b) manually
  process(all)
  begin
    y <= a and b;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity process_all_tb is
end entity;

architecture test of process_all_tb is
  signal a, b, c : std_logic := '0';
  signal y       : std_logic;
  signal errors  : natural := 0;
begin

  -- --------------------------------------------------------------------------
  -- Device Under Test: a simple AND-OR gate using process(all)
  --
  -- In VHDL-1993 we would write:  process(a, b, c)
  -- In VHDL-2008 we can write:    process(all)
  -- The result is identical, but process(all) can never have a missing signal.
  -- --------------------------------------------------------------------------
  dut : process(all)
  begin
    y <= (a and b) or c;
  end process;

  -- --------------------------------------------------------------------------
  -- Stimulus + Checker
  -- --------------------------------------------------------------------------
  stim_proc : process
    -- Helper function to compute expected value
    function expected (aa, bb, cc : std_logic) return std_logic is
    begin
      return (aa and bb) or cc;
    end function;

    -- Helper to drive and check
    procedure check (
      constant aa, bb, cc : std_logic;
      constant msg        : string
    ) is
    begin
      a <= aa; b <= bb; c <= cc;
      wait for 1 ns;  -- Allow delta cycle for signal update

      if y /= expected(a, b, c) then
        report "FAIL: " & msg & " -- y=" & std_logic'image(y)
               & " expected " & std_logic'image(expected(a, b, c))
          severity error;
        errors <= errors + 1;
      end if;
    end procedure;

  begin
    report "==============================================" severity note;
    report "TEST: process(all) -- automatic sensitivity list" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- Walk through all 8 input combinations
    check('0','0','0', "a=0,b=0,c=0");
    check('0','0','1', "a=0,b=0,c=1");
    check('0','1','0', "a=0,b=1,c=0");
    check('0','1','1', "a=0,b=1,c=1");
    check('1','0','0', "a=1,b=0,c=0");
    check('1','0','1', "a=1,b=0,c=1");
    check('1','1','0', "a=1,b=1,c=0");
    check('1','1','1', "a=1,b=1,c=1");

    -- Report result
    if errors = 0 then
      report "PASS: process(all) correctly detects all input changes" severity note;
      stop(0);
    else
      report "FAIL: process(all) had " & integer'image(errors) & " errors"
        severity failure;
    end if;
    wait;
  end process;

end architecture;
-- TAKEAWAY: process(all) replaces manual sensitivity lists -- never miss a signal again.
