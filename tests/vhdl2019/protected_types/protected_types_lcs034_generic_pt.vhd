-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Protected types with generic clause — parameterizable protected types
-- CATEGORY: protected_types
-- XREF: LCS2016-034
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2019, protected types had fixed internal types. A FIFO
--   protected type for std_logic_vector(7 downto 0) was a completely
--   different type from one for std_logic_vector(15 downto 0). You could
--   not parameterize the width or depth.
--
--   VHDL-2019 allows protected types to have a generic clause, just like
--   entities and packages. This enables a single generic protected type
--   to serve multiple use cases:
--     type fifo_t is protected
--       generic (WIDTH : positive; DEPTH : positive);
--       procedure push(data : std_logic_vector(WIDTH-1 downto 0));
--       ...
--
--   This test defines a generic protected counter parameterized by modulo.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_generic_pt is
end entity;

architecture test of tb_generic_pt is

  -- VHDL-2019: Generic protected type
  type mod_counter_t is protected
    generic (MODULO : positive := 10);
    procedure increment;
    impure function value return integer;
  end protected;

  type mod_counter_t is protected body
    generic (MODULO : positive := 10);
    variable count : integer := 0;
    procedure increment is
    begin
      if count = MODULO - 1 then
        count := 0;
      else
        count := count + 1;
      end if;
    end procedure;
    impure function value return integer is
    begin
      return count;
    end function;
  end protected body;

  shared variable mod5 : mod_counter_t;
  shared variable mod3 : mod_counter_t;

begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Protected types with generic clause" severity note;
    report "STD:  VHDL-2019 (LCS2016-034)" severity note;
    report "==============================================" severity note;

    -- Increment mod-5 counter 7 times (should wrap to 2)
    for i in 1 to 7 loop
      mod5.increment;
    end loop;
    assert mod5.value = 2
      report "FAIL: mod-5 after 7 increments should be 2, got "
             & integer'image(mod5.value)
      severity error;

    -- Increment mod-3 counter 5 times (should wrap to 2)
    for i in 1 to 5 loop
      mod3.increment;
    end loop;
    assert mod3.value = 2
      report "FAIL: mod-3 after 5 increments should be 2"
      severity error;

    report "PASS: Protected types with generic clause work correctly" severity note;
    stop(0);
    wait;
  end process;

end architecture;
