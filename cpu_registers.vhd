--  
--  cpu_registers.vhd
--  
--  The register file
--  

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cpu_registers is
  port (
    clk   : in std_logic;
    reset : in std_logic;
    wen   : in std_logic;
    rs1   : in std_logic_vector(4 downto 0);
    rs2   : in std_logic_vector(4 downto 0);
    rs3   : in std_logic_vector(4 downto 0);
    rws   : in std_logic_vector(4 downto 0);
    din   : in std_logic_vector(31 downto 0);
    dout1 : out std_logic_vector(31 downto 0);
    dout2 : out std_logic_vector(31 downto 0);
    dout3 : out std_logic_vector(31 downto 0)
  );
end cpu_registers;

architecture arch of cpu_registers is
  
  type vec_array is array(1 to 31) of std_logic_vector(31 downto 0);
  
  signal regs: vec_array;
  signal wenv: std_logic_vector(31 downto 0);
  signal wdata: std_logic_vector(31 downto 0);
  
begin
  
  with reset select
    wdata <= din when '0',
             X"00000000" when others;
  
  decode_wen : entity work.decoder(arch)
    port map (
      sel => rws,
      en => wen,
      dout => wenv
    );
  
  gen_regs: for ii in 1 to 31 generate
    process(clk)
    begin
      if(rising_edge(clk) and (wenv(ii) = '1' or reset = '1')) then
        regs(ii) <= wdata;
      end if;
    end process;
  end generate;
  
  with rs1 select
    dout1 <= (others => '0') when "00000",
             regs(to_integer(unsigned(rs1))) when others;
  
  with rs2 select
    dout2 <= (others => '0') when "00000",
             regs(to_integer(unsigned(rs2))) when others;
  
  -- dout3 is used for debugging
  with rs3 select
    dout3 <= (others => '0') when "00000",
             regs(to_integer(unsigned(rs3))) when others;
  
end arch;
