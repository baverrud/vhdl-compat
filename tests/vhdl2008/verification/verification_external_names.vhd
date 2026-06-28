-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: External (hierarchical) names — access signals across hierarchy
-- CATEGORY: verification
-- XREF: FT07
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2008, a testbench could only access the ports of the top-level
--   entity. Internal signals of sub-components were completely invisible.
--   Verification engineers had to either modify the RTL to expose internal
--   signals (undesirable) or use vendor-specific Tcl commands to peek inside.
--
--   VHDL-2008 introduced "external names" embedded in double angle brackets:
--       <<signal .path.to.signal : type>>
--   This allows a testbench to read (and even force) any signal anywhere in
--   the design hierarchy, without modifying the RTL at all.
--
--   Path components:
--     .       = root of the design (the top-level entity)
--     ^       = move up one level in the hierarchy
--     @       = root the path in a library/package
--
--   This test creates a simple two-level design (top → counter) and accesses
--   the counter's internal count value from the testbench via an external name.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

-- ============================================================================
-- A simple 4-bit counter (internal design — we want to peek at its "count")
-- ============================================================================
entity counter is
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    en    : in  std_logic;
    q     : out std_logic_vector(3 downto 0)
  );
end entity;

architecture rtl of counter is
  signal count : unsigned(3 downto 0) := (others => '0');
begin
  q <= std_logic_vector(count);

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        count <= (others => '0');
      elsif en = '1' then
        count <= count + 1;
      end if;
    end if;
  end process;
end architecture;

-- ============================================================================
-- Top-level wrapper: instantiates the counter
-- ============================================================================
entity top is
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    en  : in  std_logic;
    q   : out std_logic_vector(3 downto 0)
  );
end entity;

architecture structural of top is
begin
  uut : entity work.counter
    port map (
      clk => clk,
      rst => rst,
      en  => en,
      q   => q
    );
end architecture;

-- ============================================================================
-- Testbench: accesses counter's internal "count" via external name
-- ============================================================================
entity tb_external_names is
end entity;

architecture test of tb_external_names is
  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  signal en  : std_logic := '0';
  signal q   : std_logic_vector(3 downto 0);
  signal errors : natural := 0;

  constant CLK_PERIOD : time := 10 ns;

begin
  -- Instantiate the top-level design
  dut_top : entity work.top
    port map (
      clk => clk,
      rst => rst,
      en  => en,
      q   => q
    );

  -- Clock generator
  clk <= not clk after CLK_PERIOD / 2;

  -- --------------------------------------------------------------------------
  -- Stimulus + Checker — uses external name to peek at counter internals
  -- --------------------------------------------------------------------------
  stim_proc : process
    -- VHDL-2008 external name: access the "count" signal inside the counter
    -- The path is: top-level entity . top-level architecture . uut label . count
    alias internal_count is
      <<signal .tb_external_names.dut_top.uut.count : unsigned(3 downto 0)>>;
  begin
    report "==============================================" severity note;
    report "TEST: External (hierarchical) names" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- Reset
    wait for CLK_PERIOD * 2;
    rst <= '0';
    en  <= '1';
    wait for CLK_PERIOD;

    -- After first clock with en=1, internal count should be 1
    wait for CLK_PERIOD;
    if internal_count /= 1 then
      report "FAIL: after 1st tick, internal_count="
             & integer'image(to_integer(internal_count)) & " expected 1"
        severity error;
      errors <= errors + 1;
    end if;

    -- After 5 more clocks, count should be 6
    for i in 1 to 5 loop
      wait for CLK_PERIOD;
    end loop;
    if internal_count /= 6 then
      report "FAIL: after 6 ticks, internal_count="
             & integer'image(to_integer(internal_count)) & " expected 6"
        severity error;
      errors <= errors + 1;
    end if;

    -- The external name works — we read an internal signal without modifying RTL
    if errors = 0 then
      report "PASS: External names correctly read internal counter signal"
        severity note;
      stop(0);
    else
      report "FAIL: External names had " & integer'image(errors) & " errors"
        severity failure;
    end if;
    wait;
  end process;

end architecture;
-- TAKEAWAY: External names <<signal .path : type>> let testbenches peek at internal design signals without modifying RTL.
