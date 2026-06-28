-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: Pointers to composites of protected types
-- CATEGORY: protected_types
-- XREF: LCS2016-014a
-- TEST_TYPE: sim
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

entity tb_pt_pointers is
end entity;

architecture test of tb_pt_pointers is

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
