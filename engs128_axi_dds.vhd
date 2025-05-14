----------------------------------------------------------------------------
--  Lab 1: DDS and the Audio Codec
--  Week 3 - AXI Lite Demo
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
--	Description: AXI Lite control interface
--  Modified from Xilinx IP generated file
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
----------------------------------------------------------------------------
entity engs128_axi_dds is
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
end engs128_axi_dds;

architecture Behavioral of engs128_axi_dds is
    ----------------------------------------------------------------------------
    -- Signals for port mapping to the DDS controllers
    signal left_dds_phase_incr : std_logic_vector(DDS_PHASE_DATA_WIDTH-1 downto 0) := (others => '0');
    signal left_phase_incr_axi_data : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
    signal right_dds_phase_incr : std_logic_vector(DDS_PHASE_DATA_WIDTH-1 downto 0) := (others => '0');
    signal right_phase_incr_axi_data : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');

    ----------------------------------------------------------------------------
    -- Component Declarations
    ----------------------------------------------------------------------------
	-- Axi Responder/Slave Bus Interface S00_AXI
	component engs128_axi_dds_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= C_S00_AXI_DATA_WIDTH;
		C_S_AXI_ADDR_WIDTH	: integer	:= C_S00_AXI_ADDR_WIDTH
		);
		port (
		----------------------------------------------------------------------------
		-- User-defined ports
		left_dds_phase_incr_o  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		right_dds_phase_incr_o  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		----------------------------------------------------------------------------
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component;
	
    ----------------------------------------------------------------------------
    -- DDS controller with sine wave samples stored in BRAM IP
    component dds_controller is
        Generic ( DDS_DATA_WIDTH : integer := DDS_DATA_WIDTH;           -- DDS data width
                DDS_PHASE_DATA_WIDTH : integer := DDS_PHASE_DATA_WIDTH);    -- DDS phase increment data width
        Port ( 
          clk_i         : in std_logic;
          enable_i      : in std_logic;
          reset_i       : in std_logic;
          phase_inc_i   : in std_logic_vector(DDS_PHASE_DATA_WIDTH-1 downto 0);
          
          data_o        : out std_logic_vector(DDS_DATA_WIDTH-1 downto 0)); 
    end component;
    ----------------------------------------------------------------------------

begin

    ----------------------------------------------------------------------------
    -- Component Instantiations
    ----------------------------------------------------------------------------
    -- Axi Bus Interface S00_AXI
    engs128_axi_dds_S00_AXI_inst : engs128_axi_dds_S00_AXI
        generic map (
            C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
            C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
        )
        port map (
            left_dds_phase_incr_o => left_phase_incr_axi_data,
            right_dds_phase_incr_o => right_phase_incr_axi_data,
            S_AXI_ACLK	=> s00_axi_aclk,
            S_AXI_ARESETN	=> s00_axi_aresetn,
            S_AXI_AWADDR	=> s00_axi_awaddr,
            S_AXI_AWPROT	=> s00_axi_awprot,
            S_AXI_AWVALID	=> s00_axi_awvalid,
            S_AXI_AWREADY	=> s00_axi_awready,
            S_AXI_WDATA	=> s00_axi_wdata,
            S_AXI_WSTRB	=> s00_axi_wstrb,
            S_AXI_WVALID	=> s00_axi_wvalid,
            S_AXI_WREADY	=> s00_axi_wready,
            S_AXI_BRESP	=> s00_axi_bresp,
            S_AXI_BVALID	=> s00_axi_bvalid,
            S_AXI_BREADY	=> s00_axi_bready,
            S_AXI_ARADDR	=> s00_axi_araddr,
            S_AXI_ARPROT	=> s00_axi_arprot,
            S_AXI_ARVALID	=> s00_axi_arvalid,
            S_AXI_ARREADY	=> s00_axi_arready,
            S_AXI_RDATA	=> s00_axi_rdata,
            S_AXI_RRESP	=> s00_axi_rresp,
            S_AXI_RVALID	=> s00_axi_rvalid,
            S_AXI_RREADY	=> s00_axi_rready
        );
    
    ---------------------------------------------------------------------------- 
    -- DDS Tone Generators
    ----------------------------------------------------------------------------     
    -- DDS audio tone generator -- left audio
    left_audio_dds : dds_controller 
        port map (
            clk_i => dds_clk_i,
            enable_i => dds_enable_i,
            reset_i => dds_reset_i,
            phase_inc_i => left_dds_phase_incr,
            data_o => left_dds_data_o); 
    
    ----------------------------------------------------------------------------     
    -- DDS audio tone generator -- right audio
    right_audio_dds : dds_controller 
        port map (
            clk_i => dds_clk_i,
            enable_i => dds_enable_i,
            reset_i => dds_reset_i,
            phase_inc_i => right_dds_phase_incr,
            data_o => right_dds_data_o); 
    
                
    ----------------------------------------------------------------------------   
	-- Add user logic here
    ----------------------------------------------------------------------------    
    -- Connect signals to ports
    left_dds_phase_incr <= left_phase_incr_axi_data(DDS_PHASE_DATA_WIDTH-1 downto 0); -- take LSBs
    right_dds_phase_incr <= right_phase_incr_axi_data(DDS_PHASE_DATA_WIDTH-1 downto 0); -- take LSBs
    left_dds_phase_inc_dbg_o <= left_dds_phase_incr; -- debug signal to ILA
    right_dds_phase_inc_dbg_o <= right_dds_phase_incr; -- debug signal to ILA

    ----------------------------------------------------------------------------   

end Behavioral;
