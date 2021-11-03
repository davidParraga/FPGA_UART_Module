--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:56:01 07/07/2019
-- Design Name:   
-- Module Name:   C:/Users/david/Desktop/88/UART/Prueba_transmisor.vhd
-- Project Name:  UART
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: UART
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
 
ENTITY Prueba_transmisor IS
END Prueba_transmisor;
 
ARCHITECTURE behavior OF Prueba_transmisor IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT UART
    PORT(
         CLK : IN  std_logic;
         RESET : IN  std_logic;
         TX_DATA : IN  std_logic_vector(7 downto 0);
         BTN_IN : IN  std_logic;
         TX_OUT : OUT  std_logic;
         TX_READY : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal RESET : std_logic := '0';
   signal TX_DATA : std_logic_vector(7 downto 0) := (others => '0');
   signal BTN_IN : std_logic := '0';

 	--Outputs
   signal TX_OUT : std_logic;
   signal TX_READY : std_logic;

   -- Clock period definitions
   constant CLK_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: UART PORT MAP (
          CLK => CLK,
          RESET => RESET,
          TX_DATA => TX_DATA,
          BTN_IN => BTN_IN,
          TX_OUT => TX_OUT,
          TX_READY => TX_READY
        );

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for CLK_period*10;

      -- insert stimulus here 
			
			reset <= '1';
			wait for 100 us;

			reset <= '0';
			TX_DATA <= "10000011";
			BTN_IN <= '1';
			
		
			
			
      wait;
   end process;
			

END;
