--  
--  File:   core_shifter.vhd
--  Brief:  Bidirectional barrel shifter
--
--  Copyright (C) 2023 Nick Chan
--  See the LICENSE file at the root of the project for licensing info.
--  
--  Handles shift left, shift right, shift right arithmetic
--  BITS and SEL can be modified to change the width of the
--  data (SEL should always = log2(BITS))
--  

library ieee;
use ieee.std_logic_1164.all;

entity core_shifter is
  generic (
    BITS: positive := 32;   -- width of shifter
    SEL : positive := 5     -- log2(BITS)
  );
  port (
    shft_di       : in  std_logic_vector(BITS - 1 downto 0);  -- Shift data in
    shft_amt      : in  std_logic_vector(SEL - 1 downto 0);   -- Shift ammount
    shft_dir      : in  std_logic;                            -- Shift direction, left when '0' right when '1'
    shft_arth_en  : in  std_logic;                            -- Arithmetic shift enable
    shft_do       : out std_logic_vector(BITS - 1 downto 0)   -- Shift data out
  );
end core_shifter;

architecture arch of core_shifter is
  
  type shift_layers_t is array(0 to SEL) of std_logic_vector(BITS - 1 downto 0);

  signal ext_bit      : std_logic;
  signal shift_layers : shift_layers_t;
  
begin
  
  -- The bit that will be shifted in is 0 when a logical shift or the MSB of
  -- the data input when an arithmetic right shift
  ext_bit <= shft_di(BITS - 1) AND shft_arth_en AND shft_dir;
  
  -- Reverse input if shifting in other direction
  initial_reverse: for ii in 0 to BITS - 1 generate
    with shft_dir select shift_layers(0)(ii) <=
      shft_di(ii)             when '0',
      shft_di(BITS - 1 - ii)  when others;
  end generate initial_reverse;
  
  gen_layers: for ii in 1 to SEL generate
    gen_top: for jj in BITS - 1 downto 2**(ii - 1) generate
      with shft_amt(ii - 1) select shift_layers(ii)(jj) <=
        shift_layers(ii - 1)(jj)                    when '0',
        shift_layers(ii - 1)(jj - (2 ** (ii - 1)))  when others;
    end generate;
    gen_bottom: for jj in 2**(ii-1) - 1 downto 0 generate
      with shft_amt(ii - 1) select shift_layers(ii)(jj) <=
        shift_layers(ii - 1)(jj)  when '0',
        ext_bit                   when others;
    end generate;
  end generate gen_layers;
  
  -- If data was reversed before shifting, reverse it back
  final_reverse: for ii in 0 to BITS - 1 generate
    with shft_dir select shft_do(ii) <=
      shift_layers(SEL)(ii)             when '0',
      shift_layers(SEL)(BITS - 1 - ii)  when others;
  end generate final_reverse;

end arch;
