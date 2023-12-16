--  
--  File:   core_package.vhd
--  Brief:  TODO
--
--  Copyright (C) 2023 Nick Chan
--  See the LICENSE file at the root of the project for licensing info.
--  

library ieee;
use ieee.std_logic_1164.all;

package core_package is
  
  -- In RISC-V, a word is 32 bits
  subtype word_t is std_logic_vector(31 downto 0);
  
  type word_array_t is array(natural range <>) of word_t;

  -- Register file select
  subtype rf_sel_t is std_logic_vector(4 downto 0);

  -- Control signal bus
  type ctrl_bus_t is record
    pc_we             : std_logic;                    -- Program counter write enable
    cmp_opcode        : std_logic_vector(2 downto 0); -- Comparison opcode
    cond_branch_en    : std_logic;                    -- Conditional branch enable
    uncond_branch_en  : std_logic;                    -- Unconditional branch enable
    rs1_sel           : rf_sel_t;                     -- Register source 1 select
    rs2_sel           : rf_sel_t;                     -- Register source 2 select
    rd_sel            : rf_sel_t;                     -- Register destination select
    rd_we             : std_logic;                    -- Register destination write enable
    rd_wd_sel         : std_logic_vector(1 downto 0); -- Register destination write data select
    alu_opcode        : std_logic_vector(3 downto 0); -- ALU opcode
    alu_operand1_sel  : std_logic_vector(1 downto 0); -- ALU operand 1 select
    alu_operand2_sel  : std_logic;                    -- ALU operand 2 select
    dmem_en           : std_logic;                    -- Data memory enable
    dmem_we           : std_logic;                    -- Data memory write enable
    dmem_dtype        : std_logic_vector(2 downto 0); -- Data memory data type
  end record;

  -- Instruction opcodes

  -- Memory regions
  constant MREGION_BOOT_ROM : word_t := x"10000000";
  constant MREGION_TIMER    : word_t := x"20000000";
  constant MREGION_UART     : word_t := x"30000000";

end core_package;
