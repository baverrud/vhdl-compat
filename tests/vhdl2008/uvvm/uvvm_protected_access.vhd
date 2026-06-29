-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: Protected types with internal access types — UVVM dynamic data pattern
-- CATEGORY: uvvm
-- SYNTH_ENTITY: uvvm_protected_access
-- TEST_TYPE: sim
-- DESCRIPTION:
--   UVVM uses protected types that internally manage dynamic data
--   structures via access types (pointers). For example, the UVVM
--   command queue and logger internally allocate linked-list nodes
--   to store variable-length data.
--
--   This pattern requires the simulator to correctly handle:
--     - Access types declared inside protected type bodies
--     - ALLOCATE and DEALLOCATE within protected method calls
--     - Multiple processes accessing the same protected object
--       without memory corruption
--
--   Vivado xsim is known to crash (memory access violation) when
--   protected types contain complex dynamic structures, even though
--   basic protected types with simple scalar state work fine.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;

-- ============================================================================
-- Package: uvvm_queue_pkg
-- A protected queue using internal access types — mimics UVVM's
-- command queue pattern.
-- ============================================================================
package uvvm_queue_pkg is

  type integer_queue is protected
    procedure enqueue(val : integer);
    impure function  dequeue return integer;
    impure function  size    return natural;
    impure function  is_empty return boolean;
    procedure        clear;
  end protected;

end package;

package body uvvm_queue_pkg is

  type integer_queue is protected body

    -- KEY FEATURE: access type defined inside protected type body
    -- This is how UVVM builds dynamic data structures inside PTs.
    type node_t;
    type node_ptr is access node_t;
    type node_t is record
      value : integer;
      next_node : node_ptr;
    end record;

    variable head : node_ptr := null;
    variable tail : node_ptr := null;
    variable count : natural := 0;

    procedure enqueue(val : integer) is
      variable new_node : node_ptr;
    begin
      -- KEY FEATURE: dynamic allocation inside a protected method
      new_node := new node_t;
      new_node.value := val;
      new_node.next_node := null;

      if head = null then
        head := new_node;
        tail := new_node;
      else
        tail.next_node := new_node;
        tail := new_node;
      end if;
      count := count + 1;
    end procedure;

    impure function dequeue return integer is
      variable result : integer;
      variable old_head : node_ptr;
    begin
      assert head /= null
        report "dequeue from empty queue"
        severity failure;

      result := head.value;
      old_head := head;
      head := head.next_node;

      -- KEY FEATURE: dynamic deallocation inside a protected method
      deallocate(old_head);

      if head = null then
        tail := null;
      end if;
      count := count - 1;
      return result;
    end function;

    impure function size return natural is
    begin
      return count;
    end function;

    impure function is_empty return boolean is
    begin
      return count = 0;
    end function;

    procedure clear is
      variable current : node_ptr;
      variable next_node : node_ptr;
    begin
      current := head;
      while current /= null loop
        next_node := current.next_node;
        deallocate(current);
        current := next_node;
      end loop;
      head  := null;
      tail  := null;
      count := 0;
    end procedure;

  end protected body;

end package body;


-- ============================================================================
-- RTL: protected types with internal access types
-- Simple register entity (sim-only test, RTL not used by TB directly).
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uvvm_protected_access is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    din  : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of uvvm_protected_access is
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        dout <= (others => '0');
      else
        dout <= din;
      end if;
    end if;
  end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.uvvm_queue_pkg.all;

entity uvvm_protected_access_tb is
end entity;

architecture test of uvvm_protected_access_tb is
  -- KEY FEATURE: shared variable of a protected type that uses
  -- internal access types (mimics UVVM's command queue)
  shared variable queue : integer_queue;
begin

  stim_proc : process
    variable val : integer;
  begin
    report "==============================================" severity note;
    report "TEST: Protected types with internal access types" severity note;
    report "STD:  VHDL-2008 (UVVM dynamic data pattern)" severity note;
    report "==============================================" severity note;

    -- Initial state: queue should be empty
    assert queue.is_empty
      report "FAIL: new queue should be empty"
      severity failure;
    assert queue.size = 0
      report "FAIL: new queue size should be 0, got "
             & natural'image(queue.size)
      severity failure;
    report "PASS: Queue initially empty" severity note;

    -- Enqueue values (dynamic allocation via new)
    queue.enqueue(10);
    queue.enqueue(20);
    queue.enqueue(30);

    assert queue.size = 3
      report "FAIL: after 3 enqueues, size should be 3, got "
             & natural'image(queue.size)
      severity failure;
    report "PASS: Queue size = 3 after 3 enqueues" severity note;

    -- Dequeue values (dynamic deallocation via deallocate)
    val := queue.dequeue;
    assert val = 10
      report "FAIL: first dequeue should be 10, got " & integer'image(val)
      severity failure;
    report "PASS: First dequeue = 10" severity note;

    val := queue.dequeue;
    assert val = 20
      report "FAIL: second dequeue should be 20, got " & integer'image(val)
      severity failure;
    report "PASS: Second dequeue = 20" severity note;

    val := queue.dequeue;
    assert val = 30
      report "FAIL: third dequeue should be 30, got " & integer'image(val)
      severity failure;
    report "PASS: Third dequeue = 30" severity note;

    -- Queue should be empty again
    assert queue.is_empty
      report "FAIL: queue should be empty after draining"
      severity failure;
    report "PASS: Queue empty after draining" severity note;

    -- Interleaved enqueue/dequeue (stress test for dynamic alloc/free)
    for i in 1 to 50 loop
      queue.enqueue(i);
    end loop;
    assert queue.size = 50
      report "FAIL: after 50 enqueues, size should be 50, got "
             & natural'image(queue.size)
      severity failure;

    for i in 1 to 50 loop
      val := queue.dequeue;
      assert val = i
        report "FAIL: expected " & integer'image(i) & ", got "
               & integer'image(val)
        severity failure;
    end loop;

    assert queue.is_empty
      report "FAIL: queue should be empty after 50 dequeues"
      severity failure;
    report "PASS: 50 enqueue/dequeue cycles completed correctly" severity note;

    -- Clean up (free any remaining memory)
    queue.clear;

    report "PASS: Protected types with internal access types test passed" severity note;

    assert false
      report "PASS: End of test"
      severity failure;
    wait;
  end process;

end architecture;

-- TAKEAWAY: Protected types with internal access types (pointers) enable
-- UVVM's dynamic data structures — command queues, log buffers, linked
-- lists. Simulators must correctly handle allocate/deallocate within
-- protected method calls. Vivado xsim is reported to crash (memory
-- access violation) on this pattern in UVVM's actual codebase.
