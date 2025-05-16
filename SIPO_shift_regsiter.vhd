----------------------------------------------------------------------------
-- 	ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: Shift register with parallel load and serial output
----------------------------------------------------------------------------
-- Add libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

----------------------------------------------------------------------------
-- Entity definition
entity SIPO_shift_register is
    Generic ( DATA_WIDTH : integer := 24);
    Port ( 
      clk_i         : in std_logic;
      data_i        : in std_logic;
      load_en_i     : in std_logic;
      shift_en_i    : in std_logic;
      
      data_o        : out std_logic_vector(DATA_WIDTH-1 downto 0));
      
end SIPO_shift_register;
----------------------------------------------------------------------------
architecture Behavioral of SIPO_shift_register is
----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
-- ++++ Add internal signals here ++++
signal shift_reg: std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- ++++ Describe the behavior using processes ++++
----------------------------------------------------------------------------  
    sipo : process(clk_i)
    begin
        if rising_edge(clk_i) then
            if load_en_i = '1' then
                data_o <= shift_reg; -- sends out shift_reg as data_o
            elsif shift_en_i = '1' then
                shift_reg <= shift_reg(DATA_WIDTH-2 downto 0) & data_i; -- shifts register to the left and appends data in as the LSB
            end if;
        end if;
    end process sipo;
----------------------------------------------------------------------------   
end Behavioral;