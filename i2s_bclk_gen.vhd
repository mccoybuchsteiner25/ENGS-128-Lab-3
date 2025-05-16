----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: Clock divider with BUFG output
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

library UNISIM;
use UNISIM.VComponents.all;     -- contains BUFG clock buffer

----------------------------------------------------------------------------
-- Entity definition
entity i2s_bclk_gen is
    Generic (CLK_DIV_RATIO : integer := 4);
    Port (  clk_i : in STD_LOGIC;
            clk_unbuf_o : out std_logic;		  
            clk_o : out STD_LOGIC); 
end i2s_bclk_gen;

----------------------------------------------------------------------------
-- Architecture Definition 
architecture Behavioral of i2s_bclk_gen is

----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
constant CLK_DIV_TC : integer := integer(CLK_DIV_RATIO/2);
constant CLK_COUNT_BITS : integer := integer(ceil(log2(real(CLK_DIV_TC))));
signal unbuffered_clk : std_logic := '1';
signal clock_counter : unsigned(CLK_COUNT_BITS-1 downto 0) := (others => '0');


----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Slow clock counter
slow_clock_counter : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (clock_counter = CLK_DIV_TC-1) then 
            clock_counter <= (others => '0');   -- reset
        else
            clock_counter <= clock_counter + 1; -- increment
        end if;
    end if;
end process slow_clock_counter;

----------------------------------------------------------------------------
-- Slow clock toggle
slow_clock_ff : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (clock_counter = CLK_DIV_TC-1) then 
            unbuffered_clk <= not unbuffered_clk;
        end if;
    end if;
end process slow_clock_ff;

----------------------------------------------------------------------------   
-- Clock buffer     
slow_clock_bufg : BUFG
port map (
   O => clk_o,     -- 1-bit output: Clock output
   I => unbuffered_clk  -- 1-bit input: Clock input
);

clk_unbuf_o <= unbuffered_clk;
end Behavioral;