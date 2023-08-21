--  
--  File:   basys3_wrapper.vhd
--  Brief:  Connects the CPU to the board IO.
--
--  Copyright (C) 2023 Nick Chan
--  See the LICENSE file at the root of the project for licensing info.
--  

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity basys3_wrapper is
  port (
    clk   : in  std_logic;
    sw    : in  std_logic_vector(15 downto 0);
    led   : out std_logic_vector(15 downto 0);
    seg   : out std_logic_vector(6 downto 0);
    an    : out std_logic_vector(3 downto 0);
    btnC  : in  std_logic;
    btnU  : in  std_logic;
    btnL  : in  std_logic;
    btnR  : in  std_logic;
    btnD  : in  std_logic; 
    RsRx  : in  std_logic;  -- UART receiver
    RsTx  : out std_logic   -- UART transmitter
  );
end basys3_wrapper;

architecture arch of basys3_wrapper is

  signal clk_soc : std_logic;
  signal gpio_out_temp : std_logic_vector(31 downto 0); -- TODO
  
  signal clk_1hz  : std_logic := '0';
  signal clk_1Mhz : std_logic := '0';
  signal clk_btn  : std_logic := '0';

  -- Debug
  signal dbg_rs3_val    : std_logic_vector(31 downto 0);
  signal dbg_curr_instr : std_logic_vector(31 downto 0);
  signal dbg_curr_pc    : std_logic_vector(31 downto 0);
  signal dbg_imm        : std_logic_vector(31 downto 0);
  signal dbg_alu_result : std_logic_vector(31 downto 0);
  signal dbg_ctrl_sigs  : std_logic_vector(31 downto 0);
  signal debug_output   : std_logic_vector(31 downto 0);

begin

  soc_inst : entity work.soc_top(arch)
    generic map (
      CLK_FREQ_HZ => 100000000
    )
    port map (
      clk         => clk,
      clk_dbg     => clk_soc,
      rst_n       => NOT btnC,
      uart_rx     => RsRx,
      uart_tx     => RsTx,
      gpio_in     => (others => '0'), -- TODO
      gpio_out    => gpio_out_temp, -- TODO
      -- Debug
      dbg_rs3_sel     => sw(15 downto 11),
      dbg_rs3_val     => dbg_rs3_val,
      dbg_curr_instr  => dbg_curr_instr,
      dbg_imm         => dbg_imm,
      dbg_curr_pc     => dbg_curr_pc,
      dbg_alu_result  => dbg_alu_result,
      dbg_ctrl_sigs   => dbg_ctrl_sigs
    );
  
  -- 1Hz Clock divider
  clk_div_1hz: process (clk)
    variable counter : integer range 0 to 100000000 := 0;
  begin
    if rising_edge(clk) then
      if counter = 100000000 then
        clk_1hz <= '1';
        counter := 0;
      else
        clk_1hz <= '0';
        counter := counter + 1;
      end if;
    end if;
  end process clk_div_1hz;

  -- 1Hz Clock divider
  clk_div_1Mhz: process (clk)
    variable counter : integer range 0 to 100 := 0;
  begin
    if rising_edge(clk) then
      if counter = 100 then
        clk_1Mhz <= '1';
        counter := 0;
      else
        clk_1Mhz <= '0';
        counter := counter + 1;
      end if;
    end if;
  end process clk_div_1Mhz;
  
  btn_clk_gen : process (clk)
  begin
    if rising_edge(clk) then
      if btnD = '1' then
        clk_btn <= '1';
      else
        clk_btn <= '0';
      end if;
    end if;
  end process btn_clk_gen;

  -- clk_soc source mux
  with sw(1 downto 0) select
    clk_soc <=  clk_1Mhz when "00",
                clk_1hz  when "01",
                clk_btn  when others;
  
  -- Debug

  -- debug_output source mux
  with sw(4 downto 2) select
    debug_output <= dbg_rs3_val     when "000",
                    dbg_curr_instr  when "001",
                    dbg_curr_pc     when "010",
                    dbg_imm         when "011",
                    dbg_alu_result  when "100",
                    dbg_ctrl_sigs   when "101",
                    x"DEADBEEF"     when others;
  
  seg7 : entity work.seg7_controller(arch)
    port map (
      clk    => clk,
      di     => debug_output(31 downto 16),
      an_sel => an,
      digit  => seg
    );
  
  led <= debug_output(15 downto 0);
  
end arch;
