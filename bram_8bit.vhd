--  
--  bram_8bit.vhd
--  
--  Single-Port Block RAM Write-First Mode
--  specified by Vivado synthesis docs
--  
--  Used for the data memory
--  

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bram_8bit is
  port (
    clk  : in std_logic;
    we   : in std_logic;
    addr : in unsigned(13 downto 0);
    di   : in std_logic_vector(7 downto 0);
    do   : out std_logic_vector(7 downto 0)
  );
end bram_8bit;

architecture arch of bram_8bit is
  
  type ram_type is array (16383 downto 0) of std_logic_vector(7 downto 0);
  
  signal RAM: ram_type;
  
begin
  
  process(clk)
  begin
    if(rising_edge(clk)) then
      if we = '1' then
        RAM(to_integer(addr)) <= di;
        do <= di;
      else
        do <= RAM(to_integer(addr));
      end if;
    end if;
  end process;
  
end arch;
