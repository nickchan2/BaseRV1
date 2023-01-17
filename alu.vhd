--
--  alu.vhd
--  
--  Arithmetic & Logic Unit
--  
--  operation   opcode  
--  
--  add         0000
--  sub         1000
--  sll         0001
--  slt         1010
--  sltu        1011
--  xor         0100
--  srl         0101
--  sra         1101
--  or          0110
--  and         0111
--  
--  slt and sltu opcodes are also used for branch
--  comparisons as they set the flags
--  

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity alu is
  port (
    din1      : in std_logic_vector(31 downto 0);
    din2      : in std_logic_vector(31 downto 0);
    op        : in std_logic_vector(3 downto 0);
    dout      : out std_logic_vector(31 downto 0);
    eq_flag   : out std_logic;
    lt_flag   : out std_logic
  );
end alu;

architecture arch of alu is 
  
  signal shift_out: std_logic_vector(31 downto 0);
  signal arithmetic_out: std_logic_vector(31 downto 0);
  
  signal d1_eq_d2: std_logic;
  signal d1_lt_d2_signed: std_logic;
  signal d1_lt_d2_unsigned: std_logic;
  signal comparison_result: std_logic_vector(31 downto 0);
  
begin
  
  shifter : entity work.bidir_barrel_shifter(arch)
    port map (
      din => din1,
      shamt => din2(4 downto 0),
      shdir => op(2),
      arith => op(3),
      dout => shift_out
    );
  
  addsub : entity work.add_sub(arch)
    port map (
      num1 => din1,
      num2 => din2,
      op   => op(3),
      dout => arithmetic_out
    );
  
  -- When the subtraction of the nums is 0, they are equal (signed or unsigned)
  with dout select
    d1_eq_d2 <= '1' when X"00000000",
                  '0' when others;

  -- din1 less than din2 signed comparison
  -- din1 is less than din2 when:
  --    - The MSB of din1 is '1' and the MSB of din2 is '0' (meaning that din1 is negative
  --      and din2 is non-negative) or
  --    - The MSBs of din1 and din2 are the same and the MSB of din1-din2 is '1' (meaning that
  --      the result of their subtraction is negative)
  d1_lt_d2_signed <= (din1(31) and (not din2(31))) or ((din1(31) xnor din2(31)) and arithmetic_out(31));
  
  -- din1 less than din2 unsigned comparison
  -- din1 is less than din2 when:
  --   - The MSB of din1 and din2 are the same and the MSB din1-din2 is '1' or
  --   - The MSB of din1 is '0' and the MSB of din2 is '1'
  d1_lt_d2_unsigned <= ((din1(31) xnor din2(31)) and arithmetic_out(31)) or ((not din1(31) and din2(31)));
  
  eq_flag <= d1_eq_d2;
  
  with op(0) select
    lt_flag <= d1_lt_d2_signed when '0',
               d1_lt_d2_unsigned when others;
  
  with op(2 downto 0) select
    dout <= arithmetic_out when "000",
            shift_out when "001",
            X"0000000" & "000" & d1_lt_d2_signed when "010",
            X"0000000" & "000" & d1_lt_d2_unsigned when "011",
            din1 xor din2 when "100",
            shift_out when "101",
            din1 or din2 when "110",
            din1 and din2 when others;
  
end arch;
