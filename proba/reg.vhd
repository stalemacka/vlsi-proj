library ieee;
--uzeti od registara--
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.helper.all;


entity reg is
	generic (Tpd : Time := unit_delay
				cache_size_blocks : natural := 2**12);
	port ( -- da li treba clk?
		cl : in bit;
		inc : in bit;
		outData : out std_logic_vector(cache_size_blocks-1 downto 0)
	);
end reg;


architecture reg_arch of reg is
begin
	process(inc)
	signal tmpdata: integer;
	begin
		if (inc='1') then tmpdata <= (tmpdata + 1) mod cache_size_blocks;
		end if;
		outdata<= to_stdlogicvector(tmpdata) after Tpd;
	end process;
end pc_arch;