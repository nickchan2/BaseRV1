--  
--  File:   core_reg_file.vhd
--  Brief:  The register file
--
--  Copyright (C) 2023 Nick Chan
--  See the LICENSE file at the root of the project for licensing info.
--  

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.soc_package.all;

entity core_reg_file is
  port (
    clk     : in  std_logic;
    rst_n   : in  std_logic;
    rs1_sel : in  rf_sel_t;
    rs2_sel : in  rf_sel_t;
    rs1_val : out word_t;
    rs2_val : out word_t;
    rd_sel  : in  rf_sel_t;
    rd_we   : in  std_logic;
    rd_wd   : in  word_t;

    -- Debug
    dbg_rs3_sel : in  rf_sel_t;
    dbg_rs3_val : out word_t
  );
end core_reg_file;

architecture arch of core_reg_file is
  
  type reg_file_t is array(1 to 31) of word_t;
  
  signal regs: reg_file_t;
  
begin
  
  gen_regs: for ii in 1 to 31 generate
    process (clk, rst_n)
    begin
      if rst_n = '0' then
        regs(ii) <= X"DEADBEEF";
      elsif rising_edge(clk) AND (rd_we = '1') AND (to_integer(unsigned(rd_sel)) = ii) then
        regs(ii) <= rd_wd;
      end if;
    end process;
  end generate;
  
  with rs1_sel select rs1_val <=
    (others => '0')                     when "00000",
    regs(to_integer(unsigned(rs1_sel))) when others;
  
  with rs2_sel select rs2_val <=
    (others => '0')                     when "00000",
    regs(to_integer(unsigned(rs2_sel))) when others;
  
  with dbg_rs3_sel select dbg_rs3_val <=
    (others => '0')                         when "00000",
    regs(to_integer(unsigned(dbg_rs3_sel))) when others;
  
end arch;
