--  
--  data_mem.vhd
--  
--  The data memory controller
--  addr [15:0] selects the byte (rest are unused)
--  8,192 bytes / 65,536 bits
--  
--  Little endian memory system as required by rv32i
--  
--  100 unsigned byte
--  101 unsigned half word
--  110 unsigned word
--  000 signed byte
--  001 signed half word
--  010 signed word (does same thing as unsigned word since no sign extension occurs)
--  
--  addr[1:0] | din (byte) |  bram  | addressed word
--  
--       00          0    ->    0    ->    0
--                   1    ->    1    ->    1
--                   2    ->    2    ->    2
--                   3    ->    3    ->    3
--  
--       01          0    ->    1    ->    0
--                   1    ->    2    ->    1
--                   2    ->    3    ->    2
--                   3    ->    0    ->    3
--  
--       10          0    ->    2    ->    0
--                   1    ->    3    ->    1
--                   2    ->    0    ->    2
--                   3    ->    1    ->    3
--  
--       11          0    ->    3    ->    0
--                   1    ->    0    ->    1
--                   2    ->    1    ->    2
--                   3    ->    2    ->    3

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity data_mem is
  port (
    clk     : in std_logic;
    addr    : in std_logic_vector(31 downto 0);
    dtype   : in std_logic_vector(2 downto 0);
    din     : in std_logic_vector(31 downto 0);
    wen     : in std_logic;
    dout    : out std_logic_vector(31 downto 0)
  );
end data_mem;

architecture arch of data_mem is
  
  component bram_8bit is
    port (
      clk  : in std_logic;
      we   : in std_logic;
      addr : in unsigned(13 downto 0);
      di   : in std_logic_vector(7 downto 0);
      do   : out std_logic_vector(7 downto 0)
    );
  end component bram_8bit; 
  
  type vec_array is array(natural range <>) of std_logic_vector;
  type addr_array is array(3 downto 0) of unsigned(13 downto 0);
  
  signal bram_addr: addr_array;
  signal bram_din: std_logic_vector(31 downto 0);
  signal bram_dout: vec_array(3 downto 0)(7 downto 0);
  signal bram_wen_unaligned: std_logic_vector(3 downto 0);
  signal bram_wen: std_logic_vector(3 downto 0);
  
  signal addr_word: std_logic_vector(31 downto 0);
  signal extend: std_logic;
  signal extend_vec: std_logic_vector(23 downto 0) := (others => extend);
  
  signal offset: vec_array(2 downto 0)(0 downto 0);
  
begin
  
  -- The addresses for bram[2:0] may be offset by 1 depending on
  -- addr[1:0] (bram[3]'s address is never offset)
  offset(0) <= "" & (addr(1) or addr(0));
  offset(1) <= "" & addr(1);
  offset(2) <= "" & (addr(1) and addr(0));
  
  -- Creating each bram address, adding the offset as needed
  bram_addr(0) <= unsigned(addr(15 downto 2)) + unsigned(offset(0));
  bram_addr(1) <= unsigned(addr(15 downto 2)) + unsigned(offset(1));
  bram_addr(2) <= unsigned(addr(15 downto 2)) + unsigned(offset(2));
  bram_addr(3) <= unsigned(addr(15 downto 2));
  
  -- The write enables depend on the data type (byte vs halfword vs word)
  bram_wen_unaligned(0) <= wen;
  bram_wen_unaligned(1) <= wen and (dtype(1) or dtype(0));
  bram_wen_unaligned(2) <= wen and (dtype(1));
  bram_wen_unaligned(3) <= wen and (dtype(1));
  
  -- rearranging the write enables so that they are aligned to the addressed word
  with addr(1 downto 0) select
    bram_wen <= bram_wen_unaligned when "00",
                bram_wen_unaligned(2 downto 0) & bram_wen_unaligned(3) when "01",
                bram_wen_unaligned(1 downto 0) & bram_wen_unaligned(3 downto 2) when "10",
                bram_wen_unaligned(0) & bram_wen_unaligned(3 downto 1) when others;
  
  -- rearranging the data in
  with addr(1 downto 0) select
    bram_din <= din when "00",
                din(23 downto 0) & din(31 downto 24) when "01",
                din(15 downto 0) & din(31 downto 16) when "10",
                din(7 downto 0) & din(31 downto 8) when others;
  
  -- Generating the block rams
  mem_gen : for ii in 0 to 3 generate
    memg : bram_8bit
      port map (
        clk  => clk,
        we   => bram_wen(ii),
        addr => bram_addr(ii),
        di   => bram_din(7 + 8*ii downto 8*ii),
        do   => bram_dout(ii)
      );
  end generate mem_gen;
  
  -- Arranging the block ram byte outputs into a word
  with addr(1 downto 0) select
    addr_word <= bram_dout(3) & bram_dout(2) & bram_dout(1) & bram_dout(0) when "00",
                 bram_dout(0) & bram_dout(3) & bram_dout(2) & bram_dout(1) when "01",
                 bram_dout(1) & bram_dout(0) & bram_dout(3) & bram_dout(2) when "10",
                 bram_dout(2) & bram_dout(1) & bram_dout(0) & bram_dout(3) when others;
  
  extend <= (not dtype(2)) and (
              (addr_word(7) and (not dtype(0))) or
              (addr_word(15) and dtype(0))
            );
  
  with dtype(1 downto 0) select
    dout <= extend_vec & addr_word(7 downto 0) when "00",
            extend_vec(15 downto 0) & addr_word(15 downto 0) when "01",
            addr_word when others;
  
end arch;
