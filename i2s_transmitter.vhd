  ----------------------------------------------------------------------------
--  Lab 1: DDS and the Audio Codec
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: I2S transmitter for SSM2603 audio codec
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
----------------------------------------------------------------------------
-- Entity definition
entity i2s_transmitter is
    Generic (AC_DATA_WIDTH : integer := 24);
    Port (

        -- Timing
		mclk_i    : in std_logic;	
		bclk_i    : in std_logic;	
		lrclk_i   : in std_logic;
		
		-- Data
		left_audio_data_i     : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_i    : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		dac_serial_data_o     : out std_logic);  
end i2s_transmitter;
----------------------------------------------------------------------------
architecture Behavioral of i2s_transmitter is
----------------------------------------------------------------------------
-- Define constants, signals, and declare sub-components
----------------------------------------------------------------------------
signal load_en_r, load_en_l, shift_en : std_logic :='0';
signal counter_tc, counter_reset : std_logic := '0';
signal shift_reg_data_in :std_logic_vector(AC_DATA_WIDTH-1 downto 0);
signal shift_reg_load_en : std_logic;

type state_type is (IdleStateR, IdleStateL, LoadRegisterR, LoadRegisterL, ShiftDataR, ShiftDataL);
signal curr_state, next_state : state_type := IdleStateR;

component shift_register is
    Generic ( AC_DATA_WIDTH : integer := AC_DATA_WIDTH );
    Port (
        clk_i       : in std_logic;
        data_i      : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
        load_en_i   : in std_logic;
        shift_en_i  : in std_logic;
        
        data_o      : out std_logic);
end component;

component counter is 
    Generic ( MAX_COUNT : integer := AC_DATA_WIDTH);
    Port ( clk_i        : in STD_LOGIC;
           reset_i      : in STD_LOGIC;
           enable_i     : in STD_LOGIC;
           tc_o         : out std_logic);
end component;

        
----------------------------------------------------------------------------
begin

shift_reg_data_in <= left_audio_data_i when (lrclk_i  = '0') else 
                     right_audio_data_i;

shift_reg_load_en <= load_en_l when (lrclk_i = '0') else 
                     load_en_r;
----------------------------------------------------------------------------
-- Port-map sub-components, and describe the entity behavior
----------------------------------------------------------------------------
shift_reg_inst : shift_register
    port map (
        clk_i => bclk_i,
        data_i => shift_reg_data_in,
        load_en_i => shift_reg_load_en,
        shift_en_i => shift_en,
        data_o => dac_serial_data_o);
    
bit_counter : counter 
    port map (
        clk_i => bclk_i,
        reset_i => counter_reset,
        enable_i => '1',
        tc_o => counter_tc);
   

next_state_logic : process(curr_state, lrclk_i, counter_tc)

begin
 
        next_state <= curr_state;
        
        case curr_state is 
        
                when IdleStateR => 
                        if(lrclk_i = '1') then
                           next_state <= LoadRegisterR;
                        end if;
                
                when LoadRegisterR => 
                        next_state <= ShiftDataR;
                
                when ShiftDataR =>
                        if(counter_tc = '1') then
                                next_state <= IdleStateL;
                        end if;
                
                when IdleStateL => 
                        if(lrclk_i = '0') then
                                next_state <= LoadRegisterL;
                        end if;
                
                when LoadRegisterL => 
                        next_state <= ShiftDataL;
                
                when ShiftDataL => 
                        if(counter_tc = '1') then
                                next_state <= IdleStateR;
                        end if;
                        
                when others => 
                        next_state <= IdleStateR;  
        end case;
end process next_state_logic;


fsm_output_logic : process(curr_state)
begin
        load_en_l <= '0';
        load_en_r <= '0';
        shift_en <= '0';
        counter_reset <= '0';
        
        case curr_state is 
        
            when IdleStateR =>
                counter_reset <= '1'; 
            
            when LoadRegisterR => 
                load_en_r <= '1';
                counter_reset <= '1';
           
            when ShiftDataR => 
                shift_en <= '1';
            
            when IdleStateL => 
                counter_reset <= '1';
                
            when LoadRegisterL => 
                load_en_l <= '1';
                counter_reset <= '1';
            
            when ShiftDataL => 
                shift_en <= '1';
            
            when others => 
            
        end case;

end process fsm_output_logic;

state_update: process (bclk_i)
begin
        if (rising_edge(bclk_i)) then
                curr_state <= next_state;
        end if;
end process state_update;
---------------------------------------------------------------------------- 
end Behavioral;