--  
--  File:   uart.vhd
--  Brief:  The UART
--
--  Copyright (C) 2023 Nick Chan
--  See the LICENSE file at the root of the project for licensing info.
--  

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is
  generic (
    CLK_FREQ_HZ     : integer;
    UART_BAUD_RATE  : integer
  );
  port (
    clk             : in  std_logic;
    rst_n           : in  std_logic;
    uart_rx_pin     : in  std_logic;
    uart_tx_pin     : out std_logic;

    uart_addr       : in  std_logic_vector(1 downto 0);
    uart_en         : in  std_logic;
    uart_wd         : in  std_logic_vector(7 downto 0);
    uart_we         : in  std_logic;
    uart_do         : out std_logic_vector(7 downto 0)
  );
end uart;

architecture arch of uart is

  -- Receiver samples at 16 times the baud rate
  -- Assumes clock speed is 100 MHz
  constant sample_clk_ticks         : integer := 3125000 / UART_BAUD_RATE; -- TODO remove this
  constant TICKS_IN_FULL_BAUD_CYCLE : integer := CLK_FREQ_HZ / UART_BAUD_RATE; -- TODO
  constant TICKS_IN_HALF_BAUD_CYCLE : integer := CLK_FREQ_HZ / 2 / UART_BAUD_RATE; -- TODO
  
  type uart_state_t is (idle, start, data, stop);
  signal rx_state         : uart_state_t := idle;
  signal tx_state         : uart_state_t := idle;
  
  signal sample_clk       : std_logic := '0';
  
  signal received_byte    : std_logic_vector(7 downto 0) := (others => '0');
  signal pending_rx_data  : std_logic_vector(7 downto 0) := (others => '0');
  signal pending_rx_ready : std_logic := '0';
  signal pending_rx_cmp   : std_logic := '1';
  signal rx_ready         : std_logic := '0';
  signal reading_rx       : std_logic;
  signal rx_data          : std_logic_vector(7 downto 0) := (others => '0');
  
  signal tx_busy          : std_logic := '0';
  signal tx_data          : std_logic_vector(7 downto 0)  := (others => '0');
  signal writing_tx       : std_logic;
  
  signal uart_do_wd       : std_logic_vector(7 downto 0);

begin
  
  -- generates the clock for sampling the input
  sample_clk_gen : process(clk)
    variable tickcounter: integer range 0 to sample_clk_ticks - 1 := 0;
  begin
    if rising_edge(clk) then
      if tickcounter = sample_clk_ticks - 1 then
        sample_clk <= not sample_clk;
        tickcounter := 0;
      else
        tickcounter := tickcounter + 1;
      end if;
    end if;
  end process;
  
  uart_receiver : process(clk)
    variable clktickcounter : integer range 0 to TICKS_IN_FULL_BAUD_CYCLE - 1 := 0; -- counts the ticks for sampling the next byte
    variable bitcounter     : integer range 0 to 7  := 0; -- counts which bit is being received
  begin
    if rising_edge(clk) then
      case rx_state is
        
        when idle =>
          
          received_byte <= (others => '0');
          clktickcounter := 0;
          bitcounter := 0;
          
          if uart_rx_pin = '0' then
            -- The input signal has gone low which indicates the start bit
            rx_state <= start;
          end if;
          
        when start =>
          
          if uart_rx_pin = '0' then -- Ensure that the rx pin is still low
            if clktickcounter = TICKS_IN_HALF_BAUD_CYCLE - 1 then -- wait half the baud rate so the data can be sampled in the middle of each bit
              rx_state <= data;              
              clktickcounter := 0;
            else
              clktickcounter := clktickcounter + 1;
            end if;
          else
            rx_state <= idle;
          end if;
          
        when data =>
          
          if clktickcounter = TICKS_IN_FULL_BAUD_CYCLE - 1 then
            received_byte(bitcounter) <= uart_rx_pin;
            clktickcounter := 0;
            if bitcounter = 7 then
              -- All bits of the byte have been received
              rx_state <= stop;
              clktickcounter := 0;
            else
              bitcounter := bitcounter + 1;
            end if;
          else
            clktickcounter := clktickcounter + 1;
          end if;
          
        when stop =>
          
          if clktickcounter = TICKS_IN_FULL_BAUD_CYCLE - 1 then -- wait for 1 baud rate cycle
            pending_rx_data   <= received_byte;
            pending_rx_ready  <= pending_rx_ready XOR '1';
            rx_state          <= idle;
          else
            clktickcounter := clktickcounter + 1;
          end if;
          
        when others =>
          
          rx_state <= idle;
          
      end case;
    end if;
  end process uart_receiver;
  
  reading_rx <= '1' when (uart_en & uart_we & uart_addr = "1000") else '0';

  writing_tx <= '1' when (uart_en & uart_we & uart_addr = "1110") else '0';

  uart_transmitter : process(clk)
    variable tick_count : integer range 0 to TICKS_IN_FULL_BAUD_CYCLE - 1 := 0;
    variable bit_count  : integer range 0 to 7 := 0;
  begin
    if rising_edge(clk) then
      case tx_state is

        when idle =>

          uart_tx_pin <= '1';
          tx_busy     <= '0';
          tick_count  := 0;
          bit_count   := 0;

          if writing_tx = '1' then
            -- The tx data register has been written to so start transmitting
            tx_busy   <= '1';
            tx_data   <= uart_wd;
            tx_state  <= start;
          end if;

        when start =>

          -- Tx pin goes low to indicate start bit
          uart_tx_pin <= '0';

          if tick_count = (TICKS_IN_FULL_BAUD_CYCLE - 1) then
            tx_state    <= data;
            tick_count  := 0;
          else
            tick_count := tick_count + 1;
          end if;

        when data =>

          uart_tx_pin <= tx_data(bit_count);

          if tick_count = (TICKS_IN_FULL_BAUD_CYCLE - 1) then
            tick_count := 0;
            if bit_count = 7 then
              tx_state    <= stop;
              tick_count  := 0;
            else
              bit_count := bit_count + 1;
            end if;
          else
            tick_count := tick_count + 1;
          end if;

        when stop =>

          uart_tx_pin <= '1';

          if tick_count = (TICKS_IN_FULL_BAUD_CYCLE - 1) then
            tx_state <= idle;
          else
            tick_count := tick_count + 1;
          end if;

        when others =>

          tx_state <= idle;

      end case;
    end if;
  end process uart_transmitter;

  with uart_addr select uart_do_wd <=
    rx_data               when "00",
    "0000000" & rx_ready  when "01",
    "0000000" & tx_busy   when "11",
    x"00"                 when others;

  process(clk)
  begin
    if rising_edge(clk) then
      if reading_rx = '1' then
        rx_ready <= '0';
      elsif (pending_rx_ready XNOR pending_rx_cmp) = '1' then
        rx_ready <= '1';
        rx_data <= pending_rx_data;
        pending_rx_cmp <= pending_rx_cmp XOR '1';
      end if;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      uart_do <= uart_do_wd;
    end if;
  end process;

end arch;
