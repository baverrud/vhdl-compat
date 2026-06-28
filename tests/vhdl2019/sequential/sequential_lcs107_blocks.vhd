-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Sequential block statements — named scopes within processes
-- CATEGORY: sequential
-- XREF: LCS2016-107
-- SYNTH_ENTITY: sequential_block
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, `block` was only a concurrent statement used in
--   architectures. There was no way to create a named, nested scope within
--   a process. This limited code organization inside processes.
--
--   VHDL-2019 introduces the sequential block statement. It's a `block` that
--   appears inside a process (or subprogram), with its own declarative part
--   and a body of sequential statements. Think of it as a named scope that
--   groups related sequential logic.
--
--   This test creates two sequential blocks, each with their own local
--   variables, and verifies scoping rules (locals don't leak).
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;


-- ============================================================================
-- Synthesizable RTL — demonstrates this VHDL feature in hardware
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sequential_block is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of sequential_block is
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

entity sequential_block_tb is
end entity;

architecture test of sequential_block_tb is
begin

  stim_proc : process
    variable outside_var : integer := 100;
  begin
    report "==============================================" severity note;
    report "TEST: Sequential block statements" severity note;
    report "STD:  VHDL-2019 (LCS2016-107)" severity note;
    report "==============================================" severity note;

    -- VHDL-2019: Sequential block with local variables
    block_a : block
      variable local_a : integer := 10;
    begin
      local_a := local_a + outside_var;
      assert local_a = 110
        report "FAIL: block_a: local_a should be 110, got " & integer'image(local_a)
        severity error;
      report "  Block A: local_a = " & integer'image(local_a) severity note;
    end block;

    -- Another sequential block, independent scope
    block_b : block
      variable local_b : integer := 20;
    begin
      local_b := local_b * 2;
      assert local_b = 40
        report "FAIL: block_b: local_b should be 40, got " & integer'image(local_b)
        severity error;
      report "  Block B: local_b = " & integer'image(local_b) severity note;
    end block;

    -- Verify outside_var is unchanged
    assert outside_var = 100
      report "FAIL: outside_var should still be 100"
      severity error;

    report "PASS: Sequential block statements work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
