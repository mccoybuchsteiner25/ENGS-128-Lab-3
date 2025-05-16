----------------------------------------------------------------------------
--  Week 3 - AXI Lite Activity
----------------------------------------------------------------------------
--  ENGS 128 Spring 2025
--	Author: Kendall Farnham
----------------------------------------------------------------------------
-- Description: testbench for AXI4-LITE interface
--              modified from https://github.com/frobino/axi_custom_ip_tb/tree/master
----------------------------------------------------------------------------
-- Add libraries 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_S00_AXI is
end tb_S00_AXI;
----------------------------------------------------------------------------------
architecture testbench of tb_S00_AXI is
----------------------------------------------------------------------------------
-- Define constants 
constant CLOCK_PERIOD: time := 8ns; 	-- define clock period, 8ns = 125 MHz
constant REG_DATA_WIDTH : integer := 4;
constant C_S00_AXI_DATA_WIDTH : integer := 32;
constant C_S00_AXI_ADDR_WIDTH : integer := 6;

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
-- Testbench signals
signal enable_send, enable_read : std_logic;
signal axi_data_out : std_logic_vector(REG_DATA_WIDTH-1 downto 0);
signal axi_data_write : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
signal data_select : std_logic_vector(C_S00_AXI_ADDR_WIDTH-3 downto 0);
signal axi_reg : integer := 0;

----------------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------------


----------------------------------------------------------------------------------
-- AXI IP
component engs128_axi_demo is
    generic (
	    ----------------------------------------------------------------------------
		-- Users to add parameters here
        REG_OUTPUT_DATA_WIDTH : integer := 4;   -- output data width
        ----------------------------------------------------------------------------

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Parameters of Axi Responder Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= C_S00_AXI_DATA_WIDTH;
		C_S00_AXI_ADDR_WIDTH	: integer	:= C_S00_AXI_ADDR_WIDTH
	);
	port (
	    ----------------------------------------------------------------------------
		-- Users to add ports here
		reg_select_i  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-3 downto 0);
		data_o  : out std_logic_vector(REG_OUTPUT_DATA_WIDTH-1 downto 0);
		----------------------------------------------------------------------------
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Ports of Axi Responder Bus Interface S00_AXI
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
-- Procedures for driving the AXI bus
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
 
 
----------------------------------------------------------------------------
begin
----------------------------------------------------------------------------
-- Instantiate DUT
dut: engs128_axi_demo
port map (
      reg_select_i => data_select,
      data_o => axi_data_out,
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
      s00_axi_rready  => S_AXI_RREADY);


----------------------------------------------------------------------------
-- Generate the AXI clock 
clock_gen_process : process
begin
	S_AXI_ACLK <= '0';				-- start low
	wait for CLOCK_PERIOD/2;		-- wait for half a clock period
	loop							-- toggle, and loop
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
    
    wait for 15 ns;
    S_AXI_ARESETN <= '1';
    
    wait until rising_edge(S_AXI_ACLK);
    wait for CLOCK_PERIOD;
    
    
    -- write data to register 0
    axi_reg <= 0;
    axi_data_write <= std_logic_vector(to_unsigned(3,axi_data_write'LENGTH));
    wait for 100 ns;
    master_write_axi_reg(S_AXI_AWADDR, S_AXI_WDATA, S_AXI_WSTRB, enable_send, axi_reg, axi_data_write, S_AXI_BVALID);
    wait for 100 ns;
    
    
    -- read data written to register 0
    master_read_axi_reg(S_AXI_ARADDR, enable_read, axi_reg, S_AXI_RVALID);
    wait for 100 ns;
    
    -- write data to register 1
    axi_reg <= 1;
    axi_data_write <= std_logic_vector(to_unsigned(1,axi_data_write'LENGTH));
    wait for 100 ns;
    master_write_axi_reg(S_AXI_AWADDR, S_AXI_WDATA, S_AXI_WSTRB, enable_send, axi_reg, axi_data_write, S_AXI_BVALID);
    wait for 100 ns;
    
    -- read data written to register 1
    master_read_axi_reg(S_AXI_ARADDR, enable_read, axi_reg, S_AXI_RVALID);
    wait for 100 ns;
    
    -- write data to register 8
    axi_reg <= 8;
    axi_data_write <= std_logic_vector(to_unsigned(2,axi_data_write'LENGTH));
    wait for 100 ns;
    master_write_axi_reg(S_AXI_AWADDR, S_AXI_WDATA, S_AXI_WSTRB, enable_send, axi_reg, axi_data_write, S_AXI_BVALID);
    wait for 100 ns;
    
    -- read data written to register 8
    master_read_axi_reg(S_AXI_ARADDR, enable_read, axi_reg, S_AXI_RVALID);
    wait for 100 ns;
    
    -- cycle through select bits
    data_select <= std_logic_vector(to_unsigned(1,data_select'LENGTH));
    wait for 100 ns;
    data_select <= std_logic_vector(to_unsigned(2,data_select'LENGTH));
    wait for 100 ns;
    
        
    -- write data to register 15
    data_select <= (others => '1');
    axi_reg <= 15;
    axi_data_write <= std_logic_vector(to_unsigned(4,axi_data_write'LENGTH));
    wait for 100 ns;
    master_write_axi_reg(S_AXI_AWADDR, S_AXI_WDATA, S_AXI_WSTRB, enable_send, axi_reg, axi_data_write, S_AXI_BVALID);
    wait for 100 ns;
    
    -- read data written to register 15
    master_read_axi_reg(S_AXI_ARADDR, enable_read, axi_reg, S_AXI_RVALID);
    wait for 100 ns;
    
        
    std.env.stop;
 END PROCESS stimulus;
end testbench;
