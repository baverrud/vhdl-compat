-- ============================================================================
-- STD: VHDL-2008
-- FEATURE: IP encryption — protect tool directives for IP protection
-- CATEGORY: misc
-- TEST_TYPE: sim
-- DESCRIPTION:
--   Before VHDL-2008, VHDL source code was always plain text. IP vendors
--   sharing RTL with customers had to either:
--     1. Deliver unencrypted source (exposing their IP)
--     2. Deliver pre-compiled netlists (tool-specific, not portable)
--     3. Use third-party encryption tools
--
--   VHDL-2008 introduces the protect tool directive mechanism based on
--   IEEE 1735-2014 for IP encryption:
--     `protect begin
--       -- encrypted or protected code here
--     `protect end
--
--   Protect directives can specify:
--     `protect data_method = "aes128-cbc"
--     `protect encoding = (enctype = "base64")
--     `protect key_keyowner = "Mentor Graphics"
--     `protect key_method = "rsa"
--
--   This test verifies that protect directives are recognized by the
--   tool (at minimum, that the tool parses `protect without error).
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity ip_protect_tb is
end entity;

architecture test of ip_protect_tb is
  signal test_pass : boolean := false;
begin

  stim_proc : process
  begin
    report "==============================================" severity note;
    report "TEST: IP encryption (protect directives)" severity note;
    report "STD:  VHDL-2008" severity note;
    report "==============================================" severity note;

    -- VHDL-2008: protect directives for IP encryption
    -- These are tool directives, not executable VHDL.
    -- If the tool parses them without error, they are recognized.

    `protect begin
      report "  Inside protected region (plain-text VHDL still runs)" severity note;
      test_pass <= true;
    `protect end

    wait for 5 ns;

    assert test_pass = true
      report "FAIL: Code inside protect region did not execute"
      severity error;

    report "PASS: IP encryption (protect) directives are recognized" severity note;
    stop(0);
    wait;
  end process;

end architecture;
