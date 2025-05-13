----------------------------------------------------------------------------
-- 	ENGS 128 Spring 2025
--	Author: McCoy Buchsteiner
----------------------------------------------------------------------------
--	Description: Shift register with parallel load and serial output
----------------------------------------------------------------------------
-- Add libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

----------------------------------------------------------------------------
-- Entity definition
entity PISO_shift_register is
    Generic ( DATA_WIDTH : integer := 24);
    Port ( 
      clk_i         : in std_logic;
      data_i        : in std_logic_vector(DATA_WIDTH-1 downto 0);
      load_en_i     : in std_logic;
      shift_en_i    : in std_logic;
      
      data_o        : out std_logic);
end PISO_shift_register;
----------------------------------------------------------------------------
architecture Behavioral of PISO_shift_register is
----------------------------------------------------------------------------

signal shift_reg: std_logic_vector(DATA_WIDTH-1 downto 0);

----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------

    data_o <= shift_reg(DATA_WIDTH-1);    
    piso : process(clk_i)
    begin
        if falling_edge(clk_i) then
            if load_en_i = '1' then
                shift_reg <= data_i;
            elsif shift_en_i = '1' then
                shift_reg <= shift_reg(DATA_WIDTH-2 downto 0) & shift_reg(DATA_WIDTH-1);
            end if;
        end if;
    end process piso;
    
----------------------------------------------------------------------------   
end Behavioral;