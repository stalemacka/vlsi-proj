library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.UserConstants.all;


entity clock is

port (clk : out std_logic);
end clock;

architecture clock_behav of clock is

begin

process
begin
	clk <= '1';
	wait for clk_period / 2;
	clk <= '0';
	wait for clk_period / 2;
	
end process;
 
end clock_behav;