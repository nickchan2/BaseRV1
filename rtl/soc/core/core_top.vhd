--
--  File:   core_top.vhd
--  Brief:  The top level of the core
--
--  Copyright (C) 2023 Nick Chan
--  See the LICENSE file at the root of the project for licensing info.
--  

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.core_package.all;

entity core_top is
  port (
    clk             : in  std_logic;
    rst_n           : in  std_logic;

    -- Data memory
    dmem_en         : out std_logic;
    dmem_addr       : out word_t;
    dmem_dtype      : out std_logic_vector(2 downto 0);
    dmem_wd         : out word_t;
    dmem_we         : out std_logic;
    dmem_do         : in  word_t;

    -- Instruction memory
    imem_addr       : out word_t;
    imem_do         : in  word_t;

    -- Debug
    dbg_rs3_sel     : in  rf_sel_t;
    dbg_rs3_val     : out word_t;
    dbg_curr_instr  : out word_t;
    dbg_imm         : out word_t;
    dbg_curr_pc     : out word_t;
    dbg_alu_result  : out word_t;
    dbg_ctrl_sigs   : out word_t
  );
end core_top;

architecture arch of core_top is
  
  signal instr        : word_t  := imem_do;

  signal imm          : word_t;     -- Immediate value

  signal ctrl_bus     : ctrl_bus_t;

  signal pc_val       : word_t  := X"10000000";
  signal pc_wd        : word_t;     -- Program counter write data
  signal next_seq_pc  : word_t;     -- Next sequential pc
  
  signal branch_en    : std_logic;  -- Branch enable
  
  signal rs1_val      : word_t;     -- rs1 value
  signal rs2_val      : word_t;     -- rs2 value
  signal rd_wd        : word_t;     -- rd write data

  signal alu_operand1 : word_t;     -- ALU operand 1
  signal alu_operand2 : word_t;     -- ALU operand 2
  signal alu_result   : word_t;     -- ALU result

begin
  
  -- Program counter register
  process (clk, rst_n)
  begin
    if rst_n = '0' then
      pc_val <= x"10000000";
    elsif rising_edge(clk) AND ctrl_bus.pc_we = '1' then
      pc_val <= pc_wd;
    end if;
  end process;

  core_imm_gen_inst : entity work.core_imm_gen(arch)
    port map (
      instr => instr,
      imm   => imm
    );
  
  core_branch_alu_inst : entity work.core_branch_alu(arch)
    port map (
      cmp_operand1      => rs1_val,
      cmp_operand2      => rs2_val,
      cmp_opcode        => ctrl_bus.cmp_opcode,
      cond_branch_en    => ctrl_bus.cond_branch_en,
      uncond_branch_en  => ctrl_bus.uncond_branch_en,
      branch_en         => branch_en
    );

  core_reg_file_inst : entity work.core_reg_file(arch)
    port map (
      clk     => clk,
      rst_n   => rst_n,
      rs1_sel => ctrl_bus.rs1_sel,
      rs2_sel => ctrl_bus.rs2_sel,
      rs1_val => rs1_val,
      rs2_val => rs2_val,
      rd_sel  => ctrl_bus.rd_sel,
      rd_we   => ctrl_bus.rd_we,
      rd_wd   => rd_wd,
      -- Debug
      dbg_rs3_sel => dbg_rs3_sel,
      dbg_rs3_val => dbg_rs3_val
    );
  
  core_alu_inst : entity work.core_alu(arch)
    port map (
      alu_operand1  => alu_operand1,
      alu_operand2  => alu_operand2,
      alu_opcode    => ctrl_bus.alu_opcode,
      alu_result    => alu_result
    );

  next_seq_pc <= std_logic_vector(unsigned(pc_val) + 4);
  
  core_control_inst : entity work.core_control(arch)
    port map (
      clk       => clk,
      rst_n     => rst_n,
      instr     => instr,
      ctrl_bus  => ctrl_bus
    );
  
  -- Program counter write data source mux
  pc_wd <= next_seq_pc when (branch_en = '0') else alu_result;

  -- ALU operand 1 source mux
  with ctrl_bus.alu_operand1_sel select alu_operand1 <=
    rs1_val     when "00",
    pc_val      when "01",
    x"00000000" when others;
  
  -- ALU operand 2 source mux
  alu_operand2 <= rs2_val when (ctrl_bus.alu_operand2_sel = '0') else imm;
  
  -- rd write data source mux
  with ctrl_bus.rd_wd_sel select rd_wd <=
    alu_result  when "00",
    dmem_do     when "01",
    next_seq_pc when others;
  
  dmem_en     <= ctrl_bus.dmem_en;
  dmem_addr   <= alu_result;
  dmem_dtype  <= ctrl_bus.dmem_dtype;
  dmem_wd     <= rs2_val;
  dmem_we     <= ctrl_bus.dmem_we;

  imem_addr <= pc_val;

  -- Debug
  dbg_curr_instr  <= instr;
  dbg_imm         <= imm;
  dbg_curr_pc     <= pc_val;
  dbg_alu_result  <= alu_result;
  dbg_ctrl_sigs   <=
    x"000000" &
    ctrl_bus.alu_opcode &
    "0" &
    ctrl_bus.uncond_branch_en &
    ctrl_bus.cond_branch_en &
    branch_en;
  
end arch;
