-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Aggregates as assignment targets — using aggregates on the left-hand side of <=
-- CATEGORY: aggregates
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2008, aggregates could only appear on the right-hand side
--   of assignments (as expressions). You could not assign TO multiple
--   signals or variables at once using an aggregate on the left.
--
--   VHDL-2008 allows aggregates as assignment targets:
--     (sig_a, sig_b) <= some_record;   -- splits a record into signals
--     (a, b) <= std_logic_vector'(c & d);  -- splits a vector
--
--   This is especially useful for unpacking records or splitting
--   concatenated values without intermediate signals.
--
--   This test verifies aggregate targets with records and arrays.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_aggregate_targets is
end entity;

architecture test of tb_aggregate_targets is
  type pair_t is record
    hi : std_logic_vector(3 downto 0);
    lo : std_logic_vector(3 downto 0);
  end record;

  signal pair   : pair_t;
  signal hi_sig : std_logic_vector(3 downto 0);
  signal lo_sig : std_logic_vector(3 downto 0);
  signal a, b   : std_logic;
  signal vec    : std_logic_vector(1 downto 0);
begin

  stim_proc : process
    variable v_hi, v_lo : std_logic_vector(3 downto 0);
  begin
    report "==============================================" severity note;
    report "TEST: Aggregates as assignment targets" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- VHDL-2008: Aggregate target — split a record into two signals
    pair.hi <= X"A";
    pair.lo <= X"5";
    wait for 1 ns;
    (hi_sig, lo_sig) <= pair;
    wait for 1 ns;
    assert hi_sig = X"A"
      report "FAIL: hi_sig should be A, got " & to_string(hi_sig)
      severity error;
    assert lo_sig = X"5"
      report "FAIL: lo_sig should be 5, got " & to_string(lo_sig)
      severity error;

    -- VHDL-2008: Aggregate target with variables
    v_hi := X"F";
    v_lo := X"0";
    -- Swap using a temporary (aggregate target on LHS only)
    (v_hi, v_lo) := std_logic_vector'(v_lo & v_hi);  -- explicit type
    assert v_hi = X"0" and v_lo = X"F"
      report "FAIL: variable assign via aggregate target failed"
      severity error;

    -- VHDL-2008: Aggregate target from vector
    vec <= "10";
    wait for 1 ns;
    (a, b) <= vec;
    wait for 1 ns;
    assert a = '1' and b = '0'
      report "FAIL: (a,b) <= '10' should set a='1', b='0'"
      severity error;

    report "PASS: Aggregates as assignment targets work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
