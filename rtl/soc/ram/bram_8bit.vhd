--  
--  File:   bram_8bit.vhd
--  Brief:  TODO.
--
--  Copyright (C) 2023 Nick Chan
--  See the LICENSE file at the root of the project for licensing info.
--  

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bram_8bit is
  generic (
    BRAM_ADDR_BITS  : in  integer
  );
  port (
    clk             : in  std_logic;
    bram_port1_addr : in  std_logic_vector((BRAM_ADDR_BITS - 1) downto 0);
    bram_port1_we   : in  std_logic;
    bram_port1_wd   : in  std_logic_vector(7 downto 0);
    bram_port1_do   : out std_logic_vector(7 downto 0);
    bram_port2_addr : in  std_logic_vector((BRAM_ADDR_BITS - 1) downto 0);
    bram_port2_do   : out std_logic_vector(7 downto 0)
  );
end bram_8bit;

architecture arch of bram_8bit is
  
  type ram_8bit_t is array (((2 ** BRAM_ADDR_BITS) - 1) downto 0) of std_logic_vector(7 downto 0);
  
  signal ram_8bit: ram_8bit_t;
  
begin

  process (clk)
  begin
    if rising_edge(clk) then
      if bram_port1_we = '1' then
        ram_8bit(to_integer(unsigned(bram_port1_addr))) <= bram_port1_wd;
        bram_port1_do <= bram_port1_wd;
      else
        bram_port1_do <= ram_8bit(to_integer(unsigned(bram_port1_addr)));
      end if;
      bram_port2_do <= ram_8bit(to_integer(unsigned(bram_port2_addr)));
    end if;
  end process;
  
end arch;
