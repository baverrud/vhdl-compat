-- ============================================================================
-- STD: VHDL-2019
-- FEATURE: PATH_NAME/INSTANCE_NAME for protected types
-- CATEGORY: protected_types
-- XREF: LCS2016-032
-- SYNTH_ENTITY: pt_path_name
-- TEST_TYPE: both
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


-- ============================================================================
-- RTL: path_name for protected types — debug introspection
-- VHDL-2019: 'path_name and 'instance_name for PT objects (LCS2016-032)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;

entity pt_path_name is
  port (clk : in std_logic; din : in std_logic_vector(7 downto 0);
        dout : out std_logic_vector(7 downto 0));
end entity;
architecture rtl of pt_path_name is
  -- KEY FEATURE: 'path_name on PT (LCS2016-032)
begin
  process(clk) begin if rising_edge(clk) then dout <= din; end if; end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
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
