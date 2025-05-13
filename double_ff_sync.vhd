----------------------------------------------------------------------------
--  Lab 2
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: McCoy Buchsteiner
----------------------------------------------------------------------------
--	Description: Double Flip Flop Synchronizer
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
----------------------------------------------------------------------------

-- Entity definition
entity double_ff_sync is
    Generic ( AC_DATA_WIDTH : integer := 24);
    Port ( 
        clk_i           : in std_logic;
        async_data_i    : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
        sync_data_o     : out std_logic_vector(AC_DATA_WIDTH-1 downto 0));
end double_ff_sync;

----------------------------------------------------------------------------
architecture Behavioral of double_ff_sync is
----------------------------------------------------------------------------

-- Signals 
signal reg_metastable : std_logic_vector(AC_DATA_WIDTH-1 downto 0);

----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------

-- Double flip-flop synchronizer logic 
sync_process : process(clk_i)
begin
    if rising_edge(clk_i) then 
        reg_metastable <= async_data_i;
        sync_data_o <= reg_metastable;
    end if;
end process sync_process;

----------------------------------------------------------------------------
end Behavioral;
