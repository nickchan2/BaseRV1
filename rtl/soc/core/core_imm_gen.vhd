--  
--  File:   core_imm_gen.vhd
--  Brief:  Generates the 32-bit immediate value
--
--  Copyright (C) 2023 Nick Chan
--  See the LICENSE file at the root of the project for licensing info.
--  

library ieee;
use ieee.std_logic_1164.all;
use work.core_package.all;

entity core_imm_gen is
  port (
    instr : in  word_t;
    imm   : out word_t
  );
end core_imm_gen;

architecture arch of core_imm_gen is
  
  -- The immediate sign bit is always stored in instr(31)
  signal sign: std_logic := instr(31);
  
  signal I: word_t;
  signal S: word_t;
  signal B: word_t;
  signal U: word_t;
  signal J: word_t;
  
begin
  
  -- I-immediate
  I(31 downto 12) <= (others => sign);
  I(11 downto 0) <= instr(31 downto 20);
  
  -- S-immediate
  S(31 downto 12) <= (others => sign);
  S(11 downto 5) <= instr(31 downto 25);
  S(4 downto 0) <= instr(11 downto 7);
  
  -- B-immediate
  B(31 downto 12) <= (others => sign);
  B(11) <= instr(7);
  B(10 downto 5) <= instr(30 downto 25);
  B(4 downto 1) <= instr(11 downto 8);
  B(0) <= '0';
  
  -- U-immediate
  U(31 downto 12) <= instr(31 downto 12);
  U(11 downto 0) <= (others => '0');
  
  -- J-immediate
  J(31 downto 20) <= (others => sign);
  J(19 downto 12) <= instr(19 downto 12);
  J(11) <= instr(20);
  J(10 downto 1) <= instr(30 downto 21);
  J(0) <= '0';
  
  with instr(6 downto 2) select imm <=
    S when "01000",
    B when "11000",
    U when "01101",
    U when "00101",
    J when "11011",
    I when "00100",
    I when "00000",
    I when "11001",
    I when others;

end arch;
