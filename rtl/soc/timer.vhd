--  
--  File:   timer.vhd
--  Brief:  A simple memory mapped timer.
--
--  Copyright (C) 2023 Nick Chan
--  See the LICENSE file at the root of the project for licensing info.
--  

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.soc_package.all;

entity timer is
  port (
    clk       : in  std_logic;
    rst_n     : in  std_logic;
    timer_val : out word_t
  );
end timer;

architecture arch of timer is

  signal timer_ff : unsigned(31 downto 0) := (others => '0');

begin

  process (clk, rst_n)
  begin
    if rst_n = '0' then
      timer_ff <= (others => '0');
    elsif rising_edge(clk) then
      timer_ff <= timer_ff + 1;
    end if;
  end process;

  timer_val <= std_logic_vector(timer_ff);

end arch;
