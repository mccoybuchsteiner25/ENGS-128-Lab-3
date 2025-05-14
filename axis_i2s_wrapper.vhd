----------------------------------------------------------------------------
--  Lab 2: AXI Stream FIFO and DMA
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: McCoy Buchsteiner
----------------------------------------------------------------------------
--	Description: AXI stream wrapper for controlling I2S audio data flow
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;     
use IEEE.STD_LOGIC_UNSIGNED.ALL;                                    
----------------------------------------------------------------------------
-- Entity definition
entity axis_i2s_wrapper is
	generic (
		-- Parameters of Axi Stream Bus Interface S00_AXIS, M00_AXIS
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4;
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4;
		C_AXI_STREAM_DATA_WIDTH	: integer	:= 32;
		DDS_DATA_WIDTH : integer := 24;         -- DDS data width
        DDS_PHASE_DATA_WIDTH : integer := 12;
		AC_DATA_WIDTH           : integer   := 24);
    Port ( 
        ----------------------------------------------------------------------------
        -- Fabric clock from Zynq PS
		sysclk_i : in  std_logic;	
		
        ----------------------------------------------------------------------------
        -- I2S audio codec ports		
		-- User controls
		ac_mute_en_i        : in STD_LOGIC;
		
		-- Audio Codec I2S controls
        ac_bclk_o           : out STD_LOGIC;
        ac_mclk_o           : out STD_LOGIC;
        ac_mute_n_o         : out STD_LOGIC;	-- Active Low
        
        -- Audio Codec DAC (audio out)
        ac_dac_data_o       : out STD_LOGIC;
        ac_dac_lrclk_o      : out STD_LOGIC;
        
        -- Audio Codec ADC (audio in)
        ac_adc_data_i       : in STD_LOGIC;
        ac_adc_lrclk_o      : out STD_LOGIC;
        
        -- Debug Signals (out)
        dbg_left_audio_rx_o     : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
        dbg_right_audio_rx_o    : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
        dbg_left_audio_tx_o     : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
        dbg_right_audio_tx_o    : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
        
        left_dds_phase_inc_dbg_o   : out std_logic_vector(DDS_PHASE_DATA_WIDTH-1 downto 0);
		right_dds_phase_inc_dbg_o  : out std_logic_vector(DDS_PHASE_DATA_WIDTH-1 downto 0);
        
        ----------------------------------------------------------------------------
        --AXI LITE PORTS 
        s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic;
        
        
        
        
        
        -- AXI Stream Interface (Receiver/Responder)
    	-- Ports of Axi Responder Bus Interface S00_AXIS
		s00_axis_aclk     : in std_logic;
		s00_axis_aresetn  : in std_logic;
		s00_axis_tready   : out std_logic;
		s00_axis_tdata	  : in std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0);
		s00_axis_tstrb    : in std_logic_vector((C_AXI_STREAM_DATA_WIDTH/8)-1 downto 0);
		s00_axis_tlast    : in std_logic;
		s00_axis_tvalid   : in std_logic;
		
        -- AXI Stream Interface (Tranmitter/Controller)
		-- Ports of Axi Controller Bus Interface M00_AXIS
		m00_axis_aclk     : in std_logic;
		m00_axis_aresetn  : in std_logic;
		m00_axis_tvalid   : out std_logic;
		m00_axis_tdata    : out std_logic_vector(C_AXI_STREAM_DATA_WIDTH-1 downto 0);
		m00_axis_tstrb    : out std_logic_vector((C_AXI_STREAM_DATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast    : out std_logic;
		m00_axis_tready   : in std_logic);
end axis_i2s_wrapper;
----------------------------------------------------------------------------
architecture Behavioral of axis_i2s_wrapper is
----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
signal dds_enable_i_s : std_logic := '1'; 
signal dds_reset_i_s : std_logic := '0';

constant FIFO_DEPTH : integer := 10;

signal mclk_s, bclk_s, lrclk_s : std_logic := '0';

signal left_audio_data_rx, right_audio_data_rx : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');

signal left_audio_data_tx, right_audio_data_tx : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');

signal ac_mute_n_s, ac_mute_n_reg_s : std_logic := '0';

----------------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------------

-- Clock generation
component i2s_clock_gen is
    Port (
        sysclk_125MHz_i     : in std_logic;
 --       mclk_i : in std_logic;
        mclk_fwd_o          : out std_logic;
        bclk_fwd_o          : out std_logic;
        adc_lrclk_fwd_o     : out std_logic;
        dac_lrclk_fwd_o     : out std_logic;
        
        mclk_o              : out std_logic;
        bclk_o              : out std_logic;
        lrclk_o             : out std_logic);
end component;
---------------------------------------------------------------------------- 

-- I2S receiver
--component i2s_receiver is
--    Generic (AC_DATA_WIDTH : integer := 24);
--    Port (
--        -- Timing
--		mclk_i                : in std_logic;	
--		bclk_i                : in std_logic;	
--		lrclk_i               : in std_logic;
		
--		-- Data
--		adc_serial_data_i     : in std_logic;
--		left_audio_data_o     : out std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
--		right_audio_data_o    : out std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0')
--		);  
--end component;

--DDS 
component engs128_axi_dds is
	generic (
	    ----------------------------------------------------------------------------
		-- Users to add parameters here
		DDS_DATA_WIDTH : integer := 24;         -- DDS data width
        DDS_PHASE_DATA_WIDTH : integer := 12;   -- DDS phase increment data width
        ----------------------------------------------------------------------------

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4
	);
	port (
	    ----------------------------------------------------------------------------
		-- Users to add ports here
		dds_clk_i     : in std_logic;
		dds_enable_i  : in std_logic;
		dds_reset_i   : in std_logic;
		left_dds_data_o    : out std_logic_vector(DDS_DATA_WIDTH-1 downto 0);
		right_dds_data_o    : out std_logic_vector(DDS_DATA_WIDTH-1 downto 0);
		
		-- Debug ports to send to ILA
		left_dds_phase_inc_dbg_o : out std_logic_vector(DDS_PHASE_DATA_WIDTH-1 downto 0);   
		right_dds_phase_inc_dbg_o : out std_logic_vector(DDS_PHASE_DATA_WIDTH-1 downto 0);   
		
		----------------------------------------------------------------------------
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Ports of Axi Responder/Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic
	);
end component;

---------------------------------------------------------------------------- 

-- I2S transmitter
component i2s_transmitter is
    Generic (AC_DATA_WIDTH : integer := 24);
    Port (
        -- Timing
		mclk_i                : in std_logic;	
		bclk_i                : in std_logic;	
		lrclk_i               : in std_logic;
		
		-- Data
		left_audio_data_i     : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_i    : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		dac_serial_data_o     : out std_logic);  
end component;

---------------------------------------------------------------------------- 

-- AXI stream transmitter
component axis_transmitter is
    Generic (
        AC_DATA_WIDTH         : integer := 24;
        AUDIO_DATA_WIDTH      : integer := 32);
    Port (
        -- Timing
		lrclk_i               : in std_logic;
		
		-- M
		m00_axis_aclk         : in std_logic;
		m00_axis_aresetn      : in std_logic;
		m00_axis_tready       : in std_logic;
		m00_axis_tdata        : out std_logic_vector(AUDIO_DATA_WIDTH-1 downto 0);
		m00_axis_tlast        : out std_logic;
		m00_axis_tstrb        : out std_logic_vector(3 downto 0);
		m00_axis_tvalid       : out std_logic;
		
		-- Data
		left_audio_data_i     : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_i    : in std_logic_vector(AC_DATA_WIDTH-1 downto 0));  
end component;
    
----------------------------------------------------------------------------
 
-- AXI stream receiver
component axis_receiver is
    Generic (
        AC_DATA_WIDTH         : integer := 24;
        AUDIO_DATA_WIDTH      : integer := 32);
    Port (
        -- Timing
		lrclk_i               : in std_logic;
		
		-- M
		s00_axis_aclk         : in std_logic;
		s00_axis_aresetn      : in std_logic;
		s00_axis_tdata        : in std_logic_vector(AUDIO_DATA_WIDTH-1 downto 0);
		s00_axis_tlast        : in std_logic;
		s00_axis_tstrb        : in std_logic_vector(3 downto 0);
		s00_axis_tvalid       : in std_logic;
		s00_axis_tready       : out std_logic;
		
		-- Data
		left_audio_data_o     : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
		right_audio_data_o    : out std_logic_vector(AC_DATA_WIDTH-1 downto 0));  
end component;

----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Component instantiations
---------------------------------------------------------------------------- 
   
-- Clock generation
clock_gen : i2s_clock_gen
    port map (
        sysclk_125MHz_i     => sysclk_i,
        
        mclk_fwd_o          => ac_mclk_o,
        bclk_fwd_o          => ac_bclk_o,
        adc_lrclk_fwd_o     => ac_adc_lrclk_o,
        dac_lrclk_fwd_o     => ac_dac_lrclk_o,
        
        mclk_o              => mclk_s,
        bclk_o              => bclk_s,
        lrclk_o             => lrclk_s);


---------------------------------------------------------------------------- 

-- I2S receiver
--receiver_i2s : i2s_receiver 
--    generic map (AC_DATA_WIDTH => AC_DATA_WIDTH)
--    port map (

--        -- Timing
--		mclk_i                => mclk_s, 	
--		bclk_i                => bclk_s,	
--		lrclk_i               => lrclk_s,
		
--		-- Data
--		adc_serial_data_i     => ac_adc_data_i,
--		left_audio_data_o     => left_audio_data_rx,
--		right_audio_data_o    => right_audio_data_rx);

dds : engs128_axi_dds
	port map (
	    ----------------------------------------------------------------------------
		-- Users to add ports here
		dds_clk_i  => lrclk_s,  
		dds_enable_i  => dds_enable_i_s,
		dds_reset_i   => dds_reset_i_s,
		left_dds_data_o    => left_audio_data_rx,
		right_dds_data_o   => right_audio_data_rx,
		
		-- Debug ports to send to ILA
		left_dds_phase_inc_dbg_o   => left_dds_phase_inc_dbg_o,
		right_dds_phase_inc_dbg_o  =>  right_dds_phase_inc_dbg_o,
		
		----------------------------------------------------------------------------
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Ports of Axi Responder/Slave Bus Interface S00_AXI
		s00_axi_aclk	=> s00_axis_aclk,
		s00_axi_aresetn	=> s00_axis_aresetn,
		s00_axi_awaddr	=> s00_axi_awaddr,
		s00_axi_awprot	=> s00_axi_awprot,
		s00_axi_awvalid	=> s00_axi_awvalid,
		s00_axi_awready	=> s00_axi_awready,
		s00_axi_wdata	=> s00_axi_wdata,
		s00_axi_wstrb	=> s00_axi_wstrb,
		s00_axi_wvalid	=> s00_axi_wvalid,
		s00_axi_wready	=> s00_axi_wready,
		s00_axi_bresp	=> s00_axi_bresp,
		s00_axi_bvalid	=> s00_axi_bvalid,
		s00_axi_bready	=> s00_axi_bready,
		s00_axi_araddr	=> s00_axi_araddr,
		s00_axi_arprot	=> s00_axi_arprot,
		s00_axi_arvalid	=> s00_axi_arvalid,
		s00_axi_arready	=> s00_axi_arready,
		s00_axi_rdata	=> s00_axi_rdata,
		s00_axi_rresp	=> s00_axi_rresp,
		s00_axi_rvalid	=> s00_axi_rvalid,
		s00_axi_rready	=> s00_axi_rready
	);

---------------------------------------------------------------------------- 

-- I2S transmitter
transmitter_i2s : i2s_transmitter
    generic map (AC_DATA_WIDTH => AC_DATA_WIDTH)
    port map (

        -- Timing
		mclk_i                => mclk_s, 	
		bclk_i                => bclk_s,	
		lrclk_i               => lrclk_s,
		
		-- Data
		dac_serial_data_o     => ac_dac_data_o,
		left_audio_data_i     => left_audio_data_tx,
		right_audio_data_i    => right_audio_data_tx);

---------------------------------------------------------------------------- 

-- AXI stream transmitter
transmitter_axis : axis_transmitter
    generic map (
        AC_DATA_WIDTH         => AC_DATA_WIDTH,
        AUDIO_DATA_WIDTH            => C_AXI_STREAM_DATA_WIDTH)
    port map (
        -- Timing
		lrclk_i               => lrclk_s,
		
		-- M
		m00_axis_aclk         => m00_axis_aclk, 
		m00_axis_aresetn      => m00_axis_aresetn,
		m00_axis_tready       => m00_axis_tready,
		m00_axis_tdata        => m00_axis_tdata,
		m00_axis_tlast        => m00_axis_tlast,
		m00_axis_tstrb        => m00_axis_tstrb,
		m00_axis_tvalid       => m00_axis_tvalid,
		
		-- Data
		left_audio_data_i     => left_audio_data_rx,
		right_audio_data_i    => right_audio_data_rx);
    
---------------------------------------------------------------------------- 

-- AXI stream receiver
receiver_axis : axis_receiver
    generic map (
        AC_DATA_WIDTH         => AC_DATA_WIDTH,
        AUDIO_DATA_WIDTH      => C_AXI_STREAM_DATA_WIDTH)
    port map (
        -- Timing
		lrclk_i               => lrclk_s,
		
		-- S
	    s00_axis_aclk         => s00_axis_aclk, 
		s00_axis_aresetn      => s00_axis_aresetn,
		s00_axis_tready       => s00_axis_tready,
		s00_axis_tdata        => s00_axis_tdata,
		s00_axis_tlast        => s00_axis_tlast,
		s00_axis_tstrb        => s00_axis_tstrb,
		s00_axis_tvalid       => s00_axis_tvalid,
		
		-- Data
		left_audio_data_o     => left_audio_data_tx,
		right_audio_data_o    => right_audio_data_tx);
		
---------------------------------------------------------------------------- 
-- Logic
---------------------------------------------------------------------------- 

dbg_left_audio_rx_o     <= left_audio_data_rx;
dbg_right_audio_rx_o    <= right_audio_data_rx;

dbg_left_audio_tx_o     <= left_audio_data_tx;
dbg_right_audio_tx_o    <= right_audio_data_tx;

ac_mute_n_s <= not ac_mute_en_i;
ac_mute_n_o <= ac_mute_n_reg_s;

---------------------------------------------------------------------------- 

mute_process : process(sysclk_i)
begin
    if rising_edge(sysclk_i) then
        ac_mute_n_reg_s <= ac_mute_n_s;
    end if;
end process mute_process;

----------------------------------------------------------------------------

end Behavioral;