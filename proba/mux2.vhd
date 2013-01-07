library ieee;

use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;

entity mux2 is
	generic (
		word_size : integer := 32;
		Tpd  : Time := 5ns  --any value 
	);
	port (
		value1, value0 : in std_logic_vector(word_size-1 downto 0);
		value : out std_logic_vector(word_size-1 downto 0);
		value_selector : in std_logic
	);
end mux2;


architecture mux2_behav of mux2 is
begin
	with value_selector select
			value <= value0 after Tpd when '0',
						value1 after Tpd when '1';
end mux2_behav;