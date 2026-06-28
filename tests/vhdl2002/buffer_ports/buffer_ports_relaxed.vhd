-- ============================================================================
-- STD: VHDL-2002
-- FEATURE: Relaxed buffer port rules -- buffer ports can connect to out ports
-- CATEGORY: buffer_ports
-- TEST_TYPE: sim
-- DESCRIPTION:
--   In VHDL-93, a port of mode `buffer` could only be connected to another
--   `buffer` port, never to an `out` port. This was restrictive: if a
--   sub-component had a buffer port (because it needed to read its own
--   output), you couldn't connect it to a top-level `out` port.
--
--   VHDL-2002 relaxed this rule: a `buffer` port can now be connected to
--   an `out` port. This eliminated a common source of port-mode conflicts
--   and made hierarchical design easier.
--
--   This test creates an entity with a buffer port (reads its own output),
--   then instantiates it connected to a top-level out port. This would
--   fail in VHDL-93 but passes in VHDL-2002+.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

-- ============================================================================
-- Entity with a buffer port — it reads its own output to compute next state.
-- In VHDL-93, this port could only connect to another buffer port.
-- ============================================================================
entity toggle is
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    q   : buffer std_logic  -- VHDL-2002: buffer can connect to out
  );
end entity;

architecture rtl of toggle is
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        q <= '0';
      else
        q <= not q;  -- reads its own output (why it's buffer, not out)
      end if;
    end if;
  end process;
end architecture;

-- ============================================================================
-- Testbench: connects the buffer port to a top-level out port
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_buffer_ports is
end entity;

architecture test of tb_buffer_ports is
  signal clk    : std_logic := '0';
  signal rst    : std_logic := '1';
  signal q_out  : std_logic;  -- VHDL-2002: out port, connected to buffer below
  signal errors : natural := 0;
  constant CLK_PERIOD : time := 10 ns;
begin

  clk <= not clk after CLK_PERIOD / 2;

  -- VHDL-2002: buffer port connected to out port — illegal in VHDL-93
  uut : entity work.toggle
    port map (
      clk => clk,
      rst => rst,
      q   => q_out
    );

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Relaxed buffer port rules" severity note;
    report "STD:  VHDL-2002" severity note;
    report "==============================================" severity note;

    wait for CLK_PERIOD * 2;
    rst <= '0';
    wait for CLK_PERIOD * 2;

    -- After reset release and 2 clocks, q should have toggled twice: 0→1→0
    if q_out /= '0' then
      report "FAIL: q_out=" & std_logic'image(q_out) & " expected 0"
        severity error;
      errors <= errors + 1;
    end if;

    wait for CLK_PERIOD;
    -- After 3rd clock: 0→1
    if q_out /= '1' then
      report "FAIL: q_out=" & std_logic'image(q_out) & " expected 1"
        severity error;
      errors <= errors + 1;
    end if;

    if errors = 0 then
      report "PASS: Buffer port connected to out port -- VHDL-2002 relaxation works"
        severity note;
      stop(0);
    else
      report "FAIL: Buffer ports had " & integer'image(errors) & " errors"
        severity failure;
    end if;
    wait;
  end process;

end architecture;

-- TAKEAWAY: VHDL-2002 relaxed buffer port rules — buffer ports can now connect to out ports, fixing a common VHDL-93 annoyance.
