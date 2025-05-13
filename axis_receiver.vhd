  ----------------------------------------------------------------------------
--  Lab 2
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: McCoy Buchsteiner
----------------------------------------------------------------------------
--	Description: AXI receiver 
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
----------------------------------------------------------------------------

-- Entity definition
entity axis_receiver is
    Generic (
        AC_DATA_WIDTH : integer := 24;
        AUDIO_DATA_WIDTH : integer := 32);
    Port (
        -- Timing
		lrclk_i           : in std_logic;
		
		-- M
		s00_axis_aclk     : in std_logic;
		s00_axis_aresetn  : in std_logic;
		s00_axis_tdata    : in std_logic_vector(AUDIO_DATA_WIDTH-1 downto 0);
		s00_axis_tlast    : in std_logic;
		s00_axis_tstrb    : in std_logic_vector(3 downto 0);
		s00_axis_tvalid   : in std_logic;
		s00_axis_tready   : out std_logic;
		
		-- Data
		left_audio_data_o     : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_o    : out std_logic_vector(AC_DATA_WIDTH-1 downto 0));  
end axis_receiver;

----------------------------------------------------------------------------
architecture Behavioral of axis_receiver is
----------------------------------------------------------------------------

constant LR_BIT_INDEX   : integer := 24;

signal lr_data_bit      : std_logic := '0';
signal data_reg_enable  : std_logic := '0';
signal axis_tready      : std_logic := '0';
signal axis_data_0, axis_data_1 : std_logic_vector(AUDIO_DATA_WIDTH-1 downto 0) := (others => '0');

type state_type is (IdleHigh, IdleLow, LatchOutputs, SetRightReady, SetLeftReady);
signal curr_state, next_state : state_type := IdleHigh;
        
----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Processes
----------------------------------------------------------------------------

s00_axis_tready <= axis_tready;

-- AXI stream logic
latch_audio_data : process(s00_axis_aclk)
begin
    if rising_edge(s00_axis_aclk) then
        if s00_axis_tvalid = '1' AND axis_tready = '1' then
            axis_data_0 <= s00_axis_tdata;
            axis_data_1 <= axis_data_0;
        end if;
    end if;
end process latch_audio_data;

----------------------------------------------------------------------------

-- Stream Out
latch_audio_outputs : process(s00_axis_aclk)
begin
    if rising_edge(s00_axis_aclk) then 
        if data_reg_enable = '1' then 
            lr_data_bit <= axis_data_1(LR_BIT_INDEX);
            
            if lr_data_bit = '0' then
                right_audio_data_o <= axis_data_1(AC_DATA_WIDTH-1 downto 0);
                left_audio_data_o  <= axis_data_0(AC_DATA_WIDTH-1 downto 0);
            elsif lr_data_bit = '1' then
                right_audio_data_o <= axis_data_0(AC_DATA_WIDTH-1 downto 0);
                left_audio_data_o  <= axis_data_1(AC_DATA_WIDTH-1 downto 0);
            end if;
        end if;
    end if;
end process latch_audio_outputs;
                
----------------------------------------------------------------------------

-- Next state logic process
next_state_logic : process(curr_state, lrclk_i, s00_axis_tvalid)
begin
    next_state <= curr_state;
    
    case curr_state is 
    
        when IdleHigh => 
            if lrclk_i = '0' then
                next_state <= LatchOutputs;
            else
                next_state <= IdleHigh;
            end if;
        
        when LatchOutputs => 
            next_state <= IdleLow;
            
        when IdleLow => 
            if lrclk_i = '0' then
                next_state <= IdleLow;
            else
                next_state <= SetRightReady;
            end if;
            
        when SetRightReady => 
            if s00_axis_tvalid = '0' then
                next_state <= SetRightReady;
            else
                next_state <= SetLeftReady;
            end if;
            
        when SetLeftReady => 
            if s00_axis_tvalid = '0' then
                next_state <= SetLeftReady;
            else
                next_state <= IdleHigh;
            end if;
            
        when others => 
            next_state <= IdleHigh;
    end case;
end process;

----------------------------------------------------------------------------

-- Output logic process
output_logic : process(curr_state)
begin
    axis_tready <= '0';
    data_reg_enable <= '0';
    
    case curr_state is
    
        when IdleHigh =>
        
        when LatchOutputs => 
            data_reg_enable <= '1';
            
        when IdleLow => 
        
        when SetRightReady => 
            axis_tready <= '1';
            
        when SetLeftReady =>  
            axis_tready <= '1';
        
        when others =>
        
    end case;
end process output_logic;

----------------------------------------------------------------------------

-- State update process
state_update : process(s00_axis_aclk)
begin
    if rising_edge(s00_axis_aclk) then
        curr_state <= next_state;
    end if;
end process state_update;

---------------------------------------------------------------------------- 
end Behavioral;