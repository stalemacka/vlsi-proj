library ieee;
--uzeti od registara--
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity reg is
	generic (--Tpd : Time := unit_delay;
				cache_size_blocks : natural := 2**12);
	port ( -- da li treba clk?
		cl : in std_logic;
		inc : in std_logic;
		outData : out std_logic_vector(cache_size_blocks-1 downto 0)
	);
end reg;


architecture reg_behav of reg is
signal tmpdata: integer;
begin
	process(inc)
	
	begin
		if (inc='1') then tmpdata <= (tmpdata + 1) mod cache_size_blocks;
		end if;
		outdata<= std_logic_vector(to_signed(tmpdata, cache_size_blocks));-- after Tpd;
	end process;
end reg_behav;