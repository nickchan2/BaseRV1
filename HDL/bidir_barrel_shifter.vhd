--  
--  bidir_barrel_shifter.vhd
--  
--  Bidirectional barrel shifter
--  
--  Handles shift left, shift right, shift right arithmetic
--  BITS and SEL can be modified to change the width of the
--  data (SEL should always = log2(BITS))
--  

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bidir_barrel_shifter is
  generic (
    BITS: positive := 32;   -- width of shifter
    SEL : positive := 5     -- log2(BITS)
  );
  port (
    din    : in std_logic_vector(BITS - 1 downto 0);  -- data to be shifted
    shamt  : in std_logic_vector(SEL - 1 downto 0);   -- shift ammount
    shdir  : in std_logic;                            -- shift direction, left when '0' right when '1'
    arith  : in std_logic;                            -- arithmetic shift (when 1)
    dout   : out std_logic_vector(BITS - 1 downto 0)  -- shifted data
  );
end bidir_barrel_shifter;

architecture arch of bidir_barrel_shifter is
  
  component reverse_bits is
    generic (
      BITS : in positive := 32
    );
    port (
      din  : in std_logic_vector(BITS - 1 downto 0);
      rev  : in std_logic;
      dout : out std_logic_vector(BITS - 1 downto 0)
    );
  end component reverse_bits;
  
  type t_vec_array is array(0 to SEL) of std_logic_vector(BITS - 1 downto 0);
  
  signal ext_bit: std_logic;
  signal shift_layers: t_vec_array;
  
begin
  
  ext_bit <= din(BITS - 1) and arith;
  
  -- input can be reversed to shift in other direction
  initial_reverse: reverse_bits
    generic map (
      BITS => BITS
    )
    port map (
      din  => din,
      rev  => shdir,
      dout => shift_layers(0)
    );
  
  gen_layers: for ii in 1 to SEL generate
    gen_top: for jj in BITS - 1 downto 2**(ii - 1) generate
      with shamt(ii-1) select
        shift_layers(ii)(jj) <= shift_layers(ii-1)(jj) when '0',
                                shift_layers(ii-1)(jj - 2**(ii - 1)) when others;
    end generate;
    gen_bottom: for jj in 2**(ii-1) - 1 downto 0 generate
      with shamt(ii-1) select
        shift_layers(ii)(jj) <= shift_layers(ii-1)(jj) when '0',
                                ext_bit when others;
    end generate;
  end generate;
  
  final_reverse: reverse_bits
    generic map (
      BITS => BITS
    )
    port map (
      din  => shift_layers(SEL),
      rev  => shdir,
      dout => dout
    );
  
end arch;
