--
-- File:   ram.vhd
-- Brief:  RAM for the SOC.
--
-- Copyright (C) 2023 Nick Chan
-- See the LICENSE file at the root of the project for licensing info.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram is
  generic (
    RAM_ADDR_BITS   : in  integer
  );
  port (
    clk             : in  std_logic;

    -- Port 1: Read/Write
    ram_port1_addr  : in  std_logic_vector((RAM_ADDR_BITS - 1) downto 0);
    ram_port1_dtype : in  std_logic_vector(2 downto 0);
    ram_port1_wd    : in  std_logic_vector(31 downto 0);
    ram_port1_we    : in  std_logic;
    ram_port1_do    : out std_logic_vector(31 downto 0);

    -- Port 2: Read only
    ram_port2_addr  : in  std_logic_vector((RAM_ADDR_BITS - 1) downto 0); -- Bottom 2 bits not used
    ram_port2_do    : out std_logic_vector(31 downto 0)
  );
end ram;

architecture arch of ram is

  component bram_8bit is
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
  end component bram_8bit;

  type byte_array_t is array(0 to 3) of std_logic_vector(7 downto 0);
  type bram_addr_array_t is array(0 to 3) of std_logic_vector((RAM_ADDR_BITS - 3) downto 0);
  type bram_we_array_t is array(0 to 3) of std_logic;

  signal bram_port1_addr  : bram_addr_array_t;
  signal bram_port1_we    : bram_we_array_t;
  signal bram_port1_wd    : byte_array_t;
  signal bram_port1_do    : byte_array_t;
  signal bram_port2_addr  : bram_addr_array_t;
  signal bram_port2_do    : byte_array_t;

  signal width_is_w       : std_logic;
  signal width_is_hw      : std_logic;
  signal width_is_b       : std_logic;

  signal addr_byte_3      : std_logic;
  signal addr_byte_2      : std_logic;
  signal addr_byte_1      : std_logic;
  signal addr_byte_0      : std_logic;

begin

  gen_loop : for ii in 0 to 3 generate

    bram_8bit_inst : bram_8bit
      generic map (
        BRAM_ADDR_BITS  => RAM_ADDR_BITS - 2
      )
      port map (
        clk             => clk,
        bram_port1_addr => bram_port1_addr(ii),
        bram_port1_we   => bram_port1_we(ii),
        bram_port1_wd   => bram_port1_wd(ii),
        bram_port1_do   => bram_port1_do(ii),
        bram_port2_addr => bram_port2_addr(ii),
        bram_port2_do   => bram_port2_do(ii)
      );

      bram_port1_addr(ii) <= ram_port1_addr((RAM_ADDR_BITS - 1) downto 2);
      
      bram_port1_wd(ii) <= ram_port1_wd((7 + (8 * ii)) downto (8 * ii));
      
      bram_port2_addr(ii) <= ram_port2_addr((RAM_ADDR_BITS - 1) downto 2);
      
      ram_port2_do((7 + (8 * ii)) downto (8 * ii)) <= bram_port2_do(ii);

  end generate;

  width_is_w  <= '1' when (dtype(1 downto 0) = "10") else '0';
  width_is_hw <= '1' when (dtype(1 downto 0) = "01") else '0';
  width_is_b  <= '1' when (dtype(1 downto 0) = "00") else '0';

  addr_byte_3 <= '1' when (ram_port1_addr(1 downto 0) = "11") else '0';
  addr_byte_2 <= '1' when (ram_port1_addr(1 downto 0) = "10") else '0';
  addr_byte_1 <= '1' when (ram_port1_addr(1 downto 0) = "01") else '0';
  addr_byte_0 <= '1' when (ram_port1_addr(1 downto 0) = "00") else '0';

  bram_port1_we(3) <=
  (
    ram_port1_we AND
    (
      (width_is_w)                    OR
      (width_is_hw AND addr_byte_2)   OR
      (width_is_byte AND addr_byte_3)
    )
  );

  bram_port1_we(2) <=
  (
    ram_port1_we AND
    (
      (width_is_w)                    OR
      (width_is_hw AND addr_byte_2)   OR
      (width_is_byte AND addr_byte_2)
    )
  );

  bram_port1_we(1) <=
  (
    ram_port1_we AND
    (
      (width_is_w)                    OR
      (width_is_hw AND addr_byte_0)   OR
      (width_is_byte AND addr_byte_1)
    )
  );

  bram_port1_we(0) <=
  (
    ram_port1_we AND
    (
      (width_is_w)                    OR
      (width_is_hw AND addr_byte_0)   OR
      (width_is_byte AND addr_byte_0)
    )
  );

end arch;
