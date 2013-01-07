library ieee;

use ieee.numeric_std.all;


entity mux4 is
	generic (
		size : integer := 32;
		Tpd  : Time := 5ns  --any value 
	);
	port (
		value1, value2, value3, value0 : in bit_vector(size-1 downto 0);
		value : out bit_vector(size-1 downto 0);
		value_selector : in bit_vector(1 downto 0)
	);
end mux4;


architecture mux4_arch of mux4 is
begin		
	with value_selector select
		value <= value0 after Tpd when "00",
					value1 after Tpd when "01",
					value2 after Tpd when "10",
					value3 after Tpd when "11";
end mux4_arch;