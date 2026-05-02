--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   22:35:59 11/17/2025
-- Design Name:   
-- Module Name:   /home/student1/a2bholat/coe758/VGAController/VGAController_TB.vhd
-- Project Name:  VGAController
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: VGAController
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
USE ieee.std_logic_textio.ALL;
USE std.textio.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY VGAController_TB IS
END VGAController_TB;
 
ARCHITECTURE behavior OF VGAController_TB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT VGAController
    PORT(
         clk : IN  std_logic;
         sw : IN  std_logic_vector(3 downto 0);
         h_sync : OUT  std_logic;
         v_sync : OUT  std_logic;
         R : OUT  std_logic_vector(7 downto 0);
         G : OUT  std_logic_vector(7 downto 0);
         B : OUT  std_logic_vector(7 downto 0);
         DAC_clk : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal sw : std_logic_vector(3 downto 0) := (others => '0');

 	--Outputs
   signal h_sync : std_logic;
   signal v_sync : std_logic;
   signal R : std_logic_vector(7 downto 0);
   signal G : std_logic_vector(7 downto 0);
   signal B : std_logic_vector(7 downto 0);
   signal DAC_clk : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
   constant DAC_clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: VGAController PORT MAP (
          clk => clk,
          sw => sw,
          h_sync => h_sync,
          v_sync => v_sync,
          R => R,
          G => G,
          B => B,
          DAC_clk => DAC_clk
        );

  -- Clock process definitions
	process(clk)
		file file_pointer: text is out "write.txt";
		variable line_el: line;
	begin
		if rising_edge(clk) then
			write(line_el, now);
			write(line_el, ":");
			write(line_el, " ");
			write(line_el, h_sync);
			write(line_el, " ");
			write(line_el, v_sync);
			write(line_el, " ");
			write(line_el, R);
			write(line_el, " ");
			write(line_el, G);
			write(line_el, " ");
			write(line_el, B);
			writeline(file_pointer, line_el);
		end if;
	end process;
	
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 10 ns.
		
      wait for 10 ns;	
		

      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
