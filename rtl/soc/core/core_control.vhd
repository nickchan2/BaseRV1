--
--  File:   core_control.vhd
--  Brief:  The control unit
--
--  Copyright (C) 2023 Nick Chan
--  See the LICENSE file at the root of the project for licensing info.
--
--  Note: Doesn't detect illegal instrucitons (they will cause undefined behavior)
--

library ieee;
use ieee.std_logic_1164.all;
use work.soc_package.all;

entity core_control is
  port (
    clk               : in  std_logic;
    rst_n             : in  std_logic; -- FIXME use this
    instr             : in  word_t;
    ctrl_bus          : out ctrl_bus_t
  );
end core_control;

architecture arch of core_control is

  signal stall  : std_logic;
  signal cycle  : std_logic := '0';
  
  signal opcode : std_logic_vector(4 downto 0)  := instr(6 downto 2);
  signal funct3 : std_logic_vector(2 downto 0)  := instr(14 downto 12);
  signal funct7 : std_logic_vector(6 downto 0)  := instr(31 downto 25);
  signal rs1    : std_logic_vector(4 downto 0)  := instr(19 downto 15);
  signal rs2    : std_logic_vector(4 downto 0)  := instr(24 downto 20);
  signal rd     : std_logic_vector(4 downto 0)  := instr(11 downto 7);
  
begin

  stall <= '1' when (opcode = "00000") else '0';

  process(clk)
  begin
    if rising_edge(clk) then
      if (cycle = '0') AND (stall = '1') then
        cycle <= '1';
      else
        cycle <= '0';
      end if;
    end if;
  end process;

  ctrl_bus.pc_we <= '0' when ((cycle & stall) = "01") else '1';

  ctrl_bus.cmp_opcode <= funct3;

  ctrl_bus.cond_branch_en <= '1' when (opcode = "11000") else '0';

  -- Unconditional branch when opcode is jal or jalr
  ctrl_bus.uncond_branch_en <= '1' when (opcode(4 downto 2) & opcode(0) = "1101") else '0';

  ctrl_bus.rs1_sel <= rs1;
  ctrl_bus.rs2_sel <= rs2;
  ctrl_bus.rd_sel  <= rd;

  with opcode select ctrl_bus.rd_we <=
    '1' when "01100", -- OP
    '1' when "00100", -- OP-IMM
    '1' when "01101", -- lui
    '1' when "00101", -- auipc
    '1' when "00000", -- Loads
    '1' when "11011", -- jal
    '1' when "11001", -- jalr
    '0' when others;

  with opcode select ctrl_bus.rd_wd_sel <=
    "10" when "11011",  -- jal
    "10" when "11001",  -- jalr
    "01" when "00000",  -- Loads
    "00" when others;

  with opcode select ctrl_bus.alu_opcode <=
    funct7(5) & funct3  when "01100", -- OP
    ((funct3(2) AND NOT funct3(1) AND funct3(0)) AND funct7(5)) & funct3  when "00100", -- OP-IMM
    "0000"              when others;

  with opcode select ctrl_bus.alu_operand1_sel <=
    "00"  when "01100", -- OP
    "00"  when "00100", -- OP-IMM
    "10"  when "01101", -- lui
    "01"  when "00101", -- auipc
    "00"  when "00000", -- Loads
    "00"  when "01000", -- Stores
    "01"  when "11000", -- Branches
    "01"  when "11011", -- jal
    "00"  when "11001", -- jalr
    "00"  when others;

  -- Immediate is selected unless OP instruction
  ctrl_bus.alu_operand2_sel <= '0' when (opcode = "01100") else '1';

  -- Data memory is enabled when opcode is load or store
  ctrl_bus.dmem_en <= '1' when (opcode(4) & opcode(2 downto 0) = "0000") else '0';

  ctrl_bus.dmem_we <= opcode(3);

  ctrl_bus.dmem_dtype <= funct3;
    
end arch;
