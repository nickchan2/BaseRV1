--  
--  File:   seg7_controller.vhd
--  Brief:  Displays 16-bit number in hex on 4 digit 7-segment display.
--
--  Copyright (C) 2023 Nick Chan
--  See the LICENSE file at the root of the project for licensing info.
--  

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seg7_controller is
  port (
    clk     : in std_logic;
    di      : in std_logic_vector(15 downto 0);
    an_sel  : out std_logic_vector(3 downto 0);
    digit   : out std_logic_vector(6 downto 0)
  );
end seg7_controller;

architecture arch of seg7_controller is

  signal hex_curr: std_logic_vector(3 downto 0);
  signal div_clk: std_logic := '0';
  signal dig_sel: unsigned(1 downto 0) := "00";

begin

  clock_divider : process(clk)
    variable counter: integer range 0 to 10000 := 0;
  begin
    if rising_edge(clk) then
      if counter = 10000 then
        counter := 0;
        div_clk <= not div_clk;
      else
        counter := counter + 1;
      end if;
    end if;
  end process clock_divider;

  dig_sel_gen : process(div_clk)
  begin
    if rising_edge(div_clk) then
      dig_sel <= dig_sel + 1;
      if(dig_sel = "11") then
        dig_sel <= "00";
      end if;
    end if;
  end process dig_sel_gen;
    
  with dig_sel select
    an_sel <= "1110" when "00",
              "1101" when "01",
              "1011" when "10",
              "0111" when others;
  
  with dig_sel select
    hex_curr <= di(3 downto 0) when "00",
                di(7 downto 4) when "01",
                di(11 downto 8) when "10",
                di(15 downto 12) when others;
    
  decode : entity work.hex_seg7_decoder(arch)
    port map (
      hex => hex_curr,
      seg7 => digit
    );
    
end arch;
