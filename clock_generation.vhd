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
entity i2s_clock_gen is
    Port ( 
--          sysclk_125MHz_i : in std_logic; --comment out for block design
          mclk_i : in std_logic;        -- comment out for simulation
          mclk_fwd_o : out std_logic;  
          bclk_fwd_o : out std_logic;
          adc_lrclk_fwd_o : out std_logic;
          dac_lrclk_fwd_o : out std_logic;
        
          mclk_o    : out std_logic; -- 12.288 MHz output of clk_wiz	
		   bclk_o    : out std_logic;	
		   lrclk_o   : out std_logic); 
end i2s_clock_gen;

----------------------------------------------------------------------------
-- Architecture Definition 
architecture Behavioral of i2s_clock_gen is

----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
constant BCLK_DIV_RATIO : integer := 4;
constant LRCLK_DIV_RATIO : integer := 64;
--signal mclk_i : std_logic := '0'; -- comment out for block design
signal bclk : std_logic := '0';
signal lrclk : std_logic := '0';
signal lrclk_unbuf : std_logic := '0';

--component clk_wiz_0 
--    Port (
--         clk_out1 : out std_logic;
--         clk_in1  : in  std_logic
--  );
--end component;

component i2s_bclk_gen is
    Generic (CLK_DIV_RATIO : integer := BCLK_DIV_RATIO);
    Port (  clk_i : in std_logic;
            clk_unbuf_o : out std_logic;
            clk_o : out std_logic);
end component;

component i2s_lrclk_gen is 
    Generic (CLK_DIV_RATIO : integer := LRCLK_DIV_RATIO);
    Port (  clk_i : in std_logic;
            clk_unbuf_o : out std_logic;
            clk_o : out std_logic);
end component;
----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------

 -- comment out for block design
--mclk_gen: clk_wiz_0
--    port map( 
--        clk_out1 => mclk_i,
--        clk_in1 => sysclk_125MHz_i
--   );

bclk_gen : i2s_bclk_gen
    port map (
         clk_i => mclk_i,
 --       clk_i => sysclk_125MHz_i,
        clk_unbuf_o => open,
        clk_o => bclk);

lrclk_gen : i2s_lrclk_gen
    port map (
        clk_i => bclk,
        clk_unbuf_o => open,
        clk_o => lrclk);

mclk_o <= mclk_i;
bclk_o <= bclk;
lrclk_o <= lrclk;

mclk_forward_oddr : ODDR
generic map(
 DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
 INIT => '0', -- Initial value for Q port ('1' or '0')
 SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
port map (
 Q => mclk_fwd_o,     -- 1-bit DDR output
 C => mclk_i,     -- 1-bit clock input
 --C => sysclk_125MHz_i,
 CE => '1', -- 1-bit clock enable input
 D1 => '1', -- 1-bit data input (positive edge)
 D2 => '0', -- 1-bit data input (negative edge)
 R => '0', -- 1-bit reset input
 S => '0' -- 1-bit set input
);

bclk_forward_oddr : ODDR
generic map(
 DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
 INIT => '0', -- Initial value for Q port ('1' or '0')
 SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
port map (
 Q => bclk_fwd_o,     -- 1-bit DDR output
 C => bclk,     -- 1-bit clock input
 CE => '1', -- 1-bit clock enable input
 D1 => '1', -- 1-bit data input (positive edge)
 D2 => '0', -- 1-bit data input (negative edge)
 R => '0', -- 1-bit reset input
 S => '0' -- 1-bit set input
);

adc_lrclk_forward_oddr : ODDR
generic map(
 DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
 INIT => '0', -- Initial value for Q port ('1' or '0')
 SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
port map (
 Q => adc_lrclk_fwd_o,     -- 1-bit DDR output
 C => lrclk,     -- 1-bit clock input
 CE => '1', -- 1-bit clock enable input
 D1 => '1', -- 1-bit data input (positive edge)
 D2 => '0', -- 1-bit data input (negative edge)
 R => '0', -- 1-bit reset input
 S => '0' -- 1-bit set input
);

dac_lrclk_forward_oddr : ODDR
generic map(
 DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
 INIT => '0', -- Initial value for Q port ('1' or '0')
 SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
port map (
 Q => dac_lrclk_fwd_o,     -- 1-bit DDR output
 C => lrclk,     -- 1-bit clock input
 CE => '1', -- 1-bit clock enable input
 D1 => '1', -- 1-bit data input (positive edge)
 D2 => '0', -- 1-bit data input (negative edge)
 R => '0', -- 1-bit reset input
 S => '0' -- 1-bit set input
);


end Behavioral;