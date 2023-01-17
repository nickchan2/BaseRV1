--  
--  hex_seg7_decoder.vhd
--  

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hex_seg7_decoder is
  port (
    hex   : in std_logic_vector(3 downto 0);
    seg7  : out std_logic_vector(6 downto 0)
  );
end hex_seg7_decoder;

architecture arch of hex_seg7_decoder is

begin

  with hex select
    seg7 <= "1000000" when X"0",
            "1111001" when X"1",   --     00
            "0100100" when X"2",   --    5  1
            "0110000" when X"3",   --    5  1
            "0011001" when X"4",   --     66
            "0010010" when X"5",   --    4  2
            "0000010" when X"6",   --    4  2
            "1111000" when X"7",   --     33
            "0000000" when X"8",
            "0010000" when X"9",
            "0001000" when X"A",
            "0000011" when X"B",
            "0100111" when X"C",
            "0100001" when X"D",
            "0000110" when X"E",
            "0001110" when X"F",
            "1111111" when others;

end arch;
