--
--  imm_gen.vhd
--  
--  Generates the 32 bit value specified by immediate instructions
--  

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity imm_gen is
  port (
    instr : in std_logic_vector(31 downto 0);
    imm   : out std_logic_vector(31 downto 0)
  );
end imm_gen;

architecture arch of imm_gen is
  
  -- The immediate sign bit is always stored in instr(31)
  signal sign: std_logic := instr(31);
  signal sign_ext: std_logic_vector(19 downto 0) := (others => sign);
  
  signal I: std_logic_vector(31 downto 0);
  signal S: std_logic_vector(31 downto 0);
  signal B: std_logic_vector(31 downto 0);
  signal U: std_logic_vector(31 downto 0) := (others => '0');
  signal J: std_logic_vector(31 downto 0);
  
begin
  
  -- I-immediate
  I(31 downto 12) <= sign_ext;
  I(11 downto 0) <= instr(31 downto 20);
  
  -- S-immediate
  S(31 downto 12) <= sign_ext;
  S(11 downto 5) <= instr(31 downto 25);
  S(4 downto 0) <= instr(11 downto 7);
  
  -- B-immediate
  B(31 downto 12) <= sign_ext;
  B(11) <= instr(7);
  B(10 downto 5) <= instr(30 downto 25);
  B(4 downto 1) <= instr(11 downto 8);
  B(0) <= '0';
  
  -- U-immediate
  U(31 downto 12) <= instr(31 downto 12);
  
  -- J-immediate
  J(31 downto 20) <= sign_ext(11 downto 0);
  J(19 downto 12) <= instr(19 downto 12);
  J(11) <= instr(20);
  J(10 downto 1) <= instr(30 downto 21);
  J(0) <= '0';
  
  with instr(6 downto 2) select
    imm <= S when "01000",
           B when "11000",
           U when "01101",
           U when "00101",
           J when "11011",
           I when "00100",
           I when "00000",
           I when "11001",
           I when others;
  
end arch;
