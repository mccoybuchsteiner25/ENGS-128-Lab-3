----------------------------------------------------------------------------
--  Lab 1: DDS and the Audio Codec
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: DDS Controller with Block Memory (BROM) for storing the samples
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;             -- required for modulus function
use IEEE.STD_LOGIC_UNSIGNED.ALL;

----------------------------------------------------------------------------
-- Entity definition
entity dds_controller is
    Generic ( DDS_DATA_WIDTH : integer := 24;       -- DDS data width
              DDS_PHASE_DATA_WIDTH : integer := 12);      -- DDS phase increment data width
    Port ( 
      clk_i         : in std_logic;
      enable_i      : in std_logic;
      reset_i       : in std_logic;
      phase_inc_i   : in std_logic_vector(DDS_PHASE_DATA_WIDTH-1 downto 0);
      
      data_o        : out std_logic_vector(DDS_DATA_WIDTH-1 downto 0)); 
end dds_controller;
----------------------------------------------------------------------------
architecture Behavioral of dds_controller is
----------------------------------------------------------------------------
-- Define constants, signals, and declare sub-components
----------------------------------------------------------------------------
constant BRAM_ADDR_WIDTH : integer := 12;
constant BRAM_DATA_WIDTH : integer := 24;

signal dds_address : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
signal dds_data : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := (others => '0');


component blk_mem_gen_0
   port (
    clka : in std_logic;
    addra : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    douta : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0)
   );
end component;
----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Port-map sub-components, and describe the entity behavior
----------------------------------------------------------------------------
--data_o <= std_logic_vector(resize(unsigned(dds_data),DATA_WIDTH));
data_o <= dds_data;

dds_sample_rom : blk_mem_gen_0
port map ( clka => clk_i,
            addra => dds_address,
            douta => dds_data);


sample_counter : process(clk_i)
begin 
    if rising_edge(clk_i) then 
        if (reset_i = '1') then
            dds_address <= (others => '0');
        elsif (enable_i = '1') then
             dds_address <= std_logic_vector(unsigned(dds_address) + unsigned(phase_inc_i) + 1);
        end if;
    end if;
end process sample_counter;

----------------------------------------------------------------------------   
end Behavioral;