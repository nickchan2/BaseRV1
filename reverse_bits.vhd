--  
--  reverse_bits.vhd
--  
--  reverse a std_logic_vector
--  

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity reverse_bits is
  generic (
    BITS: in positive := 32
  );
  port ( 
    din  : in std_logic_vector(BITS - 1 downto 0);
    rev  : in std_logic;
    dout : out std_logic_vector(BITS - 1 downto 0)
  );
end reverse_bits;

architecture arch of reverse_bits is
  
  signal reversed: std_logic_vector(BITS - 1 downto 0);
  
begin
  
  r_gen: for ii in 0 to BITS - 1 generate
    reversed(ii) <= din(BITS - 1 - ii);
  end generate r_gen;
  
  with rev select
    dout <= reversed when '1',
            din when others;
  
end arch;
