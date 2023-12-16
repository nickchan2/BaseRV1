--  
--  File:   core_branch_alu.vhd
--  Brief:  Branch ALU
--
--  Copyright (C) 2023 Nick Chan
--  See the LICENSE file at the root of the project for licensing info.
--  

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.soc_package.all;

entity core_branch_alu is
  port (
    cmp_operand1      : in  word_t;
    cmp_operand2      : in  word_t;
    cmp_opcode        : in  std_logic_vector(2 downto 0);
    cond_branch_en    : in  std_logic;
    uncond_branch_en  : in  std_logic;
    branch_en         : out std_logic
  );
end core_branch_alu;

architecture arch of core_branch_alu is
  
  signal sub_result   : word_t;
  signal op1_eq_op2   : std_logic;
  signal op1_lt_op2   : std_logic;
  signal op1_ltu_op2  : std_logic;
  signal cmp_result   : std_logic;

begin

  sub_result <= std_logic_vector(unsigned(cmp_operand2) - unsigned(cmp_operand1));

  op1_eq_op2 <= '1' when (sub_result = x"00000000") else '0';

  op1_lt_op2 <= '0'; -- TODO

  op1_ltu_op2 <= '0'; -- TODO

  with cmp_opcode select cmp_result <=
    op1_eq_op2      when "000", -- EQ
    NOT op1_eq_op2  when "001", -- NE
    NOT op1_lt_op2  when "101", -- GE
    NOT op1_ltu_op2 when "111", -- GEU
    op1_lt_op2      when "100", -- LT
    op1_ltu_op2     when "110", -- LTU
    '0'             when others;

  branch_en <= uncond_branch_en OR (cond_branch_en AND cmp_result);

end arch;
