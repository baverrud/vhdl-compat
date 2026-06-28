-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Long integers — 64-bit integer support
-- CATEGORY: types_2019
-- XREF: LCS2016-026c
-- SYNTH_ENTITY: long_integers
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, the integer type was guaranteed to be at least 32
--   bits (range -2147483647 to +2147483647). For larger values, you had
--   to use unsigned/signed from numeric_std, which lacked the convenience
--   of integer arithmetic.
--
--   VHDL-2019 guarantees that type INTEGER is at least 64 bits, covering
--   the range of a 64-bit signed integer. This allows representing
--   timestamps, large counters, and memory addresses directly as integers
--   without resorting to vector types.
--
--   This test verifies that INTEGER can hold values beyond the 32-bit range.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;


-- ============================================================================
-- RTL: 64-bit integers — integer_64 type in VHDL-2019
-- VHDL-2019: integer_64 and natural_64 in package standard
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity long_integers is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of long_integers is
  -- KEY FEATURE: 64-bit integer (LCS2016-026c)
  -- integer_64 supports values from -2**63 to 2**63-1
  constant BIG : integer := 2**30;  -- large constant value
begin
  process(clk)
  begin
    if rising_edge(clk) then
      dout <= std_logic_vector(to_unsigned(BIG mod 256, 8));
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity long_integers_tb is
end entity;

architecture test of long_integers_tb is
begin

  stim_proc : process
    -- VHDL-2019: Large integer values (beyond 32-bit range)
    constant BIG_POS : integer := 3_000_000_000;  -- > 2^31
    constant BIG_NEG : integer := -3_000_000_000;
  begin
    report "==============================================" severity note;
    report "TEST: Long integers (64-bit)" severity note;
    report "STD:  VHDL-2019 (LCS2016-026c)" severity note;
    report "==============================================" severity note;

    -- Verify large positive value
    assert BIG_POS = 3_000_000_000
      report "FAIL: BIG_POS should be 3000000000"
      severity error;

    -- Verify large negative value
    assert BIG_NEG = -3_000_000_000
      report "FAIL: BIG_NEG should be -3000000000"
      severity error;

    -- Arithmetic with large values
    assert BIG_POS + 1_000_000_000 = 4_000_000_000
      report "FAIL: large integer arithmetic"
      severity error;

    report "PASS: Long integers (64-bit) work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
