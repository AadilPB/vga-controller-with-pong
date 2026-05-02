----------------------------------------------------------------------------------
-- 
--
--Author:			 Aadil Bholat
-- Create Date:    15:18:47 11/12/2025 
-- Design Name: 	 VGAController
-- Module Name:    VGAController - Behavioral 
-- Project Name: 	 VGAController
-- Target Devices: Spartan3E XC3S500E, 60 Hz 640 x 480 pixel Monitors
--
-- Description: Implements a VGA Controller that can display graphics onto a 60 Hz, 
--					 640 x 480 pixel monitor. Also implements a video game processors 
--					 that creates a game of Pong. 
--
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;


entity VGAController is
    Port ( clk : in  STD_LOGIC;
           sw : in  STD_LOGIC_VECTOR (3 downto 0);
           h_sync : out  STD_LOGIC;
           v_sync : out  STD_LOGIC;
           R : out  STD_LOGIC_VECTOR (7 downto 0);
           G : out  STD_LOGIC_VECTOR (7 downto 0);
           B : out  STD_LOGIC_VECTOR (7 downto 0);
			  DAC_clk : out STD_LOGIC						-- Pixel clock output to VGA DAC 
			  ); 
end VGAController;


architecture Behavioral of VGAController is
	
	-- Chipscope components and signals
	component icon
	PORT (
		CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0)
		);
	end component;
	
	component ila
	PORT (
		CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
		CLK : IN STD_LOGIC;
		DATA : IN STD_LOGIC_VECTOR(22 DOWNTO 0);
		TRIG0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0));
	end component;
	
	signal control0 : STD_LOGIC_VECTOR(35 DOWNTO 0);
	signal ila_data : STD_LOGIC_VECTOR(22 DOWNTO 0);
	signal trig0 : STD_LOGIC_VECTOR(7 downto 0);
	signal ila_clk : std_logic := '0';
	signal clk_div : unsigned(15 downto 0) := (others => '0');
	constant div : unsigned(15 downto 0) := to_unsigned (499, 16);
	
	-----------------------------------------------
	
	-- VGA Controller Signals and Constants
	
	-- Pixel Clock Signal
	signal pxl_clk : std_logic := '0';
	
	-- Horizontal(per line) Timing Parameters(800 with 640 display)
	constant HAD : integer := 639; -- Horizontal Active Display
	constant HFP : integer := 16;  -- Horizontal Front Porch
	constant HSP : integer := 96;  -- Horizontal Sync Pulse
	constant HBP : integer := 48;  -- Horizontal Back Porch
	
	-- Vertical(per frame) Timing Parameters(525 with 480 display)
	constant VAD : integer := 479; -- Vertical Active Display
	constant VFP : integer := 10;  -- Vertical Front Porch
	constant VSP : integer := 2;   -- Vertical Sync Pulse
	constant VBP : integer := 33;  -- Vertical Back Porch
	
	-- Display location signals for line by line updates
	signal h_pos : integer := 0;
	signal v_pos : integer := 0;
	signal h_pos_probe : STD_LOGIC_VECTOR(9 downto 0);
	signal v_pos_probe : STD_LOGIC_VECTOR(9 downto 0); 
	
	
	-- Signal checking if video is on
	signal video_on : std_logic := '0';
	
	-----------------------------------------------
	
	-- Pong Signals and Constants
	
	-- Pong Inner Border Parameters (used in Paddle and Ball Logic alongside drawing borders)
	constant top_inner : integer := 29;
	constant bottom_inner : integer := 449;
	constant left_inner : integer := 29;
	constant right_inner : integer := 609;
	
	-- Pong Outer Border Parameters (only used for drawing borders)
	constant top_outer : integer := 9;
	constant bottom_outer : integer := 469;
	constant left_outer : integer := 9;
	constant right_outer : integer := 629;
	
	--Goal Border Parameters (determines the size of the net)
	constant net_top : integer := 129;
	constant net_bottom : integer := 351;
	
	--Paddle Parameters
	constant paddle_width : integer := 10;
	constant left_paddle_net : integer := left_inner + 10;
	constant left_paddle_field : integer := left_paddle_net + paddle_width;
	constant right_paddle_net : integer := right_inner - 10;
	constant right_paddle_field : integer := right_paddle_net - paddle_width; 
	constant paddle_height : integer := 80;
	constant paddle_up : integer := 35;       -- Paddle deflects ball upward
	constant paddle_straight : integer := 45; -- Paddle deflects ball straight
	constant paddle_down : integer := 80;     -- Paddle deflects ball downward
	signal paddle1_top : integer := 199;
	signal paddle2_top : integer := 199;
	
	--Input Delay Parameters
	signal input_tick : std_logic := '0';
	signal input_counter : integer range 0 to 416666 := 0; -- 25 MHz / 60 Hz = 416667
	
	--Ball Parameters
	constant ball_length : integer := 10;
	signal ball_h : integer := 314;
	signal ball_v : integer := 234;
	signal ball_dx : integer := 1;
	signal ball_dy : integer := 1;
	signal ball_mid : integer := ball_v + (ball_length/2);
	signal ball_state : std_logic := '0'; -- Tracks if ball is in play or not
	signal ball_R : std_logic_vector(7 downto 0) := "11111111";
	signal ball_G : std_logic_vector(7 downto 0) := (others => '0');
	signal ball_B : std_logic_vector(7 downto 0) := (others => '0'); 
	
	--Ball Delay Parameters 
	signal ball_tick : std_logic := '0';
	signal ball_counter : integer range 0 to 416666 := 0;
	
	--Collision checks
	signal top_border : STD_LOGIC := '0';
	signal bottom_border : STD_LOGIC := '0';
	signal left_border : STD_LOGIC := '0';
	signal right_border : STD_LOGIC := '0';
	signal left_paddle : STD_LOGIC := '0';
	signal right_paddle : STD_LOGIC := '0';
	
	--Internal signals
	signal h_sync_sig : STD_LOGIC := '0';
	signal v_sync_sig : STD_LOGIC := '0';
	signal R_sig : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal B_sig : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal G_sig : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	
   -----------------------------------------------
	
begin
	h_pos_probe <= std_logic_vector(to_unsigned(h_pos, h_pos_probe'length));
	v_pos_probe <= std_logic_vector(to_unsigned(v_pos, v_pos_probe'length));

	-- Chipscope components
	sys_icon : icon
	  port map (
		 CONTROL0 => control0
		 );

	sys_ila : ila
		port map(
			CONTROL => control0,
			CLK => ila_clk,
			DATA => ila_data,
			TRIG0 => trig0
			);

	-- Clock Divider
	process(clk)
	begin
		if rising_edge(clk)  then
			pxl_clk <= not pxl_clk; 
		end if;

	end process;

	--ILA Clock Divider(40 microseconds per sample)
	process(pxl_clk)
	begin
		if rising_edge(pxl_clk) then
			if clk_div = div then
				ila_clk <= not ila_clk;
			else 
				clk_div <= clk_div + 1;
			end if;
		end if;
	end process;
			

	-- Horizontal Position Counter
	process(pxl_clk)
	begin
		if rising_edge(pxl_clk)  then
			if(h_pos = HAD + HFP + HSP + HBP) then
				h_pos <= 0;
				
			else
				h_pos <= h_pos + 1;
			end if;
		end if;
	end process;

	-- Vertical Position Counter
	process(pxl_clk, h_pos)
	begin
		if rising_edge(pxl_clk)  then
			if(h_pos = HAD + HFP + HSP + HBP) then
				if(v_pos = VAD + VFP + VSP + VBP) then
					v_pos <= 0;
				else
					v_pos <= v_pos + 1;
				end if;
			end if;
		end if;
	end process;

	-- Horizontal Synchronization 
	process(pxl_clk, h_pos)
	begin
		if rising_edge(pxl_clk) then
			if(h_pos <= (HAD + HFP) OR (h_pos > HAD + HFP + HSP)) then
				h_sync_sig <= '1';
			else
				h_sync_sig <= '0';
			end if;
		end if;
	end process;

	-- Vertical Synchronization
	process(pxl_clk, v_pos)
	begin
		if rising_edge(pxl_clk) then
			if(v_pos <= (VAD + VFP) OR (v_pos > VAD + VFP + VSP)) then
				v_sync_sig <= '1';
			else
				v_sync_sig <= '0';
			end if;
		end if;
	end process;

	-- Video On
	process(pxl_clk, h_pos, v_pos)
	begin
		if rising_edge(pxl_clk) then
			if(h_pos <= HAD and v_pos <= VAD) then
				video_on <= '1';
			else
				video_on <= '0'; 
			end if;
		end if;
	end process;

	-- Draw Static Display
	process(pxl_clk, h_pos, v_pos)
	begin
		if rising_edge(pxl_clk) then
			if(video_on = '1') then
				-- Draw ball
				if (h_pos >= ball_h and h_pos <= ball_h + ball_length) AND (v_pos >= ball_v and v_pos <= ball_v + ball_length) then
					R_sig <= ball_R;
					G_sig <= ball_G;
					B_sig <= ball_B;
					
				-- Draw paddles
				elsif (h_pos >= left_paddle_net and h_pos <= left_paddle_field) AND (v_pos >= paddle1_top and v_pos <= paddle1_top + paddle_height) then
					R_sig <= x"80";
					G_sig <= x"00";
					B_sig <= x"80";
				elsif (h_pos >= right_paddle_field and h_pos <= right_paddle_net) AND (v_pos >= paddle2_top and v_pos <= paddle2_top + paddle_height) then
					R_sig <= x"CC";
					G_sig <= x"99";
					B_sig <= x"00";
					
				-- Top and Bottom Borders
				elsif(h_pos >= left_outer and h_pos <= right_outer) AND (v_pos >= top_outer and v_pos <= top_inner) then
					R_sig <= "01010000";
					G_sig <= "00000000";
					B_sig <= "00000000";
				elsif (h_pos >= left_outer and h_pos <= right_outer) AND (v_pos >= bottom_inner and v_pos <= bottom_outer) then
					R_sig <= "01010000";
					G_sig <= "00000000";
					B_sig <= "00000000";
					
				-- Left Borders
				elsif (h_pos >= left_outer and h_pos <= left_inner) AND (v_pos >= top_inner and v_pos <= net_top) then
					R_sig <= "01010000";
					G_sig <= "00000000";
					B_sig <= "00000000";
				elsif (h_pos >= left_outer and h_pos <= left_inner) AND (v_pos >= net_bottom and v_pos <= bottom_inner) then
					R_sig <= "01010000";
					G_sig <= "00000000";
					B_sig <= "00000000";
					
				-- Right Borders
				elsif (h_pos >= right_inner and h_pos <= right_outer) AND (v_pos >= top_inner and v_pos <= net_top) then
					R_sig <= "01010000";
					G_sig <= "00000000";
					B_sig <= "00000000";
				elsif (h_pos >= right_inner and h_pos <= right_outer) AND (v_pos >= net_bottom and v_pos <= bottom_inner) then
					R_sig <= "01010000";
					G_sig <= "00000000";
					B_sig <= "00000000";
					
				-- Centre Line
				elsif h_pos >= 314 and h_pos <= 324 then
					if v_pos >= top_inner and v_pos <= bottom_inner then
						if ((v_pos - top_inner) mod (16)) < 8 then -- Alternating 8px dash pattern
							R_sig <= "10000100";
							G_sig <= "00000000";
							B_sig <= "00000000";
						else
							R_sig <= x"20";
							G_sig <= x"20";
							B_sig <= x"20";
						end if;
					end if;
				
				-- Background
				else
					R_sig <= x"20";
					G_sig <= x"20";
					B_sig <= x"20";
				end if;
			else
				R_sig <= "00000000";
				G_sig <= "00000000";
				B_sig <= "00000000";
			end if;
		end if;
	end process;


	-- Paddle Movement 
	process(pxl_clk)
	begin
		if rising_edge(pxl_clk) then
			-- Input Delay Frame Tick
			-- 25 Mhz/ 60 hz = 416 666 cycles
			-- The above is the rate of each frame
			if input_counter = 416666 then
				input_counter <= 0;
				input_tick <= '1'; 
			else 
				input_counter <= input_counter+1;
				input_tick <= '0';
			end if;

			-- Paddle Movement Logic
			if input_tick = '1' then
				-- Left Paddle
				if sw(0) = '1' and paddle1_top > top_inner then
					paddle1_top <= paddle1_top - 1;
				elsif sw(1) = '1' and (paddle1_top + paddle_height) < bottom_inner then
					paddle1_top <= paddle1_top + 1;
				end if;
				
				-- Right Paddle
				if sw(2) = '1' and paddle2_top > top_inner then
					paddle2_top <= paddle2_top - 1;
				elsif sw(3) = '1' and (paddle2_top + paddle_height) < bottom_inner then
					paddle2_top <= paddle2_top + 1;
				end if;
			end if;
		end if;
	end process;

	-- Ball Logic
	process(pxl_clk)
	begin
		if rising_edge(pxl_clk) then
			-- Ball Frame Tick
			-- 25 Mhz/ 60 hz = 416 666 cycles
			-- The above is the rate of each frame
			if ball_counter = 416666 then
				ball_counter <= 0;
				ball_tick <= '1';
			else
				ball_counter <= ball_counter + 1;
				ball_tick <= '0';
			end if;
			
			
			if ball_tick = '1' then
				-- Reset Collision Checks
				top_border <= '0';
				bottom_border <= '0';
				left_border <= '0';
				right_border <= '0';
				left_paddle <= '0';
				right_paddle <= '0';
				
				-- Move Ball
				ball_h <= ball_h + ball_dx;
				ball_v <= ball_v + ball_dy;
				ball_mid <= ball_v + (ball_length/2);
				
				-- Goal not scored
				if(ball_state = '0') then
					-- Goal Logic
					if ball_h <= left_inner AND (ball_v >= net_top and ball_v <= net_bottom) then
						ball_state <= '1';
						-- Change ball colour to pink on goal
						ball_R <= x"FF";
						ball_G <= x"69";
						ball_B <= x"B4";
						
					elsif (ball_h + ball_length) >= right_inner AND (ball_v >= net_top and ball_v <= net_bottom) then
						ball_state <= '1';
						ball_R <= x"FF";
						ball_G <= x"69";
						ball_B <= x"B4";
						
					-- Left Paddle Collision Logic
					elsif (ball_h <= left_paddle_field) AND (ball_mid >= paddle1_top) AND (ball_mid < paddle1_top + paddle_up) then
						left_paddle <= '1';
						ball_dy <= -1;
						ball_dx <= 1;
					elsif (ball_h <= left_paddle_field) AND (ball_mid >= paddle1_top + paddle_up) AND (ball_mid < paddle1_top + paddle_straight) then
						left_paddle <= '1';
						ball_dy <= 0;
						ball_dx <= 1;
					elsif (ball_h <= left_paddle_field) AND (ball_mid >= paddle1_top + paddle_straight) AND (ball_mid <= paddle1_top + paddle_down) then
						left_paddle <= '1';
						ball_dy <= 1;
						ball_dx <= 1;
						
					-- Right Paddle Collision logic
					elsif (ball_h + ball_length >= right_paddle_field) AND (ball_mid >= paddle2_top) AND (ball_mid < paddle2_top + paddle_up) then
						right_paddle <= '1';
						ball_dy <= -1;
						ball_dx <= -1;
					elsif (ball_h + ball_length >= right_paddle_field) AND (ball_mid >= paddle2_top + paddle_up) AND (ball_mid < paddle2_top + paddle_straight) then
						right_paddle <= '1';
						ball_dy <= 0;
						ball_dx <= -1;
					elsif (ball_h + ball_length >= right_paddle_field) AND (ball_mid >= paddle2_top + paddle_straight) AND (ball_mid <= paddle2_top + paddle_down) then
						right_paddle <= '1';
						ball_dy <= 1;
						ball_dx <= -1;
					
					else
						-- Border Collision Logic
						if ball_h <= left_inner then
							left_border <= '1';
							ball_dx <= 1;
						elsif (ball_h + ball_length) >= right_inner then
							right_border <= '1';
							ball_dx <= -1;
						end if;
						
						if ball_v <= top_inner then
							top_border <= '1';
							ball_dy <= 1;
						elsif (ball_v + ball_length) >= bottom_inner then
							bottom_border <= '1';
							ball_dy <= -1;
						end if;
					end if;
					
				-- Goal Scored
				elsif ball_state = '1' then
					-- Reset Ball
					if (ball_h + ball_length < 0) OR ball_h > 639 then
						ball_h <= 314;
						ball_v <= 234;
						ball_dx <= -ball_dx; 
						-- Restore ball to red on reset
						ball_R <= "11111111";
						ball_G <= "00000000";
						ball_B <= "00000000";
						ball_state <= '0'; 
					end if;
				
				end if;
			end if;
		end if;

	end process;



-- Output Assignments
R <= R_sig;
G <= G_sig;
B <= B_sig;
h_sync <= h_sync_sig;
v_sync <= v_sync_sig;
DAC_clk <= pxl_clk; 

-- ChipScope ILA Signal Assignments
ila_data(0) <= h_sync_sig;
ila_data(1) <= v_sync_sig;
ila_data(2) <= ball_state;
ila_data(12 downto 3) <= h_pos_probe;
ila_data(22 downto 13) <= v_pos_probe;


end Behavioral;

