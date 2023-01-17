--  
--  uart_receiver.vhd
--  
--  The uart receiver
--  Used to recieve machine language programs
--  
--  receiving 0xAAAAAAAA means start programming
--  receiving 0x00000000 means end programming
--  

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_receiver is
  generic (
    baud_rate: integer := 9600
  );
  port (
    clk     : in  std_logic;
    din     : in  std_logic;
    dout    : out std_logic_vector (31 downto 0);
    prg_en  : out std_logic;
    prg_addr: out std_logic_vector(31 downto 0)
  );
end uart_receiver;

architecture arch of uart_receiver is
  
  -- Receiver samples at 16 times the baud rate
  -- Assumes clock speed is 100 MHz
  constant sample_clk_ticks: integer := 3125000/baud_rate;
  
  type bytevector is array(0 to 2) of std_logic_vector(7 downto 0);
  signal bytes: bytevector;
  
  type states is (idle, start, data, stop);
  signal state: states := idle;
  
  signal sample_clk  : std_logic := '0';
  signal stored_byte : std_logic_vector(7 downto 0) := (others => '0');
  
  signal programming: std_logic := '0';
  signal addr: unsigned(31 downto 0) := (others => '0');
  
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
  
  state_machine : process(clk)
    variable clktickcounter : integer range 0 to 15 := 0; -- counts the ticks for sampling the next byte
    variable bitcounter     : integer range 0 to 7  := 0; -- counts which bit is being received
    variable bytecounter    : integer range 0 to 3  := 0; -- counts which byte is being recieved
  begin
    if rising_edge(sample_clk) then
      case state is
        
        when idle =>
          
          stored_byte <= (others => '0');
          clktickcounter := 0;
          bitcounter := 0;
          
          -- the input signal going low indicates to start receiving
          if din = '0' then
            state <= start;
          end if;
          
        when start =>
          
          if din = '0' then
            if clktickcounter = 7 then -- wait half the baud rate so the data can be sampled in the middle of each bit
              state <= data;              
              clktickcounter := 0;
            else
              clktickcounter := clktickcounter + 1;
            end if;
          else
            state <= idle;
          end if;
          
        when data =>
          
          if clktickcounter = 15 then
            stored_byte(bitcounter) <= din;
            clktickcounter := 0;
            if bitcounter = 7 then
              state <= stop;
              clktickcounter := 0;
            else
              bitcounter := bitcounter + 1;
            end if;
          else
            clktickcounter := clktickcounter + 1;
          end if;
          
        when stop =>
          
          if clktickcounter = 15 then -- wait for 1 baud rate cycle
            if bytecounter = 3 then
              if programming = '0' then
                if bytes(0) & bytes(1) & bytes(2) & stored_byte = X"aaaaaaaa" then
                  dout <= X"00000013";
                  programming <= '1';
                  addr <= (others => '0');
                end if;
              else
                if bytes(0) & bytes(1) & bytes(2) & stored_byte = X"00000000" then
                  dout <= X"00000000";
                  programming <= '0';
                else
                  dout <= bytes(0) & bytes(1) & bytes(2) & stored_byte;
                  addr <= addr + 4;
                end if;
              end if;
              bytecounter := 0;
            else
              bytes(bytecounter) <= stored_byte;
              bytecounter := bytecounter + 1;
            end if;
            state <= idle;
          else
            clktickcounter := clktickcounter + 1;
          end if;
          
        when others =>
          
          state <= idle;
          
      end case;
    end if;
  end process state_machine;
  
  prg_en <= programming;
  prg_addr <= std_logic_vector(addr);
  
end arch;
