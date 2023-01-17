--  
--  program_mem.vhd
--  
--  The program memory
--  
--  Stores 32 bit wide data
--  
--  addr is a byte address, but the data can only be read
--  in 32 bit chunks so the bottom two bits of addr are not
--  used
--  

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity program_mem is
  port (
    clk  : in std_logic;
    we   : in std_logic;
    addr : in std_logic_vector(31 downto 0);
    di   : in std_logic_vector(31 downto 0);
    do   : out std_logic_vector(31 downto 0)
  );
end program_mem;

architecture arch of program_mem is
  
  type ram_type is array (1023 downto 0) of std_logic_vector(31 downto 0);
  
  signal RAM: ram_type := (others => (others => '0'));
  
begin
  
  process(clk)
  begin
    if(rising_edge(clk)) then
      if we = '1' then
        RAM(to_integer(unsigned(addr(11 downto 2)))) <= di;
        do <= di;
      else
        do <= RAM(to_integer(unsigned(addr(11 downto 2))));
      end if;
    end if;
  end process;
  
end arch;
