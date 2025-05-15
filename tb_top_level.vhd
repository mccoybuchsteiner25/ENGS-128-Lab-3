----------------------------------------------------------------------------
--  Lab 2: AXI Stream FIFO and DMA
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: Testbench for AXI stream interface of I2S controller
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

----------------------------------------------------------------------------
-- Entity Declaration
entity tb_top_level is
end tb_top_level;

----------------------------------------------------------------------------
architecture testbench of tb_top_level is
----------------------------------------------------------------------------

-- Constants
constant AXIS_DATA_WIDTH : integer := 32;        -- AXI stream data bus
constant AXIS_FIFO_DEPTH : integer := 12; 
constant CLOCK_PERIOD : time := 10ns;            -- 100 MHz system clock period
constant MCLK_PERIOD : time := 81.38 ns;        -- 12.288 MHz MCLK
constant SAMPLING_FREQ  : real := 48000.00;     -- 48 kHz sampling rate
constant T_SAMPLE : real := 1.0/SAMPLING_FREQ;

--AXI 
constant REG_DATA_WIDTH : integer := 4;
constant C_S00_AXI_DATA_WIDTH : integer := 32;
constant C_S00_AXI_ADDR_WIDTH : integer := 4;

----------------------------------------------------------------------------------

-- AXI signals
signal S_AXI_ACLK                     :  std_logic;
signal S_AXI_ARESETN                  :  std_logic;
signal S_AXI_AWADDR                   :  std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
signal S_AXI_AWVALID                  :  std_logic;
signal S_AXI_WDATA                    :  std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
signal S_AXI_WSTRB                    :  std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
signal S_AXI_WVALID                   :  std_logic;
signal S_AXI_BREADY                   :  std_logic;
signal S_AXI_ARADDR                   :  std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
signal S_AXI_ARVALID                  :  std_logic;
signal S_AXI_RREADY                   :  std_logic;
signal S_AXI_ARREADY                  : std_logic;
signal S_AXI_RDATA                    : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
signal S_AXI_RRESP                    : std_logic_vector(1 downto 0);
signal S_AXI_RVALID                   : std_logic;
signal S_AXI_WREADY                   : std_logic;
signal S_AXI_BRESP                    : std_logic_vector(1 downto 0);
signal S_AXI_BVALID                   : std_logic;
signal S_AXI_AWREADY                  : std_logic;
signal S_AXI_AWPROT                   : std_logic_vector(2 downto 0);
signal S_AXI_ARPROT                   : std_logic_vector(2 downto 0);

----------------------------------------------------------------------------------

--Testbench Signals
signal enable_send, enable_read : std_logic;
signal axi_data_out : std_logic_vector(REG_DATA_WIDTH-1 downto 0);
signal axi_data_write : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
signal data_select : std_logic_vector(C_S00_AXI_ADDR_WIDTH-3 downto 0);
signal axi_reg : integer := 0;

signal enable_i_s, areset_i_s : std_logic := '0'; 
signal ch_select_i_s : std_logic_vector(1 downto 0);

-- Input waveform
constant AUDIO_DATA_WIDTH : integer := 24;
constant SINE_FREQ : real := 1000.0;
constant SINE_AMPL  : real := real(2**(AUDIO_DATA_WIDTH-1)-1);

----------------------------------------------------------------------------

-- Signals to hook up to DUT
signal clk : std_logic := '0';
signal mclk_s, bclk_s, lrclk_s : std_logic := '0';
signal mute_en_sw : std_logic;
signal mute_n, bclk, mclk, data_in, data_out, lrclk : std_logic;

----------------------------------------------------------------------------

-- Testbench signals
signal bit_count : integer;

signal reset_n : std_logic := '1';
signal enable_stream : std_logic := '0';
signal test_num : integer := 0;

----------------------------------------------------------------------------

--AXI FIFO signal
signal fifo0_s00_axis_tready : std_logic := '0';
signal fifo0_s00_axis_tdata  : std_logic_vector(AXIS_DATA_WIDTH-1 downto 0);
signal fifo0_s00_axis_tstrb   : std_logic_vector((AXIS_DATA_WIDTH/8)-1 downto 0);
signal fifo0_s00_axis_tlast : std_logic := '0';
signal fifo0_s00_axis_tvalid : std_logic := '0';

signal fifo0_m00_axis_tready : std_logic := '0';
signal fifo0_m00_axis_tdata  : std_logic_vector(AXIS_DATA_WIDTH-1 downto 0);
signal fifo0_m00_axis_tstrb   : std_logic_vector((AXIS_DATA_WIDTH/8)-1 downto 0);
signal fifo0_m00_axis_tlast : std_logic := '0';
signal fifo0_m00_axis_tvalid : std_logic := '0';

signal fifo1_s00_axis_tready : std_logic := '0';
signal fifo1_s00_axis_tdata  : std_logic_vector(AXIS_DATA_WIDTH-1 downto 0);
signal fifo1_s00_axis_tstrb   : std_logic_vector((AXIS_DATA_WIDTH/8)-1 downto 0);
signal fifo1_s00_axis_tlast : std_logic := '0';
signal fifo1_s00_axis_tvalid : std_logic := '0';

signal fifo1_m00_axis_tready : std_logic := '0';
signal fifo1_m00_axis_tdata  : std_logic_vector(AXIS_DATA_WIDTH-1 downto 0);
signal fifo1_m00_axis_tstrb   : std_logic_vector((AXIS_DATA_WIDTH/8)-1 downto 0);
signal fifo1_m00_axis_tlast : std_logic := '0';
signal fifo1_m00_axis_tvalid : std_logic := '0';

----------------------------------------------------------------------------

-- AXI Stream
signal M_AXIS_TDATA, S_AXIS_TDATA : std_logic_vector(AXIS_DATA_WIDTH-1 downto 0);
signal M_AXIS_TSTRB, S_AXIS_TSTRB : std_logic_vector((AXIS_DATA_WIDTH/8)-1 downto 0);
signal M_AXIS_TVALID, S_AXIS_TVALID : std_logic := '0';
signal M_AXIS_TREADY, S_AXIS_TREADY : std_logic := '0';
signal M_AXIS_TLAST, S_AXIS_TLAST : std_logic := '0';

----------------------------------------------------------------------------

-- AXI stream component
component axis_i2s_wrapper is
	generic (
		-- Parameters of Axi Stream Bus Interface S00_AXIS, M00_AXIS
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4;
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4;
		C_AXI_STREAM_DATA_WIDTH	: integer	:= 32;
		DDS_DATA_WIDTH : integer := 24;         -- DDS data width
        DDS_PHASE_DATA_WIDTH : integer := 12;
		AC_DATA_WIDTH           : integer   := 24
	);
    Port ( 
        ----------------------------------------------------------------------------
        -- Fabric clock from Zynq PS
		sysclk_i : in  std_logic;	
		
		-- Select bit for DDS
		input_sel_i         : in std_logic;
		
        ----------------------------------------------------------------------------
        -- I2S audio codec ports		
		-- User controls
		ac_mute_en_i : in STD_LOGIC;
		
		-- Audio Codec I2S controls
        ac_bclk_o : out STD_LOGIC;
        ac_mclk_o : out STD_LOGIC;
        ac_mute_n_o : out STD_LOGIC;	-- Active Low
        
        -- Audio Codec DAC (audio out)
        ac_dac_data_o : out STD_LOGIC;
        ac_dac_lrclk_o : out STD_LOGIC;
        
        -- Audio Codec ADC (audio in)
        ac_adc_data_i : in STD_LOGIC;
        ac_adc_lrclk_o : out STD_LOGIC;
        
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
		
        ----------------------------------------------------------------------------
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
end component;

----------------------------------------------------------------------------

-- FIR Wrapper
component axis_fir_wrapper is
	generic (
		-- Parameters of Axi Stream Bus Interface S00_AXIS, M00_AXIS
		M_AXI_DATA_WIDTH : integer := 32;
		S_AXI_DATA_WIDTH : integer := 32;
		C_AXI_STREAM_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_DATA_WIDTH : integer := 32;
        C_S00_AXI_ADDR_WIDTH : integer := 4
	);
    Port ( 
        ----------------------------------------------------------------------------
        -- clocks 
        lrclk_i : in std_logic;
       	
		--filter select 
		ch_select_i : in std_logic_vector(1 downto 0);
		
		--passthrough select
		enable_i : in std_logic;

        --reset 
        aresetn_i : in std_logic; 

        ----------------------------------------------------------------------------
        -- AXI Stream Interface (Receiver/Responder)
    	s_axis_aclk : in std_logic;
    	s_axis_tdata : in std_logic_vector(S_AXI_DATA_WIDTH-1 downto 0);
    	s_axis_tvalid : in std_logic;
    	s_axis_tready : out std_logic;
    	
    	m_axis_aclk : in std_logic;
    	m_axis_tready : in std_logic;
    	m_axis_tvalid : out std_logic;
    	m_axis_tdata : out std_logic_vector(M_AXI_DATA_WIDTH-1 downto 0)
		
		);
end component;

----------------------------------------------------------------------------

component axis_fifo is
	generic (
		DATA_WIDTH	: integer	:= AXIS_DATA_WIDTH;
		FIFO_DEPTH	: integer	:= AXIS_FIFO_DEPTH
	);
	port (
	
		-- Ports of Axi Responder Bus Interface S00_AXIS
		s00_axis_aclk     : in std_logic;
		s00_axis_aresetn  : in std_logic;
		s00_axis_tready   : out std_logic;
		s00_axis_tdata	  : in std_logic_vector(DATA_WIDTH-1 downto 0);
		s00_axis_tstrb    : in std_logic_vector((DATA_WIDTH/8)-1 downto 0);
		s00_axis_tlast    : in std_logic;
		s00_axis_tvalid   : in std_logic;

		-- Ports of Axi Controller Bus Interface M00_AXIS
		m00_axis_aclk     : in std_logic;
		m00_axis_aresetn  : in std_logic;
		m00_axis_tvalid   : out std_logic;
		m00_axis_tdata    : out std_logic_vector(DATA_WIDTH-1 downto 0);
		m00_axis_tstrb    : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast    : out std_logic;
		m00_axis_tready   : in std_logic
	);
end component;

----------------------------------------------------------------------------

component i2s_clock_gen is
    Port (
       sysclk_125MHz_i     : in std_logic;
 --       mclk_i : in std_logic;
        mclk_fwd_o          : out std_logic;
        bclk_fwd_o          : out std_logic;
        adc_lrclk_fwd_o     : out std_logic;
        dac_lrclk_fwd_o     : out std_logic;
        
        mclk_o              : out std_logic; --comment out for block design
        bclk_o              : out std_logic;
        lrclk_o             : out std_logic);
end component;

----------------------------------------------------------------------------

-- Procedure to write data to our AXI IP registers
procedure master_write_axi_reg(
    signal S_AXI_AWADDR : out std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
    signal S_AXI_WDATA : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal S_AXI_WSTRB : out std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
    signal enable_send : out std_logic;
    signal axi_register : in integer;
    signal write_data    : in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal S_AXI_BVALID : in std_logic) is
 begin
    S_AXI_AWADDR <= (others => '0');   
    S_AXI_AWADDR(C_S00_AXI_ADDR_WIDTH-1 downto 2) <= std_logic_vector(to_unsigned(axi_register,C_S00_AXI_ADDR_WIDTH-2));
    S_AXI_WSTRB <= (others => '1');
    S_AXI_WDATA <= std_logic_vector(resize(unsigned(write_data),C_S00_AXI_DATA_WIDTH));
    enable_send <= '1';             --Start AXI Write to responder
    wait for 1 ns; 
    enable_send <= '0';             --Clear Start Send Flag
    
    wait until S_AXI_BVALID = '1';
    wait until S_AXI_BVALID = '0';  --AXI Write finished
    S_AXI_WSTRB <= (others => '0');
    wait for CLOCK_PERIOD;

 end procedure master_write_axi_reg;

----------------------------------------------------------------------------
-- Procedure to read data from our AXI IP registers
procedure master_read_axi_reg(
    signal S_AXI_ARADDR : out std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
    signal enable_read : out std_logic;
    signal axi_register : in integer;
    signal S_AXI_RVALID : in std_logic) is
 begin
    S_AXI_ARADDR <= (others => '0');
    S_AXI_ARADDR(C_S00_AXI_ADDR_WIDTH-1 downto 2) <= std_logic_vector(to_unsigned(axi_register,C_S00_AXI_ADDR_WIDTH-2));
    enable_read <= '1';         --Start AXI Read from responder
    wait for 1 ns; 
    enable_read <= '0';         --Clear "Start Read" Flag
    wait until S_AXI_RVALID = '1';
    wait until S_AXI_RVALID = '0';
    wait for CLOCK_PERIOD;

 end procedure master_read_axi_reg;

----------------------------------------------------------------------------------
begin
----------------------------------------------------------------------------------

-- Instantiate dut
clock_dut : i2s_clock_gen
port map (
        sysclk_125MHz_i    => clk,
--        mclk_i              =>
        mclk_fwd_o         => open,
        bclk_fwd_o          => open,
        adc_lrclk_fwd_o     => open,
        dac_lrclk_fwd_o     => open,
        
       mclk_o              => mclk_s,
        bclk_o              => bclk_s,
        lrclk_o             => lrclk_s
);

----------------------------------------------------------------------------

fir_wrapper : axis_fir_wrapper
port map (
         lrclk_i => lrclk_s,
       	
		--filter select 
		ch_select_i => ch_select_i_s,
		
		--passthrough select
		enable_i =>  enable_i_s,

        --reset 
        aresetn_i => areset_i_s,

        ----------------------------------------------------------------------------
        -- AXI Stream Interface (Receiver/Responder)
    	s_axis_aclk => clk,
    	s_axis_tdata => fifo0_m00_axis_tdata,
    	s_axis_tvalid => fifo0_m00_axis_tvalid,
    	s_axis_tready => fifo0_m00_axis_tready,
    	
    	m_axis_aclk =>  clk,
    	m_axis_tready => fifo1_s00_axis_tready,
    	m_axis_tvalid => fifo1_s00_axis_tvalid,
    	m_axis_tdata => fifo1_s00_axis_tdata
);

----------------------------------------------------------------------------

fifo0 : axis_fifo
port map (
    -- Ports of Axi Responder Bus Interface S00_AXIS
		s00_axis_aclk    =>   clk,
		s00_axis_aresetn  =>  reset_n,
		s00_axis_tready   => fifo0_s00_axis_tready,
		s00_axis_tdata	  => fifo0_s00_axis_tdata,
		s00_axis_tstrb    => fifo0_s00_axis_tstrb,
		s00_axis_tlast    => fifo0_s00_axis_tlast,
		s00_axis_tvalid  => fifo0_s00_axis_tvalid,

		-- Ports of Axi Controller Bus Interface M00_AXIS
		m00_axis_aclk     => clk,
		m00_axis_aresetn  => reset_n,
		m00_axis_tvalid   => M_AXIS_TVALID,
		m00_axis_tdata    => M_AXIS_TDATA,
		m00_axis_tstrb    => M_AXIS_TSTRB,
		m00_axis_tlast    => M_AXIS_TLAST,
		m00_axis_tready   => M_AXIS_TREADY
);

----------------------------------------------------------------------------

fifo1 : axis_fifo
port map (
        s00_axis_aclk    => clk,
		s00_axis_aresetn  => reset_n,
		s00_axis_tready   => fifo0_m00_axis_tready,
		s00_axis_tdata	  => fifo0_m00_axis_tdata,
		s00_axis_tstrb    => fifo0_m00_axis_tstrb,
		s00_axis_tlast    => fifo0_m00_axis_tlast,
		s00_axis_tvalid  => fifo0_m00_axis_tvalid,

		-- Ports of Axi Controller Bus Interface M00_AXIS
		m00_axis_aclk     => clk,
		m00_axis_aresetn  => reset_n,
		m00_axis_tvalid   => S_AXIS_TVALID,
		m00_axis_tdata    => S_AXIS_TDATA,
		m00_axis_tstrb    => S_AXIS_TSTRB,
		m00_axis_tlast    => S_AXIS_TLAST,
		m00_axis_tready   => S_AXIS_TREADY
);

----------------------------------------------------------------------------

dut: axis_i2s_wrapper
port map (

    sysclk_i => clk,
    input_sel_i => '1',
    ac_mute_en_i => mute_en_sw,
    ac_bclk_o => bclk,
    ac_mclk_o => mclk,
    ac_mute_n_o => mute_n,
    ac_dac_data_o => data_out,
    ac_dac_lrclk_o => open,
    ac_adc_data_i => data_in,
    ac_adc_lrclk_o => lrclk,
    
--      reg_select_i => data_select,
--      data_o => axi_data_out,
    s00_axi_aclk    => S_AXI_ACLK,
    s00_axi_aresetn => S_AXI_ARESETN,
    s00_axi_awaddr  => S_AXI_AWADDR,
    s00_axi_awprot  => S_AXI_AWPROT,
    s00_axi_awvalid => S_AXI_AWVALID,
    s00_axi_awready => S_AXI_AWREADY,
    s00_axi_wdata   => S_AXI_WDATA,
    s00_axi_wstrb   => S_AXI_WSTRB,
    s00_axi_wvalid  => S_AXI_WVALID,
    s00_axi_wready  => S_AXI_WREADY,
    s00_axi_bresp   => S_AXI_BRESP,
    s00_axi_bvalid  => S_AXI_BVALID,
    s00_axi_bready  => S_AXI_BREADY,
    s00_axi_araddr  => S_AXI_ARADDR,
    s00_axi_arprot  => S_AXI_ARPROT,
    s00_axi_arvalid => S_AXI_ARVALID,
    s00_axi_arready => S_AXI_ARREADY,
    s00_axi_rdata   => S_AXI_RDATA,
    s00_axi_rresp   => S_AXI_RRESP,
    s00_axi_rvalid  => S_AXI_RVALID,
    s00_axi_rready  => S_AXI_RREADY,
    
    
    
    s00_axis_aclk => clk,
    s00_axis_aresetn => reset_n,
    s00_axis_tready => S_AXIS_TREADY,
    s00_axis_tdata => S_AXIS_TDATA,
    s00_axis_tstrb => S_AXIS_TSTRB,
    s00_axis_tlast => S_AXIS_TLAST,
    s00_axis_tvalid => S_AXIS_TVALID, 

    m00_axis_aclk => clk,
    m00_axis_aresetn => reset_n,
    m00_axis_tvalid => M_AXIS_TVALID,
    m00_axis_tdata => M_AXIS_TDATA,
    m00_axis_tstrb => M_AXIS_TSTRB,
    m00_axis_tlast => M_AXIS_TLAST,
    m00_axis_tready => M_AXIS_TREADY);

---------------------------------------------------------------------------- 
 
-- Hook up transmitter interface to receiver (passthrough test)   
S_AXIS_TDATA <= M_AXIS_TDATA;
S_AXIS_TSTRB <= M_AXIS_TSTRB;
S_AXIS_TLAST <= M_AXIS_TLAST;
S_AXIS_TVALID <= M_AXIS_TVALID;
M_AXIS_TREADY <= S_AXIS_TREADY;

----------------------------------------------------------------------------   
-- Processes
----------------------------------------------------------------------------   
M_AXIS_TREADY <= '1';

-- Generate clock        
clock_gen_process : process
begin
	clk <= '0';				-- start low
	S_AXI_ACLK <= '0';
	wait for CLOCK_PERIOD/2;		-- wait for half a clock period
	loop							-- toggle, and loop
	  clk <= not(clk);
	  S_AXI_ACLK <= not(S_AXI_ACLK);
	  wait for CLOCK_PERIOD/2;
	end loop;
end process clock_gen_process;


----------------------------------------------------------------------------
-- Initiate process which simulates a master wanting to write.
 -- This process is blocked on a "Send Flag" (enable_send).
 -- When the flag goes to 1, the process exits the wait state and
 -- execute a write transaction.
 send : PROCESS
 BEGIN
    S_AXI_AWVALID <= '0';
    S_AXI_WVALID <= '0';
    S_AXI_BREADY <= '0';
    loop
        wait until enable_send = '1';
        wait until S_AXI_ACLK= '0';
            S_AXI_AWVALID <= '1';
            S_AXI_WVALID <= '1';
        wait until (S_AXI_AWREADY and S_AXI_WREADY) = '1';  --Client ready to read address/data        
            S_AXI_BREADY <= '1';
        wait until S_AXI_BVALID = '1';  -- Write result valid
            assert S_AXI_BRESP = "00" report "AXI data not written" severity failure;
            S_AXI_AWVALID <= '0';
            S_AXI_WVALID <= '0';
            S_AXI_BREADY <= '1';
        wait until S_AXI_BVALID = '0';  -- All finished
            S_AXI_BREADY <= '0';
    end loop;
 END PROCESS send;

----------------------------------------------------------------------------
-- Initiate process which simulates a master wanting to read.
-- This process is blocked on a "Read Flag" (enable_read).
-- When the flag goes to 1, the process exits the wait state and
-- execute a read transaction.
read : PROCESS
BEGIN
    S_AXI_ARVALID <= '0';
    S_AXI_RREADY <= '0';
    loop
        wait until enable_read = '1';
        wait until S_AXI_ACLK= '0';
            S_AXI_ARVALID <= '1';
            S_AXI_RREADY <= '1';
        wait until (S_AXI_RVALID and S_AXI_ARREADY) = '1';  --Client provided data
            assert S_AXI_RRESP = "00" report "AXI data not written" severity failure;
            S_AXI_ARVALID <= '0';
            S_AXI_RREADY <= '0';
    end loop;
END PROCESS read;

 
----------------------------------------------------------------------------
-- Testbench Stimulus
----------------------------------------------------------------------------
stimulus : PROCESS
 BEGIN
    -- Initialize, reset
    S_AXI_ARESETN <= '0';
    enable_send <= '0';
    enable_read <= '0';
    data_select <= (others => '0');
    axi_data_write <= (others => '0');
    axi_reg <= 0;           -- we are writing to AXI register 0
    ch_select_i_s <= "00";
    enable_i_s <= '1';
    
    wait for 15 ns;
    S_AXI_ARESETN <= '1';
    
    
    wait until rising_edge(S_AXI_ACLK);
    wait for CLOCK_PERIOD;
    
    
    -- write data to register 0
    axi_reg <= 0;
    axi_data_write <= x"0000000A";
    wait for 100 ns;
    master_write_axi_reg(S_AXI_AWADDR, S_AXI_WDATA, S_AXI_WSTRB, enable_send, axi_reg, axi_data_write, S_AXI_BVALID);
    wait for 100 ns;
    
    axi_reg <= 1;
    axi_data_write <= x"0000000A";
    wait for 100 ns;
    master_write_axi_reg(S_AXI_AWADDR, S_AXI_WDATA, S_AXI_WSTRB, enable_send, axi_reg, axi_data_write, S_AXI_BVALID);
    wait for 100 ns;
        
    std.env.stop;
 END PROCESS stimulus;

----------------------------------------------------------------------------
-- Disable mute
mute_en_sw <= '0';

------------------------------------------------------------------------------
---- Generate input data (stimulus)
------------------------------------------------------------------------------
--generate_audio_data: process
--    variable t : real := 0.0;
--begin		
------------------------------------------------------------------------------
---- Loop forever	
--loop	
------------------------------------------------------------------------------
---- Progress one sample through the sine wave:
--sine_data <= std_logic_vector(to_signed(integer(SINE_AMPL*sin(math_2_pi*SINE_FREQ*t) ), AUDIO_DATA_WIDTH));

------------------------------------------------------------------------------
---- Take sample
--wait until lrclk = '1';
--sine_data_tx <= std_logic_vector(unsigned(not(sine_data(AUDIO_DATA_WIDTH-1)) & sine_data(AUDIO_DATA_WIDTH-2 downto 0)));

------------------------------------------------------------------------------
---- Transmit sample to right audio channel
------------------------------------------------------------------------------
--bit_count <= AUDIO_DATA_WIDTH-1;            -- Initialize bit counter, send MSB first
--for i in 0 to AUDIO_DATA_WIDTH-1 loop
--    wait until bclk = '0';
--    data_in <= sine_data_tx(bit_count-i);     -- Set input data
--end loop;

--data_in <= '0';
--bit_count <= AUDIO_DATA_WIDTH-1;            -- Reset bit counter to MSB

------------------------------------------------------------------------------
----Transmit sample to left audio channel
------------------------------------------------------------------------------
--wait until lrclk = '0';
--for i in 0 to AUDIO_DATA_WIDTH-1 loop
--    wait until bclk = '0';
--    data_in <= sine_data_tx(bit_count-i);     -- Set input data
--end loop;
--data_in <= '0';

------------------------------------------------------------------------------						
----Increment by one sample
--t := t + T_SAMPLE;
--end loop;
    
--end process generate_audio_data;

----------------------------------------------------------------------------

end testbench;
