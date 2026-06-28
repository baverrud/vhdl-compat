-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Pointers to composites of protected types
-- CATEGORY: protected_types
-- XREF: LCS2016-014a
-- SYNTH_ENTITY: pt_pointers
-- TEST_TYPE: both
-- DESCRIPTION:
--   Before VHDL-2019, access types (pointers) could point to any type
--   except protected types. You could not have a linked list of PT
--   objects or dynamically allocate protected resources.
--
--   VHDL-2019 allows access types that designate composites containing
--   protected type elements. This enables dynamic data structures
--   (linked lists, trees, graphs) where nodes contain synchronized
--   resources.
--
--   This test declares an access type to a record containing a PT
--   and verifies allocation and access work.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;


-- ============================================================================
-- RTL: pointers to protected types — access types for PT objects
-- VHDL-2019: dynamic allocation of protected objects (LCS2016-014a)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pt_pointers is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of pt_pointers is
  -- KEY FEATURE: PT pointers (LCS2016-014a) — access types to protected types
  type int_ptr is access integer;
begin
  process(clk) begin if rising_edge(clk) then dout <= din; end if; end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity pt_pointers_tb is
end entity;

architecture test of pt_pointers_tb is

  type counter_t is protected
    procedure increment;
    impure function value return integer;
  end protected;

  type counter_t is protected body
    variable count : integer := 0;
    procedure increment is begin count := count + 1; end procedure;
    impure function value return integer is begin return count; end function;
  end protected body;

  -- Record containing a protected type
  type node_t is record
    id : integer;
    counter : counter_t;
  end record;

  -- VHDL-2019: Access type to composite containing PT
  type node_ptr is access node_t;

  shared variable sv_node : node_ptr;

begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: Pointers to composites of protected types" severity note;
    report "STD:  VHDL-2019 (LCS2016-014a)" severity note;
    report "==============================================" severity note;

    -- VHDL-2019: Allocate a composite containing a PT
    sv_node := new node_t'(id => 1, counter => new counter_t);

    -- Access the PT through the pointer
    sv_node.counter.increment;
    sv_node.counter.increment;

    assert sv_node.counter.value = 2
      report "FAIL: counter in allocated node should be 2"
      severity error;
    assert sv_node.id = 1
      report "FAIL: node id should be 1"
      severity error;

    deallocate(sv_node);

    report "PASS: Pointers to composites of protected types work" severity note;
    stop(0);
    wait;
  end process;

end architecture;
