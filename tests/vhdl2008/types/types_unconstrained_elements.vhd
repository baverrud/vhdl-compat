-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Unconstrained element types — records with unconstrained array fields
-- CATEGORY: types
-- SYNTH_ENTITY: unconstrained_elements
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2008, every element of a record type had to be fully
--   constrained. You could not have a record with a field like
--   "data : std_logic_vector" (without a range). This meant you had to either
--   pick a fixed width (limiting reuse) or use multiple record types.
--
--   VHDL-2008 allows unconstrained array elements in record types. The array
--   bounds are determined when a signal or variable of that record type is
--   declared. This is the record equivalent of unconstrained ports.
--
--   This test defines a record with an unconstrained std_logic_vector field,
--   then declares signals with different widths and verifies they work.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

-- ============================================================================
-- Package: defines a record with an unconstrained array element
-- ============================================================================
package unconstrained_pkg is
  -- VHDL-2008: unconstrained element type — no range specified
  type payload_t is record
    addr : std_logic_vector;   -- unconstrained!
    data : std_logic_vector;   -- unconstrained!
    valid : std_logic;
  end record;
end package;

-- Re-import needed by entity/architecture below
library ieee;
use ieee.std_logic_1164.all;
use std.env.all;
use work.unconstrained_pkg.all;


-- ============================================================================
-- RTL: unconstrained element types — records with varying array fields
-- VHDL-2008: record with std_logic_vector (no range constraint)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity unconstrained_elements is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of unconstrained_elements is
  -- KEY FEATURE: unconstrained record — data field width set at declaration
  type payload_t is record
    addr : std_logic_vector;  -- unconstrained!
    data : std_logic_vector;  -- unconstrained!
    valid : std_logic;
  end record;
  signal p : payload_t(addr(3 downto 0), data(7 downto 0));
begin
  process(clk)
  begin
    if rising_edge(clk) then
      p.addr <= din(3 downto 0);
      p.data <= din;
      p.valid <= '1';
      dout <= p.data;
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.unconstrained_pkg.all;

entity unconstrained_elements_tb is
end entity;

architecture test of unconstrained_elements_tb is
  -- VHDL-2008: constrain the unconstrained elements at declaration
  signal narrow : payload_t(addr(3 downto 0), data(7 downto 0));
  signal wide   : payload_t(addr(7 downto 0), data(15 downto 0));
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Unconstrained element types in records" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- Drive narrow payload
    narrow.addr  <= X"3";
    narrow.data  <= X"A5";
    narrow.valid <= '1';
    wait for 5 ns;

    assert narrow.addr = X"3"
      report "FAIL: narrow.addr should be X'3'"
      severity error;
    assert narrow.data = X"A5"
      report "FAIL: narrow.data should be X'A5'"
      severity error;
    assert narrow.valid = '1'
      report "FAIL: narrow.valid should be '1'"
      severity error;

    -- Drive wide payload (different widths, same record type)
    wide.addr  <= X"5A";
    wide.data  <= X"BEEF";
    wide.valid <= '0';
    wait for 5 ns;

    assert wide.addr = X"5A"
      report "FAIL: wide.addr should be X'5A'"
      severity error;
    assert wide.data = X"BEEF"
      report "FAIL: wide.data should be X'BEEF'"
      severity error;
    assert wide.valid = '0'
      report "FAIL: wide.valid should be '0'"
      severity error;

    -- Verify narrow still holds its values
    assert narrow.addr = X"3"
      report "FAIL: narrow.addr changed unexpectedly"
      severity error;

    report "PASS: Unconstrained element types work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
