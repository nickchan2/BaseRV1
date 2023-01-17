--  
--  cpu.vhd
--  
--  A single cycle implementation of the rv32i ISA
--  

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cpu is
  port (
    clk100mhz : in std_logic;
    clkinstr  : in std_logic;
    reset     : in std_logic;
    prg_en    : in std_logic;
    prg_addr  : in std_logic_vector(31 downto 0);
    pmem_wen  : in std_logic;
    instri    : in std_logic_vector(31 downto 0);
    rs3       : in std_logic_vector(4 downto 0);
    reg3      : out std_logic_vector(31 downto 0);
    instro    : out std_logic_vector(31 downto 0);
    pmem_addro: out std_logic_vector(31 downto 0);
    immo      : out std_logic_vector(31 downto 0)
  );
end cpu;

architecture arch of cpu is
  
  signal pc_reg: std_logic_vector(31 downto 0);   -- current program counter value
  signal pc_next: std_logic_vector(31 downto 0);  -- next program counter value
  signal pc_add: std_logic_vector(31 downto 0);   -- value to be added to the pc
  signal pc_sum: std_logic_vector(31 downto 0);   -- pc + pc_add
  signal pc_src: std_logic;                       -- selects pc_next source
  signal branch_en: std_logic;                    -- selects pc_add source
  
  signal rs1: std_logic_vector(4 downto 0);       -- register select 1
  signal rs2: std_logic_vector(4 downto 0);       -- register select 2
  signal rws: std_logic_vector(4 downto 0);       -- register write select
  signal rout1: std_logic_vector(31 downto 0);    -- register out 1
  signal rout2: std_logic_vector(31 downto 0);    -- register out 2
  signal reg_src: std_logic_vector(1 downto 0);   -- selects reg_din source
  signal reg_din: std_logic_vector(31 downto 0);  -- data to be written to registers
  signal reg_wen: std_logic;                      -- write enable for register file
  
  signal alu_din1: std_logic_vector(31 downto 0); -- alu data input 1
  signal alu_din2: std_logic_vector(31 downto 0); -- alu data input 2
  signal alu_dout: std_logic_vector(31 downto 0); -- alu data output
  signal alu_op: std_logic_vector(3 downto 0);    -- the alu opcode
  signal eq_flag: std_logic;                      -- equal flag
  signal lt_flag: std_logic;                      -- less than flag
  signal alu_src1: std_logic;                     -- selects alu_din1 source
  signal alu_src2: std_logic ;                    -- selects alu_din2 source
  
  signal instr: std_logic_vector(31 downto 0);    -- instruciton specified by the pc
  
  signal imm: std_logic_vector(31 downto 0);      -- immediate value generated for immediate instructions
  
  signal dmem_dtype: std_logic_vector(2 downto 0);-- data type for the data memory
  signal dmem_dout: std_logic_vector(31 downto 0);-- data memory output
  signal dmem_wen: std_logic;                     -- write enable for data memory
  
  signal pmem_out: std_logic_vector(31 downto 0); -- program memory data out
  signal pmem_addr: std_logic_vector(31 downto 0);-- program memory address
  
begin
  
  -- creates the program counter register
  process(clkinstr, reset, prg_en)
  begin
    if prg_en = '1' or reset = '1' then
      pc_reg <= (others => '0');
    elsif rising_edge(clkinstr) then
      pc_reg <= pc_next;
    end if;
  end process;
  
  reg_file : entity work.cpu_registers(arch)
    port map (
      clk   => clkinstr,
      reset => reset,
      wen   => reg_wen,
      rs1   => rs1,
      rs2   => rs2,
      rs3   => rs3,
      rws   => rws,
      din   => reg_din,
      dout1 => rout1,
      dout2 => rout2,
      dout3 => reg3
    );
  
  alu_inst : entity work.alu(arch)
    port map (
      din1    => alu_din1,
      din2    => alu_din2,
      op      => alu_op,
      dout    => alu_dout,
      eq_flag => eq_flag,
      lt_flag => lt_flag
    );
    
  increment_pc : entity work.adder(arch)
    port map (
      num1 => pc_reg,
      num2 => pc_add,
      sum  => pc_sum
    );
  
  data_memory : entity work.data_mem(arch)
    port map (
      clk   => clkinstr,
      addr  => alu_dout,
      dtype => dmem_dtype,
      din   => rout2,
      wen   => dmem_wen,
      dout  => dmem_dout
    );
  
  program_memory : entity work.program_mem(arch)
    port map (
      clk   => clk100mhz,
      we    => pmem_wen,
      addr  => pmem_addr,
      di    => instri,
      do    => pmem_out
    );
  
  control_unit : entity work.control(arch)
    port map (
      instr      => instr,
      eq_flag    => eq_flag,
      lt_flag    => lt_flag,
      branch_en  => branch_en,
      pc_src     => pc_src,
      reg_src    => reg_src,
      reg_wen    => reg_wen,
      dmem_wen   => dmem_wen,
      dmem_dtype => dmem_dtype,
      alu_op     => alu_op,
      alu_src1   => alu_src1,
      alu_src2   => alu_src2,
      imm        => imm,
      rs1        => rs1,
      rs2        => rs2,
      rws        => rws
    );
  
  with branch_en select
    pc_add <= X"00000004" when '0',
              imm when others;
  
  with pc_src select
    pc_next <= pc_sum when '0',
               alu_dout when others;
  
  with alu_src1 select
    alu_din1 <= rout1 when '0',
                pc_reg when others;
  
  with alu_src2 select
    alu_din2 <= rout2 when '0',
                imm when others;
  
  with reg_src select
    reg_din <= alu_dout when "00",
               dmem_dout when "01",
               pc_sum when others;
  
  with prg_en select
    instr <= pmem_out when '0',
             X"F0000013" when others; -- addi x0 x0 0 (do nothing)
  
  with prg_en select
    pmem_addr <= pc_reg when '0',
                 prg_addr when others;
  
  -- debug outputs
  instro <= pmem_out;
  pmem_addro <= pmem_addr;
  immo <= imm;
  
end arch;
