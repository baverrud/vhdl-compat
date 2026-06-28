-- ============================================================================
-- VHDL Compatibility Test Suite — TEMPLATE
-- ============================================================================
-- Copy this file to create a new test. Fill in the metadata below.
-- See docs/test-format.md for the full specification.
-- ============================================================================
--
-- STD: VHDL-XXXX          <-- Which standard introduced this feature?
-- FEATURE: short name — one line description
-- CATEGORY: category_name
-- XREF: LCS2016-XXX        <-- IEEE reference (LCS number for VHDL-2019, FT number for VHDL-2008, omit if none)
-- TEST_TYPE: sim           <-- "sim", "synth", "both", or "backcompat"
-- DESCRIPTION:
--   Explain the feature here in plain language. What is it? Why was it added
--   to VHDL? What problem does it solve? What would the code look like before
--   this feature existed?
--
--   A reader browsing this file should come away understanding:
--   1. What the feature does
--   2. Why it exists (the motivation)
--   3. How to use it (the code shows this)
--   4. What happened before (verbosity, bugs, workarounds)
-- ============================================================================

-- ============================================================================
-- Libraries
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

-- ============================================================================
-- Entity (testbench — no ports for simulation tests)
-- ============================================================================
entity tb_template is
end entity;

-- ============================================================================
-- Architecture
-- ============================================================================
architecture test of tb_template is

  -- --------------------------------------------------------------------------
  -- Signals / shared variables / constants
  -- --------------------------------------------------------------------------
  signal clk   : std_logic := '0';
  signal rst   : std_logic := '1';
  signal input : std_logic := '0';
  signal output : std_logic;

  -- Clock period
  constant CLK_PERIOD : time := 10 ns;

begin

  -- --------------------------------------------------------------------------
  -- Clock generator (optional — only if your test needs a clock)
  -- --------------------------------------------------------------------------
  clk_proc : process
  begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;
  end process;

  -- --------------------------------------------------------------------------
  -- Device Under Test (optional — instantiate the entity that uses the feature)
  -- --------------------------------------------------------------------------
  -- uut : entity work.my_design
  --   port map (
  --     clk   => clk,
  --     rst   => rst,
  --     d     => input,
  --     q     => output
  --   );

  -- --------------------------------------------------------------------------
  -- Stimulus + Checker process
  -- --------------------------------------------------------------------------
  stim_proc : process
  begin
    -- 1. Report what we're testing
    report "==============================================" severity note;
    report "TEST: <feature name>" severity note;
    report "STD:  <standard>" severity note;
    report "==============================================" severity note;

    -- 2. Initialize
    report "Initializing..." severity note;
    wait for CLK_PERIOD * 2;
    rst <= '0';
    wait for CLK_PERIOD;

    -- 3. Apply stimulus and check results
    -- Replace with your actual test logic
    report "Applying stimulus..." severity note;

    -- Example assertion:
    -- assert output = expected_value
    --   report "FAIL: <feature> — output was " & to_string(output)
    --          & " but expected " & to_string(expected_value)
    --   severity error;

    -- 4. Report result
    -- If we reach here without assertion failures:
    report "PASS: <feature> works correctly" severity note;
    stop(0);  -- Exit with success code
    wait;
  end process;

end architecture;
