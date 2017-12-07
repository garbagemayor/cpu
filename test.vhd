--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   00:12:38 12/08/2017
-- Design Name:   
-- Module Name:   C:/Users/rv/Desktop/cpu/test.vhd
-- Project Name:  tyt_cpu2
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: tyt_cpu2
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY test IS
END test;
 
ARCHITECTURE behavior OF test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT tyt_cpu2
    PORT(
         clk_50m : IN  std_logic;
         clk_single : IN  std_logic;
         rst : IN  std_logic;
         led : OUT  std_logic_vector(15 downto 0);
         data_ram1 : INOUT  std_logic_vector(15 downto 0);
         addr_ram1 : OUT  std_logic_vector(17 downto 0);
         OE_ram1 : OUT  std_logic;
         WE_ram1 : OUT  std_logic;
         EN_ram1 : OUT  std_logic;
         data_ram2 : INOUT  std_logic_vector(15 downto 0);
         addr_ram2 : OUT  std_logic_vector(17 downto 0);
         OE_ram2 : OUT  std_logic;
         WE_ram2 : OUT  std_logic;
         EN_ram2 : OUT  std_logic;
         rdn : OUT  std_logic;
         wrn : OUT  std_logic;
         data_ready : IN  std_logic;
         tbre : IN  std_logic;
         tsre : IN  std_logic;
         digit1 : OUT  std_logic_vector(6 downto 0);
         digit2 : OUT  std_logic_vector(6 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk_50m : std_logic := '0';
   signal clk_single : std_logic := '0';
   signal rst : std_logic := '0';
   signal data_ready : std_logic := '0';
   signal tbre : std_logic := '0';
   signal tsre : std_logic := '0';

	--BiDirs
   signal data_ram1 : std_logic_vector(15 downto 0);
   signal data_ram2 : std_logic_vector(15 downto 0);

 	--Outputs
   signal led : std_logic_vector(15 downto 0);
   signal addr_ram1 : std_logic_vector(17 downto 0);
   signal OE_ram1 : std_logic;
   signal WE_ram1 : std_logic;
   signal EN_ram1 : std_logic;
   signal addr_ram2 : std_logic_vector(17 downto 0);
   signal OE_ram2 : std_logic;
   signal WE_ram2 : std_logic;
   signal EN_ram2 : std_logic;
   signal rdn : std_logic;
   signal wrn : std_logic;
   signal digit1 : std_logic_vector(6 downto 0);
   signal digit2 : std_logic_vector(6 downto 0);

   -- Clock period definitions
   constant clk_50m_period : time := 10 ns;
   constant clk_single_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: tyt_cpu2 PORT MAP (
          clk_50m => clk_50m,
          clk_single => clk_single,
          rst => rst,
          led => led,
          data_ram1 => data_ram1,
          addr_ram1 => addr_ram1,
          OE_ram1 => OE_ram1,
          WE_ram1 => WE_ram1,
          EN_ram1 => EN_ram1,
          data_ram2 => data_ram2,
          addr_ram2 => addr_ram2,
          OE_ram2 => OE_ram2,
          WE_ram2 => WE_ram2,
          EN_ram2 => EN_ram2,
          rdn => rdn,
          wrn => wrn,
          data_ready => data_ready,
          tbre => tbre,
          tsre => tsre,
          digit1 => digit1,
          digit2 => digit2
        );

   -- Clock process definitions
   clk_50m_process :process
   begin
		clk_50m <= '0';
		wait for clk_50m_period/2;
		clk_50m <= '1';
		wait for clk_50m_period/2;
   end process;
 
   clk_single_process :process
   begin
		clk_single <= '0';
		wait for clk_single_period/2;
		clk_single <= '1';
		wait for clk_single_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_50m_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
