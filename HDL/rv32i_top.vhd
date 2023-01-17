--  
--  rv32i_top.vhd
--  
--  Connects the CPU to the board IO
--  

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rv32i_top is
  port (
    clk   : in std_logic;
    sw    : in std_logic_vector(15 downto 0);
    led   : out std_logic_vector(15 downto 0);
    seg   : out std_logic_vector(6 downto 0);
    an    : out std_logic_vector(3 downto 0);
    btnC  : in std_logic;
    btnU  : in std_logic;
    btnL  : in std_logic;
    btnR  : in std_logic;
    btnD  : in std_logic; 
    RsRx  : in std_logic; -- UART receiver
    RsTx  : out std_logic -- UART transmitter
  );
end rv32i_top;

architecture arch of rv32i_top is
  
  -- the uart receiver baud rate
  constant baud_rate: integer := 9600;
  
  -- signal db_btn: std_logic_vector(4 downto 0);

  signal clk10hz: std_logic := '0';
  
  type states is (init, prg, rinit, run);
  signal state: states := init;

  -- cpu debug
  signal reg: std_logic_vector(31 downto 0);
  signal instr: std_logic_vector(31 downto 0);
  signal pc: std_logic_vector(31 downto 0);
  signal imm: std_logic_vector(31 downto 0);
  signal debug_output: std_logic_vector(31 downto 0);
  
  signal cpu_clk: std_logic;
  signal reset: std_logic;
  
  -- signals for programming the cpu
  signal newinstr: std_logic_vector(31 downto 0);
  signal prg_en: std_logic := '0';
  signal prg_addr: std_logic_vector(31 downto 0);
  
  signal pmem_addr: std_logic_vector(31 downto 0) := (others => '0');
  signal pmem_wen: std_logic := '0';
  signal drun: std_logic := '1';

begin

  state_machine : process(clk)
  begin
    if rising_edge(clk) then
      case state is

        -- initial state, cpu not doing anything & waiting for program
        when init =>

          if prg_en then
            state <= prg;
          end if;

          pmem_addr <= (others => '0');
          pmem_wen <= '0';
          drun <= '1';
          reset <= '0';

        -- prgramming state
        when prg =>

          if prg_en = '0' then
            state <= rinit;
          end if;

          pmem_addr <= prg_addr;
          pmem_wen <= '1';
          drun <= '1';
          reset <= '0';

        -- will set all regs to 0 in future, currently used for debugging
        when rinit =>
          
          if btnL = '1' then
            state <= run;
          end if;
          
          pmem_addr <= X"000000" & "0" & sw(15 downto 11) & "00";
          pmem_wen <= '0';
          drun <= '1';
          reset <= '1';

        -- cpu is executing instructions
        when run =>

          if btnC = '1' then
            state <= rinit;
          elsif prg_en then
            state <= prg;
          end if;

          pmem_addr <= (others => '0');
          pmem_wen <= '0';
          drun <= '0';
          reset <= '0';
        
        when others =>

          state <= init;

      end case;
    end if;
  end process state_machine;

  uart : entity work.uart_receiver(arch)
    generic map (
      baud_rate => baud_rate
    )
    port map (
      clk => clk,
      din => RsRx,
      dout => newinstr,
      prg_en => prg_en,
      prg_addr => prg_addr
    );
  
  -- Clock divider
  clk_div: process(clk)
    variable counter : integer range 0 to 10000000 := 0;
  begin
    if rising_edge(clk) then
      if counter = 10000000 then
        clk10hz <= '1';
        counter := 0;
      else
      clk10hz <= '0';
        counter := counter + 1;
      end if;
    end if;
  end process clk_div;
  
  -- Clock select
  with sw(1 downto 0) select
    cpu_clk <= clk when "00",
               clk10hz when "01",
               btnD when others;
  
  cpu_inst : entity work.cpu(arch)
    port map (
      clk100mhz => clk,
      clkinstr  => cpu_clk,
      reset     => reset,
      prg_en    => drun,
      prg_addr  => pmem_addr,
      pmem_wen  => pmem_wen,
      instri    => newinstr,
      rs3       => sw(15 downto 11),
      reg3      => reg,
      instro    => instr,
      pmem_addro=> pc,
      immo      => imm
    );
  
  -- output select
  with sw(3 downto 2) select
    debug_output <= reg when "00",
                    instr when "01",
                    pc when "10",
                    imm when others;
  
  seg7 : entity work.seg7_controller(arch)
    port map (
      clk    => clk,
      di     => debug_output(31 downto 16),
      an_sel => an,
      digit  => seg
    );
  
  led <= debug_output(15 downto 0);
  
  -- No uart transmitter
  RsTx <= '1';
  
end arch;
