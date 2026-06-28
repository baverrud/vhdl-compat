-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: If-generate with elsif/else — multi-way conditional elaboration
-- CATEGORY: generate
-- SYNTH_ENTITY: if_elsif_generate
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, if-generate had no elsif or else. Multi-way elaboration
--   required deeply nested if-generate statements:
--       g1: if COND1 generate
--         ...
--       else generate
--         g2: if COND2 generate
--           ...
--         else generate
--           ...
--         end generate;
--       end generate;
--   This was hard to read and maintain.
--
--   VHDL-2008 adds elsif and else to if-generate, matching the if statement
--   syntax. The conditions are evaluated at elaboration time, not runtime.
--
--   This test uses generics to select between three implementations.
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

entity if_elsif_generate is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of if_elsif_generate is
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

entity if_elsif_generate_tb is
  generic (
    IMPL : integer := 0   -- 0=and, 1=or, 2=xor
  );
end entity;

architecture test of if_elsif_generate_tb is
  signal a, b : std_logic_vector(3 downto 0) := X"0";
  signal result : std_logic_vector(3 downto 0);
begin

  -- VHDL-2008: if-generate with elsif and else
  gen_impl : if IMPL = 0 generate
    result <= a and b;
  elsif IMPL = 1 generate
    result <= a or b;
  elsif IMPL = 2 generate
    result <= a xor b;
  else generate
    result <= a;   -- pass-through
  end generate;

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: If-generate with elsif/else" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    a <= X"5";  b <= X"3";   -- 0101 and 0011
    wait for 5 ns;

    if IMPL = 0 then
      assert result = (X"5" and X"3")
        report "FAIL: IMPL=0 (AND): expected 0001, got " & to_string(result)
        severity error;
    elsif IMPL = 1 then
      assert result = (X"5" or X"3")
        report "FAIL: IMPL=1 (OR): expected 0111, got " & to_string(result)
        severity error;
    elsif IMPL >= 2 then
      assert result = (X"5" xor X"3")
        report "FAIL: IMPL=2 (XOR): expected 0110, got " & to_string(result)
        severity error;
    end if;

    report "PASS: If-generate with elsif works (IMPL=" & integer'image(IMPL) & ")" severity note;
    stop(0);
    wait;
  end process;

end architecture;
