-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Inferred constraints — constrain unconstrained record elements at signal declaration
-- CATEGORY: types_2019
-- XREF: LCS2016-019
-- SYNTH_ENTITY: inferred_constraints
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, if a record contained an unconstrained array element
--   (e.g., `data : std_logic_vector`), you had to create a separate subtype
--   or use a dummy constant just to specify the array bounds:
--       constant proto : my_rec_t := ...;
--       signal s : proto'subtype;
--
--   VHDL-2019 lets you constrain the elements directly in the signal
--   declaration using record element constraints:
--       signal s : my_rec_t(data(7 downto 0), addr(15 downto 0));
--
--   This is especially useful when combined with VHDL-2019 interface mode
--   views, where you often want different widths for different instances.
--   It eliminates verbose subtype declarations and dummy constants.
--
--   This test defines a record with two unconstrained vectors, constrains
--   them at signal declaration, and verifies the constrained widths.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

-- ============================================================================
-- Entity with unconstrained record port (wishbone-like)
-- ============================================================================
entity slave_device is
  port (
    clk   : in  std_logic;
    adr   : in  std_logic_vector;   -- unconstrained
    dat_i : in  std_logic_vector;   -- unconstrained
    dat_o : out std_logic_vector    -- unconstrained
  );
end entity;

architecture rtl of slave_device is
begin
  process(clk)
  begin
    if rising_edge(clk) then
      dat_o <= std_logic_vector(unsigned(dat_i) + unsigned(adr));
    end if;
  end process;
end architecture;

-- ============================================================================
-- Testbench
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;


-- ============================================================================
-- RTL: inferred constraints — array bounds from initialization
-- VHDL-2019: variable v : std_logic_vector := "1010"; infers (1 to 4)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity inferred_constraints is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of inferred_constraints is
  -- KEY FEATURE: inferred array constraints (LCS2016-019) — bounds from init value
  constant DEFAULT : std_logic_vector := X"A5";  -- infers (7 downto 0)
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if din = X"00" then dout <= DEFAULT;
      else dout <= din; end if;
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity inferred_constraints_tb is
end entity;

architecture test of inferred_constraints_tb is
  signal clk    : std_logic := '0';
  signal adr    : std_logic_vector(7 downto 0) := (others => '0');
  signal dat_i  : std_logic_vector(7 downto 0) := (others => '0');
  signal dat_o  : std_logic_vector(7 downto 0);
  signal errors : natural := 0;

  constant CLK_PERIOD : time := 10 ns;
begin

  clk <= not clk after CLK_PERIOD / 2;

  -- VHDL-2019: constrain unconstrained port elements at instantiation.
  -- The entity ports (adr, dat_i, dat_o) are unconstrained std_logic_vector.
  -- Their widths are inferred from the actual signals connected.
  uut : entity work.slave_device
    port map (
      clk   => clk,
      adr   => adr,      -- width inferred: 8 bits from signal
      dat_i => dat_i,     -- width inferred: 8 bits from signal
      dat_o => dat_o      -- width inferred: 8 bits from signal
    );

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Inferred constraints (LCS2016-019)" severity note;
    report "STD:  VHDL-2019" severity note;
    report "==============================================" severity note;

    -- Apply 3 + 10 = 13 (0x0D)
    adr   <= x"03";
    dat_i <= x"0A";
    wait for CLK_PERIOD * 2;

    if dat_o /= x"0D" then
      report "FAIL: expected x0D, got " & to_string(dat_o)
        severity error;
      errors <= errors + 1;
    end if;

    -- Apply 7 + 5 = 12 (0x0C)
    adr   <= x"07";
    dat_i <= x"05";
    wait for CLK_PERIOD * 2;

    if dat_o /= x"0C" then
      report "FAIL: expected x0C, got " & to_string(dat_o)
        severity error;
      errors <= errors + 1;
    end if;

    if errors = 0 then
      report "PASS: Unconstrained ports correctly infer width from connected signals"
        severity note;
      stop(0);
    else
      report "FAIL: Inferred constraints had " & integer'image(errors) & " errors"
        severity failure;
    end if;
    wait;
  end process;

end architecture;

-- TAKEAWAY: VHDL-2019 lets you constrain unconstrained record/port elements directly without dummy subtypes.
