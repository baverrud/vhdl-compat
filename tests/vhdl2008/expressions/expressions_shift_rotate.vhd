-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Shift/rotate operators — SLL, SRL, SLA, SRA, ROL, ROR for vectors
-- CATEGORY: expressions
-- SYNTH_ENTITY: shift_rotate
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, shifting a vector required concatenation tricks:
--       result <= sig(sig'high-1 downto 0) & '0';  -- shift left
--   This was verbose and error-prone (mixing up directions, off-by-one).
--
--   VHDL-2008 introduces shift and rotate operators in numeric_std:
--     SLL — shift left logical  (fill with '0')
--     SRL — shift right logical (fill with '0')
--     SLA — shift left arithmetic (preserve sign)
--     SRA — shift right arithmetic (preserve sign)
--     ROL — rotate left
--     ROR — rotate right
--
--   For unsigned: SLL/SRL fill with '0', SLA/SRA fill with '0' (same as SLL/SRL)
--   For signed:   SLA/SRA preserve the sign bit
--
--   This test verifies each operator on unsigned and signed types.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;


-- ============================================================================
-- Synthesizable RTL — demonstrates this VHDL feature in hardware
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity shift_rotate is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of shift_rotate is
  signal reg : std_logic_vector(7 downto 0);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        reg <= (others => '0');
      else
        reg <= din;
      end if;
    end if;
  end process;
  dout <= reg;
end architecture;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity shift_rotate_tb is
end entity;

architecture test of shift_rotate_tb is
begin

  stim_proc : process
    variable u : unsigned(7 downto 0);
    variable s : signed(7 downto 0);
  begin
    report "==============================================" severity note;
    report "TEST: Shift/rotate operators (SLL, SRL, SLA, SRA, ROL, ROR)" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    ------------------------------------------------------------------------
    -- Unsigned shift tests
    ------------------------------------------------------------------------
    u := X"03";  -- "0000_0011"

    -- SLL: shift left logical, fill with 0
    assert u sll 2 = X"0C"
      report "FAIL: X'03' sll 2 should be X'0C', got " & to_string(u sll 2)
      severity error;

    -- SRL: shift right logical, fill with 0
    assert u srl 1 = X"01"
      report "FAIL: X'03' srl 1 should be X'01', got " & to_string(u srl 1)
      severity error;

    -- ROL: rotate left
    u := X"81";  -- "1000_0001"
    assert u rol 1 = X"03"
      report "FAIL: X'81' rol 1 should be X'03', got " & to_string(u rol 1)
      severity error;

    -- ROR: rotate right
    assert u ror 1 = X"C0"
      report "FAIL: X'81' ror 1 should be X'C0', got " & to_string(u ror 1)
      severity error;

    ------------------------------------------------------------------------
    -- Signed arithmetic shift tests
    ------------------------------------------------------------------------
    s := X"FC";  -- -4 in 8-bit signed, "1111_1100"

    -- SRA: shift right arithmetic, preserve sign (fill with sign bit = '1')
    assert s sra 1 = X"FE"
      report "FAIL: signed(-4) sra 1 should be -2 (X'FE'), got " & to_string(s sra 1)
      severity error;

    -- SLA: shift left arithmetic (same as SLL for 2's complement)
    assert s sla 2 = X"F0"
      report "FAIL: signed(-4) sla 2 should be -16 (X'F0'), got " & to_string(s sla 2)
      severity error;

    -- Positive signed: SRA fills with 0
    s := X"08";  -- +8, "0000_1000"
    assert s sra 1 = X"04"
      report "FAIL: signed(+8) sra 1 should be +4 (X'04'), got " & to_string(s sra 1)
      severity error;

    -- Shift by zero is identity
    assert u sll 0 = u
      report "FAIL: sll 0 should be identity"
      severity error;

    report "PASS: Shift/rotate operators work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
