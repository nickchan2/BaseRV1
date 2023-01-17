--  
--  control.vhd
--  
--  The control unit
--  
--  Note: Doesn't detect invalid instrucitons (they will cause undefined behavior)
--  

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity control is
  port (
    instr       : in std_logic_vector(31 downto 0);
    eq_flag     : in std_logic;
    lt_flag     : in std_logic;
    branch_en   : out std_logic;
    pc_src      : out std_logic;
    reg_src     : out std_logic_vector(1 downto 0);
    reg_wen     : out std_logic;
    dmem_wen    : out std_logic;
    dmem_dtype  : out std_logic_vector(2 downto 0);
    alu_op      : out std_logic_vector(3 downto 0);
    alu_src1    : out std_logic;
    alu_src2    : out std_logic;
    imm         : out std_logic_vector(31 downto 0);
    rs1         : out std_logic_vector(4 downto 0);
    rs2         : out std_logic_vector(4 downto 0);
    rws         : out std_logic_vector(4 downto 0)
  );
end control;

architecture arch of control is
  
  signal branch_condition_met: std_logic;
  signal is_branch_instr: std_logic;
  signal baluop: std_logic_vector(3 downto 0);
  signal aluop_msb: std_logic;
  
begin
  
  with instr(14) & instr(12) select
    branch_condition_met <= eq_flag when "00",        -- beq
                            not eq_flag when "01",    -- bne
                            lt_flag when "10",        -- blt(u)
                            not lt_flag when others;  -- bge(u)
  
  is_branch_instr <= instr(6) and instr(5) and (not instr(2));
  
  branch_en <= is_branch_instr and branch_condition_met;
  
  -- ALU opcode decode
  
  aluop_msb <= instr(30) and (not instr(5)) and instr(12);
  
  with instr(13) select
    baluop <= "1010" when '0',
              "1011" when others;
  
  with instr(6 downto 4) & instr(2) select
    alu_op <= aluop_msb & instr(14 downto 12) when "0010",
              instr(30) & instr(14 downto 12) when "0110",
              baluop when "1100",
              "0000" when others;
  
  -- '1' (meaning pc selected) when auipc or jal
  alu_src1 <= instr(3) or ((not instr(6)) and (not instr(5)) and instr(4) and instr(2));
  
  -- '1' when not R-type and not B-type
  alu_src2 <= (instr(6) or (not instr(5)) or (not instr(4)) or instr(2)) and
              ((not instr(6)) or (not instr(5)) or instr(4) or instr(2));
  
  dmem_wen <= (not instr(6)) and instr(5) and (not instr(4));
  
  dmem_dtype <= instr(14 downto 12);
  
  gen_imm : entity work.imm_gen(arch)
    port map (
      instr => instr,
      imm   => imm
    );
  
  -- '1' when jal or jalr
  pc_src <= instr(6) and instr(5) and instr(2);
  
  reg_src(1) <= pc_src; -- the reg source is the pc + 4 (return address) for jumps
  reg_src(0) <= not instr(4);
  
  reg_wen <= not(instr(5) and (not instr(4)) and (not instr(3)) and (not instr(2)));
  
  -- Register select
  with instr(5 downto 4) & instr(2) select
    rs1 <= "00000" when "111", -- auipc doesn't specify rs1 but uses 0 (so x0 is selected)
           instr(19 downto 15) when others;
  rs2 <= instr(24 downto 20);
  rws <= instr(11 downto 7);
  
end arch;
