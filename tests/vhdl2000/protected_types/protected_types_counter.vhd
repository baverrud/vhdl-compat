-- ============================================================================
-- STD: VHDL-2000
-- FEATURE: Protected types -- class-like constructs with mutual exclusion
-- CATEGORY: protected_types
-- TEST_TYPE: sim
-- DESCRIPTION:
--   VHDL-2000 introduced protected types — the biggest addition to the
--   language since VHDL-93. A protected type is like a class in OOP: it
--   bundles private data with public methods (functions and procedures)
--   that provide controlled access. All access is mutually exclusive —
--   only one process can execute a method at a time.
--
--   Protected types are the foundation for shared variables (VHDL-2000
--   requires shared variables to be of a protected type) and enable
--   thread-safe data structures like scoreboards, memories, and random
--   number generators in verification.
--
--   This test creates a simple protected counter with increment and get
--   methods, then uses a shared variable to access it from the testbench.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

-- ============================================================================
-- Protected type: a thread-safe counter (declared in a package)
-- ============================================================================
package counter_pkg is
  type protected_counter is protected
    procedure increment;
    impure function value return integer;
  end protected;
end package;

package body counter_pkg is
  type protected_counter is protected body
    variable count : integer := 0;
    procedure increment is
    begin
      count := count + 1;
    end procedure;
    impure function value return integer is
    begin
      return count;
    end function;
  end protected body;
end package body;

use work.counter_pkg.all;

-- ============================================================================
-- Testbench
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use std.env.all;
use work.counter_pkg.all;

entity protected_types_tb is
end entity;

architecture test of protected_types_tb is
  -- VHDL-2000: shared variables must be of a protected type
  shared variable counter : protected_counter;
  signal errors : natural := 0;
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Protected types" severity note;
    report "STD:  VHDL-2000" severity note;
    report "==============================================" severity note;

    -- Initial value should be 0
    if counter.value /= 0 then
      report "FAIL: initial value=" & integer'image(counter.value) & " expected 0"
        severity error;
      errors <= errors + 1;
    end if;

    -- Increment should work
    counter.increment;
    counter.increment;
    counter.increment;

    if counter.value /= 3 then
      report "FAIL: after 3 increments, value=" & integer'image(counter.value)
             & " expected 3"
        severity error;
      errors <= errors + 1;
    end if;

    if errors = 0 then
      report "PASS: Protected type counter works correctly" severity note;
      stop(0);
    else
      report "FAIL: Protected types had " & integer'image(errors) & " errors"
        severity failure;
    end if;
    wait;
  end process;

end architecture;

-- TAKEAWAY: VHDL-2000 protected types provide thread-safe, class-like data structures — the foundation of modern VHDL verification.
