----------------------------------------------------------------------------
--  Lab 2: AXI Stream FIFO and DMA
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
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
entity axis_fir_wrapper is
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
		ch_select_i : in std_logic_vector(2 downto 0);

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
end axis_fir_wrapper;
----------------------------------------------------------------------------
architecture Behavioral of axis_fir_wrapper is
----------------------------------------------------------------------------
-- Define Constants and Signals
----------------------------------------------------------------------------
constant AC_DATA_WIDTH : integer := 24; 
constant DDS_PHASE_WIDTH : integer := 15;      

signal lrclk_s           : std_logic := '0';
signal s_axis_aclk_s      : std_logic := '0';

signal right_audio_data_valid_o_s : std_logic := '0';
signal left_audio_data_valid_o_s : std_logic := '0';

signal right_audio_data_o : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal left_audio_data_o : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');

signal left_audio_data_tx_i_0 : std_logic := '0';
signal right_audio_data_tx_i_0 : std_logic := '0';

signal m00_axis_tstrb_s : std_logic_vector((M_AXI_DATA_WIDTH/8)-1 downto 0) := (others => '1');
signal m00_axis_tlast_s : std_logic := '0';
signal s00_axis_tstrb_s : std_logic_vector((S_AXI_DATA_WIDTH/8)-1 downto 0) := (others => '1');
signal s00_axis_tlast_s : std_logic := '0';

signal s_axis_data_tready_s : std_logic := '1';


--data signals
signal lpf_fir_data_left_s : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal hpf_fir_data_left_s : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal bpf_fir_data_left_s : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal bsf_fir_data_left_s : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal lpf_fir_data_right_s : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal hpf_fir_data_right_s : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal bpf_fir_data_right_s : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal bsf_fir_data_right_s : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');

--valid signals
signal lpf_fir_left_valid_s : std_logic := '0';
signal hpf_fir_left_valid_s : std_logic := '0';
signal bpf_fir_left_valid_s : std_logic := '0';
signal bsf_fir_left_valid_s : std_logic := '0';
signal lpf_fir_right_valid_s : std_logic := '0';
signal hpf_fir_right_valid_s : std_logic := '0';
signal bpf_fir_right_valid_s : std_logic := '0';
signal bsf_fir_right_valid_s : std_logic := '0';


signal left_audio_data_tx_s : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal right_audio_data_tx_s : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal left_audio_data_s : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal right_audio_data_s : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal ac_mute_n_s : std_logic := '0';
signal ac_mute_n_reg_s : std_logic := '0';
signal left_audio_data_tx : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal right_audio_data_tx : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal left_audio_data_rx_s : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');
signal right_audio_data_rx_s : std_logic_vector(AC_DATA_WIDTH-1 downto 0) := (others => '0');

----------------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------------

---------------------------------------------------------------------------- 
-- LPF FIR 
COMPONENT fir_compiler_lpf
  PORT (
    aclk                 : IN  STD_LOGIC;
    s_axis_data_tvalid  : IN  STD_LOGIC;
    s_axis_data_tready  : OUT STD_LOGIC;
    s_axis_data_tdata   : IN  STD_LOGIC_VECTOR(23 DOWNTO 0);
    m_axis_data_tvalid  : OUT STD_LOGIC;
    m_axis_data_tready  : IN  STD_LOGIC;
    m_axis_data_tdata   : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
  );
END COMPONENT;
---------------------------------------------------------------------------- 
-- HPF FIR 
COMPONENT fir_compiler_hpf
  PORT (
    aclk                 : IN  STD_LOGIC;
    s_axis_data_tvalid  : IN  STD_LOGIC;
    s_axis_data_tready  : OUT STD_LOGIC;
    s_axis_data_tdata   : IN  STD_LOGIC_VECTOR(23 DOWNTO 0);
    m_axis_data_tvalid  : OUT STD_LOGIC;
    m_axis_data_tready  : IN  STD_LOGIC;
    m_axis_data_tdata   : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
  );
END COMPONENT;
---------------------------------------------------------------------------- 
-- BPF FIR 
COMPONENT fir_compiler_bpf
  PORT (
    aclk                 : IN  STD_LOGIC;
    s_axis_data_tvalid  : IN  STD_LOGIC;
    s_axis_data_tready  : OUT STD_LOGIC;
    s_axis_data_tdata   : IN  STD_LOGIC_VECTOR(23 DOWNTO 0);
    m_axis_data_tvalid  : OUT STD_LOGIC;
    m_axis_data_tready  : IN  STD_LOGIC;
    m_axis_data_tdata   : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
  );
END COMPONENT;
---------------------------------------------------------------------------- 
-- BSF FIR 
COMPONENT fir_compiler_bsf
  PORT (
    aclk                 : IN  STD_LOGIC;
    s_axis_data_tvalid  : IN  STD_LOGIC;
    s_axis_data_tready  : OUT STD_LOGIC;
    s_axis_data_tdata   : IN  STD_LOGIC_VECTOR(23 DOWNTO 0);
    m_axis_data_tvalid  : OUT STD_LOGIC;
    m_axis_data_tready  : IN  STD_LOGIC;
    m_axis_data_tdata   : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
  );
END COMPONENT;
	
---------------------------------------------------------------------------- 
-- AXI stream transmitter
component axis_transmitter_interface is
	generic (
		DATA_WIDTH	: integer	:= 32;
		AC_DATA_WIDTH : integer := 24
	);
	port (
	   lrclk_i : in std_logic;
	   left_audio_data_i : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
	   right_audio_data_i : in std_logic_vector(AC_DATA_WIDTH-1 downto 0);
	   

		-- Ports of Axi Controller Bus Interface M00_AXIS
		m00_axis_aclk     : in std_logic;
		m00_axis_aresetn  : in std_logic;
		m00_axis_tvalid   : out std_logic;
		m00_axis_tdata    : out std_logic_vector(DATA_WIDTH-1 downto 0);
		m00_axis_tstrb    : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast    : out std_logic;
		m00_axis_tready   : in std_logic
	);
end component axis_transmitter_interface;

---------------------------------------------------------------------------- 
-- AXI stream receiver 
component axis_receiver_interface is
	generic (
		DATA_WIDTH	: integer	:= 32;
		AC_DATA_WIDTH : integer := 24
	);
	port (
	   lrclk_i : in std_logic;
	   left_audio_data_o : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
	   right_audio_data_o : out std_logic_vector(AC_DATA_WIDTH-1 downto 0);
	  left_audio_data_valid_o : out std_logic;
	   right_audio_data_valid_o : out std_logic;

		-- Ports of Axi Responder Bus Interface S00_AXIS
		s00_axis_aclk     : in std_logic;
		s00_axis_aresetn  : in std_logic;
		s00_axis_tready   : out std_logic;
		s00_axis_tdata	  : in std_logic_vector(DATA_WIDTH-1 downto 0);
		s00_axis_tstrb    : in std_logic_vector((DATA_WIDTH/8)-1 downto 0);
		s00_axis_tlast    : in std_logic;
		s00_axis_tvalid   : in std_logic
	);
end component axis_receiver_interface;

----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Component instantiations
----------------------------------------------------------------------------    

---------------------------------------------------------------------------- 
-- AXI stream transmitter
axis_transmitter : axis_transmitter_interface
    generic map (
        DATA_WIDTH => C_AXI_STREAM_DATA_WIDTH,
        AC_DATA_WIDTH => 24
    )
    port map (
        left_audio_data_i => left_audio_data_s,
        right_audio_data_i => right_audio_data_s,
        lrclk_i => lrclk_i,
        m00_axis_aclk => m_axis_aclk,
        m00_axis_aresetn => aresetn_i,
        m00_axis_tvalid => m_axis_tvalid,
        m00_axis_tdata => m_axis_tdata,
        m00_axis_tstrb => m00_axis_tstrb_s,
        m00_axis_tlast => m00_axis_tlast_s,
        m00_axis_tready => m_axis_tready
    );
    

---------------------------------------------------------------------------- 
-- AXI stream receiver
axis_receiver : axis_receiver_interface
    generic map (
        DATA_WIDTH => C_AXI_STREAM_DATA_WIDTH,
        AC_DATA_WIDTH => 24
    )
    port map (
        lrclk_i => lrclk_i,
        left_audio_data_o => left_audio_data_rx_s,
        right_audio_data_o => right_audio_data_rx_s,
        left_audio_data_valid_o => left_audio_data_valid_o_s,
        right_audio_data_valid_o => right_audio_data_valid_o_s,
        s00_axis_aclk => s_axis_aclk,
        s00_axis_aresetn => aresetn_i,
        s00_axis_tready => s_axis_tready,
        s00_axis_tdata => s_axis_tdata,
        s00_axis_tstrb => s00_axis_tstrb_s,
        s00_axis_tlast => s00_axis_tlast_s,
        s00_axis_tvalid => s_axis_tvalid
    );

------------------------------------------------------------------------------ 
---- LPF FIR 
lowpass_fir_filter_left :  fir_compiler_lpf
  port map (
    aclk                 => s_axis_aclk,
    s_axis_data_tvalid  => left_audio_data_valid_o_s,
    s_axis_data_tready  => s_axis_data_tready_s,
    s_axis_data_tdata   => left_audio_data_rx_s,
    m_axis_data_tvalid  => lpf_fir_left_valid_s,
    m_axis_data_tready  => m_axis_tready,
    m_axis_data_tdata  => lpf_fir_data_left_s
  );
---------------------------------------------------------------------------- 
-- HPF FIR 
highpass_fir_filter_left : fir_compiler_hpf
  port map (
    aclk                => s_axis_aclk,
    s_axis_data_tvalid  => left_audio_data_valid_o_s,
    s_axis_data_tready  => s_axis_data_tready_s,
    s_axis_data_tdata   => left_audio_data_rx_s,
    m_axis_data_tvalid => hpf_fir_left_valid_s,
    m_axis_data_tready => m_axis_tready,
    m_axis_data_tdata  => hpf_fir_data_left_s
  );

---------------------------------------------------------------------------- 
-- BPF FIR 
bandpass_fir_filter_left : fir_compiler_bpf
  port map (
    aclk                => s_axis_aclk,
    s_axis_data_tvalid => left_audio_data_valid_o_s,
    s_axis_data_tready  => s_axis_data_tready_s,
    s_axis_data_tdata  => left_audio_data_rx_s,
    m_axis_data_tvalid => bpf_fir_left_valid_s,
    m_axis_data_tready  => m_axis_tready,
    m_axis_data_tdata  => bpf_fir_data_left_s
  );

---------------------------------------------------------------------------- 
-- BSF FIR 
bandstop_fir_filter_left : fir_compiler_bsf
  port map (
    aclk                => s_axis_aclk,
    s_axis_data_tvalid  => left_audio_data_valid_o_s,
    s_axis_data_tready  => s_axis_data_tready_s,
    s_axis_data_tdata   => left_audio_data_rx_s,
    m_axis_data_tvalid  => bsf_fir_left_valid_s,
    m_axis_data_tready  => m_axis_tready,
    m_axis_data_tdata   => bsf_fir_data_left_s
  );
  
---------------------------------------------------------------------------- 
-- LPF FIR 
lowpass_fir_filter_right :  fir_compiler_lpf
  port map (
    aclk                 => s_axis_aclk,
    s_axis_data_tvalid  => right_audio_data_valid_o_s,
    s_axis_data_tready  => s_axis_data_tready_s,
    s_axis_data_tdata   => right_audio_data_rx_s,
    m_axis_data_tvalid  => lpf_fir_right_valid_s,
    m_axis_data_tready  => m_axis_tready,
    m_axis_data_tdata  => lpf_fir_data_right_s
  );
---------------------------------------------------------------------------- 
-- HPF FIR 
highpass_fir_filter_right : fir_compiler_hpf
  port map (
    aclk                => s_axis_aclk,
    s_axis_data_tvalid  => right_audio_data_valid_o_s,
    s_axis_data_tready  => s_axis_data_tready_s,
    s_axis_data_tdata   => right_audio_data_rx_s,
    m_axis_data_tvalid => hpf_fir_right_valid_s,
    m_axis_data_tready => m_axis_tready,
    m_axis_data_tdata  => hpf_fir_data_right_s
  );

---------------------------------------------------------------------------- 
-- BPF FIR 
bandpass_fir_filter_right : fir_compiler_bpf
  port map (
    aclk                => s_axis_aclk,
    s_axis_data_tvalid =>  right_audio_data_valid_o_s,
    s_axis_data_tready  => s_axis_data_tready_s,
    s_axis_data_tdata  => right_audio_data_rx_s,
    m_axis_data_tvalid => bpf_fir_right_valid_s,
    m_axis_data_tready  => m_axis_tready,
    m_axis_data_tdata  => bpf_fir_data_right_s
  );

---------------------------------------------------------------------------- 
-- BSF FIR 
bandstop_fir_filter_right : fir_compiler_bsf
  port map (
    aclk                => s_axis_aclk,
    s_axis_data_tvalid  => right_audio_data_valid_o_s,
    s_axis_data_tready  => s_axis_data_tready_s,
    s_axis_data_tdata   => right_audio_data_rx_s,
    m_axis_data_tvalid  => bsf_fir_right_valid_s,
    m_axis_data_tready  => m_axis_tready,
    m_axis_data_tdata   => bsf_fir_data_right_s
  );

	

---------------------------------------------------------------------------- 
-- Logic
---------------------------------------------------------------------------- 
left_data_mux : process(ch_select_i, lpf_fir_data_left_s, hpf_fir_data_left_s, bpf_fir_data_left_s, bsf_fir_data_left_s)
begin
    case ch_select_i is 
        when "00" => left_audio_data_tx_s <= lpf_fir_data_left_s;
        when "01" => left_audio_data_tx_s <= hpf_fir_data_left_s; 
        when "10" => left_audio_data_tx_s <= bpf_fir_data_left_s;
        when "11" => left_audio_data_tx_s <= bsf_fir_data_left_s;
        when others => left_audio_data_tx_s <= lpf_fir_data_left_s;
    end case;
end process;

right_data_mux : process(ch_select_i, lpf_fir_data_right_s, hpf_fir_data_right_s, bpf_fir_data_right_s, bsf_fir_data_right_s)
begin
    case ch_select_i is 
        when "00" => right_audio_data_tx_s <= lpf_fir_data_right_s;
        when "01" => right_audio_data_tx_s <= hpf_fir_data_right_s; 
        when "10" => right_audio_data_tx_s <= bpf_fir_data_right_s;
        when "11" => right_audio_data_tx_s <= bsf_fir_data_right_s;
        when others => right_audio_data_tx_s <= lpf_fir_data_right_s;
    end case;
end process;

left_valid_mux : process(ch_select_i, lpf_fir_left_valid_s, hpf_fir_left_valid_s, bpf_fir_left_valid_s, bsf_fir_left_valid_s)
begin
    case ch_select_i is 
        when "00" => left_audio_data_tx_i_0 <= lpf_fir_left_valid_s;
        when "01" => left_audio_data_tx_i_0 <= hpf_fir_left_valid_s; 
        when "10" => left_audio_data_tx_i_0 <= bpf_fir_left_valid_s;
        when "11" => left_audio_data_tx_i_0 <= bsf_fir_left_valid_s;
        when others => left_audio_data_tx_i_0 <= lpf_fir_left_valid_s;
    end case;
end process;

right_valid_mux : process(ch_select_i, lpf_fir_right_valid_s, hpf_fir_right_valid_s, bpf_fir_right_valid_s, bsf_fir_right_valid_s)
begin
    case ch_select_i is 
        when "00" => right_audio_data_tx_i_0 <= lpf_fir_right_valid_s;
        when "01" => right_audio_data_tx_i_0 <= hpf_fir_right_valid_s; 
        when "10" => right_audio_data_tx_i_0 <= bpf_fir_right_valid_s;
        when "11" => right_audio_data_tx_i_0 <= bsf_fir_right_valid_s;
        when others => right_audio_data_tx_i_0 <= lpf_fir_right_valid_s;
    end case;
end process;

--filter_select : process(ch_select_i)
--begin 
--if (ch_select_i = "00") then
--    left_audio_data_tx_s <= lpf_fir_data_left_s;
--    right_audio_data_tx_s <= lpf_fir_data_right_s;
--    left_audio_data_tx_i_0 <= lpf_fir_left_valid_s;
--    right_audio_data_tx_i_0 <= lpf_fir_right_valid_s;
--elsif (ch_select_i = "01") then
--    left_audio_data_tx_s <= hpf_fir_data_left_s;
--    right_audio_data_tx_s <= hpf_fir_data_right_s;
--    left_audio_data_tx_i_0 <= hpf_fir_left_valid_s;
--    right_audio_data_tx_i_0 <= hpf_fir_right_valid_s;
--elsif (ch_select_i = "10") then
--    left_audio_data_tx_s <= bpf_fir_data_left_s;
--    right_audio_data_tx_s <= bpf_fir_data_right_s;
--    left_audio_data_tx_i_0 <= bpf_fir_left_valid_s;
--    right_audio_data_tx_i_0 <= bpf_fir_right_valid_s;
--elsif (ch_select_i = "11") then
--    left_audio_data_o <= bsf_fir_data_left_s;
--    right_audio_data_tx_s <= bsf_fir_data_right_s;
--    left_audio_data_tx_i_0 <= bsf_fir_left_valid_s;
--    right_audio_data_tx_i_0 <= bsf_fir_right_valid_s;
--else 
--    left_audio_data_tx_s <= lpf_fir_data_left_s;
--    right_audio_data_tx_s <= lpf_fir_data_right_s;
--    left_audio_data_tx_i_0 <= lpf_fir_left_valid_s;
--    right_audio_data_tx_i_0 <= lpf_fir_right_valid_s;
--end if; 
--end process;

clk_proc : process(m_axis_aclk)
begin
if rising_edge(m_axis_aclk) then
    if (left_audio_data_tx_i_0 = '1') then
        left_audio_data_s <= left_audio_data_tx_s;
    end if;
    
    if (right_audio_data_tx_i_0 = '1') then
        right_audio_data_s <= right_audio_data_tx_s;
    end if;
    
end if;

end process;




----------------------------------------------------------------------------


end Behavioral;