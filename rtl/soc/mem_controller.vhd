--  
--  File:   mem_controller.vhd
--  Brief:  The memory controller.
--
--  Copyright (C) 2023 Nick Chan
--  See the LICENSE file at the root of the project for licensing info.
--  

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem_controller is
  generic (
    RAM_ADDR_BITS   : in  integer
  );
  port (
    -- Data memory
    dmem_en         : in  std_logic;
    dmem_addr       : in  std_logic_vector(31 downto 0);
    dmem_dtype      : in  std_logic_vector(2 downto 0);
    dmem_wd         : in  std_logic_vector(31 downto 0);
    dmem_we         : in  std_logic;
    dmem_do         : out std_logic_vector(31 downto 0);

    -- Instruction memory
    imem_addr       : in  std_logic_vector(31 downto 0);
    imem_do         : out std_logic_vector(31 downto 0);

    -- RAM
    ram_port1_addr  : out std_logic_vector((RAM_ADDR_BITS - 1) downto 0);
    ram_port1_dtype : out std_logic_vector(2 downto 0);
    ram_port1_wd    : out std_logic_vector(31 downto 0);
    ram_port1_we    : out std_logic;
    ram_port1_do    : in  std_logic_vector(31 downto 0);
    ram_port2_addr  : out std_logic_vector((RAM_ADDR_BITS - 1) downto 0);
    ram_port2_do    : in  std_logic_vector(31 downto 0);
    
    -- Boot ROM
    boot_rom_addr   : out std_logic_vector(4 downto 0);
    boot_rom_do     : in  std_logic_vector(31 downto 0);

    -- Timer
    timer_val       : in  std_logic_vector(31 downto 0);

    -- UART
    uart_addr       : out std_logic_vector(1 downto 0);
    uart_en         : out std_logic;
    uart_wd         : out std_logic_vector(7 downto 0);
    uart_we         : out std_logic;
    uart_do         : in  std_logic_vector(7 downto 0)
  );
end mem_controller;

architecture arch of mem_controller is
  
  signal dmem_is_ram_access       : std_logic;
  signal dmem_is_timer_access     : std_logic;
  signal dmem_is_uart_access      : std_logic;

  signal dmem_invalid_address     : std_logic;
  signal dmem_misaligned_access   : std_logic;
  signal dmem_invalid_access      : std_logic;

  signal imem_is_ram_access       : std_logic;
  signal imem_is_boot_rom_access  : std_logic;

  signal imem_invalid_address     : std_logic;
  signal imem_misaligned_access   : std_logic;
  signal imem_invalid_access      : std_logic;
  
begin

  ---------- Data memory ----------

  process (dmem_addr)
  begin
    if unsigned(dmem_addr(31 downto RAM_ADDR_BITS)) = 0 then
      dmem_is_ram_access <= '1';
    else
      dmem_is_ram_access <= '0';
    end if;
  end process;

  dmem_is_timer_access <= '1' when (dmem_addr = x"20000000") else '0';

  dmem_is_uart_access <= '1' when ((dmem_addr AND x"FFFFFFFC") = x"30000000") else '0';

  dmem_invalid_address <= NOT (dmem_is_ram_access OR dmem_is_timer_access OR dmem_is_uart_access);

  dmem_misaligned_access <= '0'; -- TODO

  dmem_invalid_access <= dmem_misaligned_access OR dmem_invalid_address; -- TODO

  with dmem_addr(31 downto 28) select dmem_do <=
    ram_port1_do        when x"0",
    timer_val           when x"2",
    x"000000" & uart_do when x"3",
    (others => '0')     when others;

  ---------- Instruction memory ----------

  process (imem_addr)
  begin
    if unsigned(imem_addr(31 downto RAM_ADDR_BITS)) = 0 then
      imem_is_ram_access <= '1';
    else
      imem_is_ram_access <= '0';
    end if;
  end process;

  imem_is_boot_rom_access <= '1' when ((imem_addr AND x"FFFFFFE0") = x"10000000") else '0';

  imem_invalid_address <= NOT (imem_is_ram_access OR imem_is_boot_rom_access);

  -- Instruction fetches must always be word aligned
  imem_misaligned_access <= imem_addr(1) OR imem_addr(0);

  imem_invalid_access <= imem_misaligned_access OR imem_invalid_address;

  with imem_addr(31 downto 28) select imem_do <=
    ram_port2_do    when X"0",
    boot_rom_do     when X"1",
    (others => '0') when others;

  ---------- Memory peripheral output signals ----------

  ram_port1_addr  <= dmem_addr((RAM_ADDR_BITS - 1) downto 0);
  ram_port1_dtype <= dmem_dtype;
  ram_port1_wd    <= dmem_wd;
  ram_port1_we    <= dmem_we AND (NOT dmem_invalid_access); -- TODO
  ram_port2_addr  <= imem_addr((RAM_ADDR_BITS - 1) downto 0);

  boot_rom_addr   <= imem_addr(6 downto 2);

  uart_addr       <= dmem_addr(1 downto 0);
  uart_en         <= dmem_is_uart_access AND dmem_en;
  uart_wd         <= dmem_wd(7 downto 0);
  uart_we         <= uart_en AND dmem_we;
  
end arch;
