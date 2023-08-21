--  
--  File:   boot_rom.vhd
--  Brief:  Bootloader ROM
--
--  Copyright (C) 2023 Nick Chan
--  See the LICENSE file at the root of the project for licensing info.
--  

library ieee;
use ieee.std_logic_1164.all;

entity boot_rom is
  port (
    boot_rom_addr : in  std_logic_vector(4 downto 0);
    boot_rom_do   : out std_logic_vector(31 downto 0)
  );
end boot_rom;

architecture arch of boot_rom is

begin

  with boot_rom_addr select boot_rom_do <=
    x"300005b7" when "00000",
    x"00000613" when "00001",
    x"028000ef" when "00010",
    x"00050293" when "00011",
    x"020000ef" when "00100",
    x"00851513" when "00101",
    x"00a282b3" when "00110",
    x"014000ef" when "00111",
    x"00a60023" when "01000",
    x"00160613" when "01001",
    x"fe561ae3" when "01010",
    x"00000067" when "01011",
    x"0015c503" when "01100",
    x"fe050ee3" when "01101",
    x"0005c503" when "01110",
    x"00008067" when "01111",
    x"00000000" when others;

end arch;
