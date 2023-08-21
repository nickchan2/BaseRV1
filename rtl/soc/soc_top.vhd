--
--  File:   soc_top.vhd
--  Brief:  The top level file of the SOC
--
--  Copyright (C) 2023 Nick Chan
--  See the LICENSE file at the root of the project for licensing info.
--  

library ieee;
use ieee.std_logic_1164.all;

entity soc_top is
  generic (
    CLK_FREQ_HZ     : integer
  );
  port (
    clk             : in  std_logic;
    clk_dbg         : in  std_logic;
    rst_n           : in  std_logic;

    -- UART
    uart_rx         : in  std_logic;
    uart_tx         : out std_logic;

    -- GPIO
    gpio_in         : in  std_logic_vector(31 downto 0);
    gpio_out        : out std_logic_vector(31 downto 0);

    -- Debug
    dbg_rs3_sel     : in std_logic_vector(4 downto 0);
    dbg_rs3_val     : out std_logic_vector(31 downto 0);
    dbg_curr_instr  : out std_logic_vector(31 downto 0);
    dbg_imm         : out std_logic_vector(31 downto 0);
    dbg_curr_pc     : out std_logic_vector(31 downto 0);
    dbg_alu_result  : out std_logic_vector(31 downto 0);
    dbg_ctrl_sigs   : out std_logic_vector(31 downto 0)
  );
end soc_top;

architecture arch of soc_top is

  ---------- Constants ----------

  constant UART_BAUD_RATE : integer := 9600;
  constant RAM_ADDR_BITS  : integer := 10;

  ---------- Signals ----------

  signal dmem_en          : std_logic;
  signal dmem_addr        : std_logic_vector(31 downto 0);
  signal dmem_dtype       : std_logic_vector(2 downto 0);
  signal dmem_wd          : std_logic_vector(31 downto 0);
  signal dmem_we          : std_logic;
  signal dmem_do          : std_logic_vector(31 downto 0);
  signal imem_addr        : std_logic_vector(31 downto 0);
  signal imem_do          : std_logic_vector(31 downto 0);

  signal ram_port1_addr   : std_logic_vector((RAM_ADDR_BITS - 1) downto 0);
  signal ram_port1_dtype  : std_logic_vector(2 downto 0);
  signal ram_port1_wd     : std_logic_vector(31 downto 0);
  signal ram_port1_we     : std_logic;
  signal ram_port1_do     : std_logic_vector(31 downto 0);
  signal ram_port2_addr   : std_logic_vector((RAM_ADDR_BITS - 1) downto 0);
  signal ram_port2_do     : std_logic_vector(31 downto 0);
  
  signal boot_rom_addr    : std_logic_vector(4 downto 0);
  signal boot_rom_do      : std_logic_vector(31 downto 0);
  
  signal timer_val        : std_logic_vector(31 downto 0);

  signal uart_addr        : std_logic_vector(1 downto 0);
  signal uart_en          : std_logic;
  signal uart_wd          : std_logic_vector(7 downto 0);
  signal uart_we          : std_logic;
  signal uart_do          : std_logic_vector(7 downto 0);

begin

  core_inst : entity work.core_top(arch)
    port map (
      clk         => clk_dbg,
      rst_n       => rst_n,
      dmem_en     => dmem_en,
      dmem_addr   => dmem_addr,
      dmem_dtype  => dmem_dtype,
      dmem_wd     => dmem_wd,
      dmem_we     => dmem_we,
      dmem_do     => dmem_do,
      imem_addr   => imem_addr,
      imem_do     => imem_do,
      -- Debug
      dbg_rs3_sel     => dbg_rs3_sel,
      dbg_rs3_val     => dbg_rs3_val,
      dbg_curr_instr  => dbg_curr_instr,
      dbg_imm         => dbg_imm,
      dbg_curr_pc     => dbg_curr_pc,
      dbg_alu_result  => dbg_alu_result,
      dbg_ctrl_sigs   => dbg_ctrl_sigs
    );

  mem_controler_inst : entity work.mem_controller(arch)
    generic map (
      RAM_ADDR_BITS => RAM_ADDR_BITS
    )
    port map (
      dmem_en         => dmem_en,
      dmem_addr       => dmem_addr,
      dmem_dtype      => dmem_dtype,
      dmem_wd         => dmem_wd,
      dmem_we         => dmem_we,
      dmem_do         => dmem_do,
      imem_addr       => imem_addr,
      imem_do         => imem_do,
      ram_port1_addr  => ram_port1_addr,
      ram_port1_dtype => ram_port1_dtype,
      ram_port1_wd    => ram_port1_wd,
      ram_port1_we    => ram_port1_we,
      ram_port1_do    => ram_port1_do,
      ram_port2_addr  => ram_port2_addr,
      ram_port2_do    => ram_port2_do,
      boot_rom_addr   => boot_rom_addr,
      boot_rom_do     => boot_rom_do,
      timer_val       => timer_val,
      uart_addr       => uart_addr,
      uart_en         => uart_en,
      uart_wd         => uart_wd,
      uart_we         => uart_we,
      uart_do         => uart_do
    );

  ram_inst : entity work.ram(arch)
    generic map (
      RAM_ADDR_BITS => RAM_ADDR_BITS
    )
    port map (
      clk             => clk,
      ram_port1_addr  => ram_port1_addr,
      ram_port1_dtype => ram_port1_dtype,
      ram_port1_wd    => ram_port1_wd,
      ram_port1_we    => ram_port1_we,
      ram_port1_do    => ram_port1_do,
      ram_port2_addr  => ram_port2_addr,
      ram_port2_do    => ram_port2_do
    );

  boot_rom_inst : entity work.boot_rom(arch)
    port map (
      boot_rom_addr => boot_rom_addr,
      boot_rom_do   => boot_rom_do
    );

  timer_inst : entity work.timer(arch)
    port map (
      clk       => clk,
      rst_n     => rst_n,
      timer_val => timer_val
    );

  uart_inst : entity work.uart(arch)
    generic map (
      CLK_FREQ_HZ     => CLK_FREQ_HZ,
      UART_BAUD_RATE  => UART_BAUD_RATE
    )
    port map (
      clk             => clk,
      rst_n           => rst_n,
      uart_rx_pin     => uart_rx,
      uart_tx_pin     => uart_tx,
      uart_addr       => uart_addr,
      uart_en         => uart_en,
      uart_wd         => uart_wd,
      uart_we         => uart_we,
      uart_do         => uart_do
    );

  gpio_out <= (others => '0'); -- TODO GPIO

end arch;
