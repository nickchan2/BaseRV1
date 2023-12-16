--  
--  File:   boot_rom.vhd
--  Brief:  Bootloader ROM
--
--  Copyright (C) 2023 Nick Chan
--  See the LICENSE file at the root of the project for licensing info.
--  

library ieee;
use ieee.std_logic_1164.all;
use work.soc_package.all;

entity boot_rom is
  port (
    clk           : in  std_logic;
    rst_n         : in  std_logic;
    boot_rom_addr : in  word_t;
    boot_rom_do   : out word_t
  );
end boot_rom;

architecture arch of boot_rom is

  constant boot_image: word_array_t(0 to 15) := (
    x"300005b7",
    x"00000613",
    x"028000ef",
    x"00050293",
    x"020000ef",
    x"00851513",
    x"00a282b3",
    x"014000ef",
    x"00a60023",
    x"00160613",
    x"fe561ae3",
    x"00000067",
    x"0015c503",
    x"fe050ee3",
    x"0005c503",
    x"00008067"
  );

  signal rom_do_reg: word_t := x"00000013";

begin

  process(clk, rst_n)
  begin
    if rst_n = '0' then
      rom_do_reg <= x"00000013";
    elsif rising_edge(clk) then
      rom_do_reg <= boot_image(to_integer(unsigned(boot_rom_addr)));
    end if;
  end process;

  boot_rom_do <= rom_do_reg;

end arch;
