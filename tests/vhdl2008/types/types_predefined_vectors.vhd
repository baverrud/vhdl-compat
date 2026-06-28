-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Predefined array types — boolean_vector, integer_vector, real_vector, time_vector
-- CATEGORY: types
-- SYNTH_ENTITY: predefined_vectors
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, the only standard array type was bit_vector and
--   std_logic_vector (from ieee). If you wanted an array of booleans,
--   integers, or reals, you had to declare your own type:
--       type bool_array is array (natural range <>) of boolean;
--
--   VHDL-2008 adds predefined unconstrained array types in the standard
--   package:
--     boolean_vector — array of boolean
--     integer_vector — array of integer
--     real_vector    — array of real
--     time_vector    — array of time
--
--   These are to boolean/integer/real/time what std_logic_vector is to
--   std_logic. They enable generic array manipulation without custom types.
--
--   This test verifies declaration, assignment, and indexing of each.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;


-- ============================================================================
-- RTL: predefined vector types — boolean_vector, integer_vector
-- VHDL-2008: new standard array types beyond std_logic_vector
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity predefined_vectors is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of predefined_vectors is
  -- KEY FEATURE: boolean_vector — array of boolean, new in VHDL-2008
  signal bv : boolean_vector(0 to 7);
  -- KEY FEATURE: integer_vector — array of integer, new in VHDL-2008
  signal iv : integer_vector(0 to 7);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      for i in 0 to 7 loop
        bv(i) <= (din(i) = '1');
        iv(i) <= to_integer(unsigned(din(i downto i)));
      end loop;
      dout <= din;
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity predefined_vectors_tb is
end entity;

architecture test of predefined_vectors_tb is
  -- VHDL-2008: predefined vector types
  signal bv : boolean_vector(0 to 3);
  signal iv : integer_vector(0 to 3);
  signal rv : real_vector(0 to 3);
  signal tv : time_vector(0 to 3);
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Predefined vector types (boolean_vector, integer_vector, real_vector, time_vector)" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- boolean_vector
    bv <= (true, false, true, false);
    wait for 5 ns;
    assert bv(0) = true
      report "FAIL: boolean_vector(0) should be true"
      severity error;
    assert bv(1) = false
      report "FAIL: boolean_vector(1) should be false"
      severity error;

    -- integer_vector
    iv <= (10, 20, 30, 40);
    wait for 5 ns;
    assert iv(0) = 10
      report "FAIL: integer_vector(0) should be 10"
      severity error;
    assert iv(3) = 40
      report "FAIL: integer_vector(3) should be 40"
      severity error;

    -- real_vector
    rv <= (1.0, 2.5, 3.14, 99.0);
    wait for 5 ns;
    assert rv(1) = 2.5
      report "FAIL: real_vector(1) should be 2.5"
      severity error;

    -- time_vector
    tv <= (1 ns, 2 ns, 3 ns, 4 ns);
    wait for 5 ns;
    assert tv(2) = 3 ns
      report "FAIL: time_vector(2) should be 3 ns"
      severity error;

    report "PASS: Predefined vector types work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
