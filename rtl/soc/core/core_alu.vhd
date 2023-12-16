--  
--  File:   core_alu.vhd
--  Brief:  Arithmetic & logic unit
--
--  Copyright (C) 2023 Nick Chan
--  See the LICENSE file at the root of the project for licensing info.
--  

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.soc_package.all;

entity core_alu is
  port (
    alu_operand1  : in  word_t;
    alu_operand2  : in  word_t;
    alu_opcode    : in  std_logic_vector(3 downto 0);
    alu_result    : out word_t
  );
end core_alu;

architecture arch of core_alu is 
  
  signal shft_do        : word_t;     -- Shifter data out
  
  signal op1_plus_op2   : word_t;
  signal op1_minus_op2  : word_t;

  signal op1_eq_op2     : std_logic;  -- Operand 1 equals operand 2
  signal op1_lt_op2     : std_logic;  -- Operand 1 is less than operand 2 (signed comparison)
  signal op1_ltu_op2    : std_logic;  -- Operand 1 is less than operand 2 (unsigned comparison)
  
begin
  
  core_shifter_inst : entity work.core_shifter(arch)
    port map (
      shft_di       => alu_operand1,
      shft_amt      => alu_operand2(4 downto 0),
      shft_dir      => alu_opcode(2),
      shft_arth_en  => alu_opcode(3),
      shft_do       => shft_do
    );

    op1_plus_op2 <= word_t(unsigned(alu_operand1) + unsigned(alu_operand2));

    op1_minus_op2 <= word_t(unsigned(alu_operand1) - unsigned(alu_operand2));
  
  -- When the subtraction of the operands is 0, they are equal
  op1_eq_op2 <= '1' when (op1_minus_op2 = x"00000000") else '0';

  -- Signed comparison:
  -- operand1 is less than operand2 when:
  --    - The MSB of operand1 is '1' AND the MSB of operand2 is '0' (meaning
  --      operand1 is negative AND operand2 is non-negative) OR
  --    - The MSBs of operand1 and operand2 are the same AND the MSB of
  --      operand1 minus operand2 is '1' (meaning that the result of their
  --      subtraction is negative)
  op1_lt_op2 <= (alu_operand1(31) AND (NOT alu_operand2(31))) OR
                ((alu_operand1(31) XNOR alu_operand2(31)) AND op1_minus_op2(31));
  
  -- Unsigned comparison:
  -- operand1 is less than operand2 when:
  --   - The MSB of operand1 and operand2 are the same AND the MSB of operand1
  --     minus operand2 is '1' OR
  --   - The MSB of operand1 is '0' AND the MSB of operand2 is '1'
  op1_ltu_op2 <=  ((alu_operand1(31) XNOR alu_operand2(31)) AND op1_minus_op2(31)) OR
                  ((not alu_operand1(31) AND alu_operand2(31)));
  
  with alu_opcode select alu_result <=
    op1_plus_op2                      when "0000",  -- add
    op1_minus_op2                     when "1000",  -- sub
    shft_do                           when "0001",  -- sll
    (0 => op1_lt_op2, others => '0')  when "1010",  -- slt
    (0 => op1_ltu_op2, others => '0') when "1011",  -- sltu
    alu_operand1 XOR alu_operand2     when "0100",  -- xor
    shft_do                           when "0101",  -- srl
    shft_do                           when "1101",  -- sra
    alu_operand1 OR alu_operand2      when "0110",  -- or
    alu_operand1 AND alu_operand2     when "0111",  -- and
    x"DEADBEEF"                       when others;
  
end arch;
