-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: PATH_NAME/INSTANCE_NAME for protected types
-- CATEGORY: protected_types
-- XREF: LCS2016-032
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2019, 'PATH_NAME and 'INSTANCE_NAME attributes were only
--   defined for signals and entities. Protected types and their shared
--   variables did not have these attributes, making it harder to include
--   context in error messages from protected type methods.
--
--   VHDL-2019 extends 'PATH_NAME and 'INSTANCE_NAME to protected type
--   variables (shared variables). This enables PT methods to report
--   their location in the design hierarchy.
--
--   This test verifies that 'PATH_NAME and 'INSTANCE_NAME can be accessed
--   on shared variables.
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity pt_path_name_tb is
end entity;

architecture test of pt_path_name_tb is

  type logger_t is protected
    procedure log(constant msg : string);
  end protected;

  type logger_t is protected body
    procedure log(constant msg : string) is
    begin
      report "LOG: " & msg severity note;
    end procedure;
  end protected body;

  shared variable sv_logger : logger_t;

begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: PATH_NAME/INSTANCE_NAME for protected types" severity note;
    report "STD:  VHDL-2019 (LCS2016-032)" severity note;
    report "==============================================" severity note;

    -- VHDL-2019: 'PATH_NAME and 'INSTANCE_NAME on shared variables
    -- Verify they return strings
    report "  Shared variable path: " & sv_logger'path_name severity note;
    report "  Shared variable instance: " & sv_logger'instance_name severity note;

    -- The path/instance names should be non-empty
    assert sv_logger'path_name'length > 0
      report "FAIL: 'path_name should return non-empty string"
      severity error;
    assert sv_logger'instance_name'length > 0
      report "FAIL: 'instance_name should return non-empty string"
      severity error;

    report "PASS: PATH_NAME/INSTANCE_NAME for protected types works" severity note;
    stop(0);
    wait;
  end process;

end architecture;
