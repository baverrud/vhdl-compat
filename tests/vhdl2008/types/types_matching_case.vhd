-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Matching case statement (case?) — don't-care aware pattern matching
-- CATEGORY: types
-- SYNTH_ENTITY: matching_case
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, decoding a std_logic_vector required verbose if-chains
--   where every bit had to be tested explicitly. VHDL-2008 adds ?= (matching
--   equality) which treats '-' as don't-care, and the case? statement which
--   uses ?= for comparison.
--
--   The ?= operator is defined in ieee.std_logic_1164 for VHDL-2008. It
--   returns true when two std_logic values match: '1' matches '1' and 'H',
--   '0' matches '0' and 'L', and '-' matches anything.
--
--   This test creates a simple instruction decoder using case? to demonstrate
--   don't-care bit matching on a 4-bit opcode.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;


-- ============================================================================
-- RTL: matching case statement (case?) — don't-care aware pattern matching
-- VHDL-2008: case? uses ?= matching with '-' as wildcard
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity matching_case is
  port (din : in std_logic_vector(3 downto 0); dout : out std_logic_vector(1 downto 0));
end entity;
architecture rtl of matching_case is
begin
  -- KEY FEATURE: case? uses ?= matching — '-' matches anything
  process(all)
  begin
    case? din is
      when "1---" => dout <= "00";  -- first bit = 1
      when "01--" => dout <= "01";  -- first two bits = 01
      when "001-" => dout <= "10";
      when others => dout <= "11";
    end case?;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity matching_case_tb is
end entity;

architecture test of matching_case_tb is
  signal opcode  : std_logic_vector(3 downto 0);
  signal decoded : string(1 to 8) := "UNKNOWN ";
begin

  -- --------------------------------------------------------------------------
  -- Instruction decoder using matching case
  -- --------------------------------------------------------------------------
  decoder_proc : process(opcode)
  begin
    case? opcode is
      when "00--" => decoded <= "NOP     ";   -- don't care on low 2 bits
      when "010-" => decoded <= "ADD     ";
      when "011-" => decoded <= "SUB     ";
      when "1000" => decoded <= "LOAD    ";   -- exact match
      when "1001" => decoded <= "STORE   ";
      when "101-" => decoded <= "JUMP    ";
      when "11--" => decoded <= "MISC    ";
      when others => decoded <= "ILLEGAL ";
    end case?;
  end process;

  -- --------------------------------------------------------------------------
  -- Stimulus + Checker
  -- --------------------------------------------------------------------------
  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Matching case statement (case?)" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- NOP group (00--)
    opcode <= "0000";  wait for 5 ns;
    assert decoded = "NOP     "
      report "FAIL: opcode 0000 should decode to NOP, got " & decoded
      severity error;

    opcode <= "0011";  wait for 5 ns;
    assert decoded = "NOP     "
      report "FAIL: opcode 0011 should decode to NOP (don't-care), got " & decoded
      severity error;

    -- ADD group (010-)
    opcode <= "0100";  wait for 5 ns;
    assert decoded = "ADD     "
      report "FAIL: opcode 0100 should decode to ADD, got " & decoded
      severity error;

    opcode <= "0101";  wait for 5 ns;
    assert decoded = "ADD     "
      report "FAIL: opcode 0101 should decode to ADD, got " & decoded
      severity error;

    -- SUB group (011-)
    opcode <= "0110";  wait for 5 ns;
    assert decoded = "SUB     "
      report "FAIL: opcode 0110 should decode to SUB, got " & decoded
      severity error;

    -- LOAD (1000 — exact)
    opcode <= "1000";  wait for 5 ns;
    assert decoded = "LOAD    "
      report "FAIL: opcode 1000 should decode to LOAD, got " & decoded
      severity error;

    -- STORE (1001 — exact)
    opcode <= "1001";  wait for 5 ns;
    assert decoded = "STORE   "
      report "FAIL: opcode 1001 should decode to STORE, got " & decoded
      severity error;

    -- JUMP group (101-)
    opcode <= "1010";  wait for 5 ns;
    assert decoded = "JUMP    "
      report "FAIL: opcode 1010 should decode to JUMP, got " & decoded
      severity error;

    opcode <= "1011";  wait for 5 ns;
    assert decoded = "JUMP    "
      report "FAIL: opcode 1011 should decode to JUMP, got " & decoded
      severity error;

    -- MISC group (11--)
    opcode <= "1100";  wait for 5 ns;
    assert decoded = "MISC    "
      report "FAIL: opcode 1100 should decode to MISC, got " & decoded
      severity error;

    opcode <= "1111";  wait for 5 ns;
    assert decoded = "MISC    "
      report "FAIL: opcode 1111 should decode to MISC, got " & decoded
      severity error;

    report "PASS: Matching case statement works correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
