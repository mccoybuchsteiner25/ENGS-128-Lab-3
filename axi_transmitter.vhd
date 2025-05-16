----------------------------------------------------------------------------
--  Lab 2
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: McCoy Buchsteiner
----------------------------------------------------------------------------
--	Description: AXI transmitter 
----------------------------------------------------------------------------
-- Libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
----------------------------------------------------------------------------

-- Entity definition
entity axis_transmitter is
    Generic (
        AC_DATA_WIDTH       : integer := 24;
        AUDIO_DATA_WIDTH    : integer := 32);
    Port (
        -- Timing
		lrclk_i           : in std_logic;
		
		-- M
		m00_axis_aclk     : in std_logic;
		m00_axis_aresetn  : in std_logic;
		m00_axis_tready   : in std_logic;
		m00_axis_tdata    : out std_logic_vector(AUDIO_DATA_WIDTH-1 downto 0);
		m00_axis_tlast    : out std_logic;
		m00_axis_tstrb    : out std_logic_vector(3 downto 0);
		m00_axis_tvalid   : out std_logic;
		
		-- Data
		left_audio_data_i     : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_i    : in std_logic_vector(AC_DATA_WIDTH-1 downto 0));  
end axis_transmitter;

----------------------------------------------------------------------------
architecture Behavioral of axis_transmitter is
----------------------------------------------------------------------------

constant LR_BIT_INDEX   : integer := 24;

signal LR_mux_set       : std_logic := '0';
signal data_reg_enable  : std_logic := '0';

signal right_audio_data, left_audio_data    : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal right_axis_data, left_axis_data      : std_logic_vector(AUDIO_DATA_WIDTH-1 downto 0) := (others => '0');

type state_type is (IdleHigh, IdleLow, LatchInputs, SetRightValid, SetLeftValid);
signal curr_state, next_state : state_type := IdleLow;

----------------------------------------------------------------------------

component double_ff_sync is
    Generic ( AC_DATA_WIDTH : integer := 24);
    Port ( 
        clk_i           : in std_logic;
        async_data_i    : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
        sync_data_o     : out std_logic_vector(AC_DATA_WIDTH-1 downto 0));
end component;
        
----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Port mapping
----------------------------------------------------------------------------

left_sync_int : double_ff_sync
    generic map ( AC_DATA_WIDTH => AC_DATA_WIDTH)
    port map (
        clk_i           => m00_axis_aclk,
        async_data_i    => left_audio_data_i,
        sync_data_o     => left_audio_data);

right_sync_int : double_ff_sync
    generic map ( AC_DATA_WIDTH => AC_DATA_WIDTH)
    port map (
        clk_i           => m00_axis_aclk,
        async_data_i    => right_audio_data_i,
        sync_data_o     => right_audio_data);

----------------------------------------------------------------------------
-- Processes
----------------------------------------------------------------------------

axis_stream : process(LR_mux_set, right_axis_data, left_axis_data, m00_axis_aresetn)
begin
    if (m00_axis_aresetn = '0') then
        m00_axis_tdata <= (others => '0');
    elsif LR_mux_set = '0' then
        m00_axis_tdata <= right_axis_data;
    elsif LR_mux_set = '1' then
        m00_axis_tdata <= left_axis_data;
    end if;
end process axis_stream;

----------------------------------------------------------------------------

latch_audio_inputs : process(m00_axis_aclk)
begin
    if rising_edge(m00_axis_aclk) then
        if (m00_axis_aresetn = '0') then
            left_axis_data <= (others => '0');
            right_axis_data <= (others => '0');
        elsif data_reg_enable = '1' then
            -- Set left data reg 
            left_axis_data <= (others => '0');
            left_axis_data(LR_BIT_INDEX) <= '1';
            left_axis_data(AC_DATA_WIDTH-1 downto 0) <= left_audio_data;
            
            -- Set right data register 
            right_axis_data <= (others => '0');
            right_axis_data(AC_DATA_WIDTH-1 downto 0) <= right_audio_data;
        end if;
    end if;
end process latch_audio_inputs;

----------------------------------------------------------------------------

next_state_logic : process(curr_state, lrclk_i, m00_axis_tready)
begin
    next_state <= curr_state;
    
    case curr_state is 
    
        when IdleHigh => 
            if lrclk_i = '0' then
                next_state <= LatchInputs;
            elsif lrclk_i = '1' then
                next_state <= IdleHIGH;
            end if;
        
        when LatchInputs =>
            next_state <= IdleLow;
            
        when IdleLow => 
            if lrclk_i = '0' then
                next_state <= IdleLow;
            elsif lrclk_i = '1' then
                next_state <= SetRightValid;
            end if;
            
        when SetRightValid => 
            if m00_axis_tready = '0' then
                next_state <= SetRightValid;
            elsif m00_axis_tready = '1' then
                next_state <= SetLeftValid;
            end if;
        
        when SetLeftValid => 
            if m00_axis_tready = '0' then
                next_state <= SetLeftValid;
            elsif m00_axis_tready = '1' then
                next_state <= IdleHigh;
            end if;
            
        when others => 
            next_state <= IdleHigh;
    end case;
end process next_state_logic;

----------------------------------------------------------------------------

output_logic : process(curr_state)
begin 
    m00_axis_tvalid <= '0';
    LR_mux_set      <= '0';
    data_reg_enable <= '0';
    
    case curr_state is 
    
        when IdleHigh => 
            LR_mux_set <= '1';
        
        when LatchInputs =>
            data_reg_enable <= '1';
            
        when IdleLow => 
            
        when SetRightValid => 
            m00_axis_tvalid <= '1';
        
        when SetLeftValid => 
            m00_axis_tvalid <= '1';
            LR_mux_set <= '1';
            
        when others => 
            
    end case;

end process output_logic;

----------------------------------------------------------------------------

state_update : process(m00_axis_aclk)
begin
    if rising_edge(m00_axis_aclk) then
        curr_state <= next_state;
    end if;
end process state_update;

---------------------------------------------------------------------------- 
end Behavioral;