--  
--  adder.vhd
--
--  Adds two 32 bit numbers
--  

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder is
  port (
    num1 : in std_logic_vector(31 downto 0);
    num2 : in std_Logic_vector(31 downto 0);
    sum  : out std_logic_vector(31 downto 0)
  );
end adder;

architecture arch of adder is
  
begin
  
  sum <= std_logic_vector(unsigned(num1) + unsigned(num2));
  
end arch;
