--  
--  add_sub.vhd
--  
--  Add or subtract two 32 bit numbers
--  
--  Adds when op is '0' subtracts when op is '1'
--  

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity add_sub is
  port (
    num1 : in std_logic_vector(31 downto 0);
    num2 : in std_logic_vector(31 downto 0);
    op   : in std_logic;
    dout : out std_logic_vector(31 downto 0)
  );
end add_sub;

architecture arch of add_sub is
  
  signal flip: std_logic_vector(31 downto 0) := (others => op);
  signal ci: std_logic_vector(0 downto 0) := (others => op);
  signal num2_1c: std_logic_vector(31 downto 0);

begin
  
  num2_1c <= num2 xor flip;
  
  dout <= std_logic_vector(unsigned(num1) + unsigned(num2_1c) + unsigned(ci));
  
end arch;
