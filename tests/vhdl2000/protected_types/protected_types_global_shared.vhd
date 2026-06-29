-- ============================================================================
-- STD: VHDL-2000
-- FEATURE: Global shared variables of protected types — package-level shared variables
-- CATEGORY: protected_types
-- SYNTH_ENTITY: global_shared
-- TEST_TYPE: sim
-- DESCRIPTION:
--   VHDL-2000 introduced protected types and requires shared variables to be
--   of a protected type. Verification frameworks like UVVM use protected
--   types for global infrastructure: loggers, alert managers, scoreboards,
--   and message queues shared across all testbench components.
--
--   However, VHDL does NOT allow declaring a shared variable of a protected
--   type in a package declarative part (the type body isn't visible yet).
--   UVVM's pattern is:
--     1. Declare the protected type interface in the package declaration
--     2. Provide wrapper subprograms in the package declaration
--     3. Declare the shared variable + protected type body in the package body
--     4. Wrapper subprograms internally delegate to the shared variable
--
--   This test reproduces that exact pattern and verifies that the shared
--   state persists correctly across multiple operations.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;

-- ============================================================================
-- Package: global_shared_pkg
-- Declares a protected type interface and wrapper subprograms that
-- internally access a package-body shared variable (UVVM pattern).
-- ============================================================================
package global_shared_pkg is

  -- Protected type: a thread-safe counter
  type global_counter is protected
    procedure increment;
    procedure increment_by(n : natural);
    impure function value return natural;
  end protected;

  -- KEY FEATURE: wrapper subprograms that delegate to a shared variable
  -- declared in the package body. This is the UVVM pattern:
  -- external code calls these procedures, which internally access
  -- the shared variable of protected type.
  procedure increment_global;
  procedure increment_global_by(n : natural);
  impure function read_global return natural;

end package;

package body global_shared_pkg is

  type global_counter is protected body
    variable count : natural := 0;

    procedure increment is
    begin
      count := count + 1;
    end procedure;

    procedure increment_by(n : natural) is
    begin
      count := count + n;
    end procedure;

    impure function value return natural is
    begin
      return count;
    end function;

  end protected body;

  -- KEY FEATURE: shared variable declared in package body, not visible
  -- outside but accessible via the wrapper subprograms above.
  -- This is exactly how UVVM hides its global state.
  shared variable global_ctr : global_counter;

  procedure increment_global is
  begin
    global_ctr.increment;
  end procedure;

  procedure increment_global_by(n : natural) is
  begin
    global_ctr.increment_by(n);
  end procedure;

  impure function read_global return natural is
  begin
    return global_ctr.value;
  end function;

end package body;


-- ============================================================================
-- RTL: global shared variable — package-level protected type variable
-- VHDL-2000: shared variables MUST be of a protected type
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity global_shared is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of global_shared is
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        dout <= (others => '0');
      else
        dout <= din;
      end if;
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.global_shared_pkg.all;

entity global_shared_tb is
end entity;

architecture test of global_shared_tb is
begin

  -- Main test process: uses the wrapper subprograms (UVVM pattern).
  -- The shared variable itself is hidden in the package body; external
  -- code calls the wrapper subprograms declared in the package header.
  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Global shared variables of protected types" severity note;
    report "STD:  VHDL-2000 (UVVM pattern)" severity note;
    report "==============================================" severity note;

    -- Initial value should be 0
    assert read_global = 0
      report "FAIL: initial value = " & natural'image(read_global)
             & ", expected 0"
      severity failure;

    -- Increment via wrapper subprograms (like UVVM's log/alert calls)
    increment_global;
    increment_global;
    increment_global_by(5);

    -- Check value after increments via wrapper function
    assert read_global = 7
      report "FAIL: after 2 increments + 5, value = "
             & natural'image(read_global) & ", expected 7"
      severity failure;

    report "PASS: read_global = " & natural'image(read_global)
           & " (expected 7)" severity note;

    -- More increments (simulating multiple verification calls)
    increment_global;
    increment_global;

    assert read_global = 9
      report "FAIL: final value = " & natural'image(read_global)
             & ", expected 9"
      severity failure;

    report "PASS: Final read_global = " & natural'image(read_global)
           & " (expected 9)" severity note;

    -- All checks passed
    report "PASS: Global shared variable test passed" severity note;

    -- Stop simulation cleanly
    assert false
      report "PASS: End of test"
      severity failure;
    wait;
  end process;

end architecture;

-- TAKEAWAY: UVVM hides global shared variables of protected types in the
-- package body, exposing only wrapper subprograms. This pattern provides
-- thread-safe global state (loggers, alert managers, scoreboards) without
-- violating VHDL's rule that shared variable declarations must come after
-- the protected type body is visible.
