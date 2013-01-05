library ieee;
--uzeti od registara--
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.helper.all;


entity pc is
	generic (Tpd : Time := unit_delay);
	port (
		clk : in std_logic;
		cl, ld: in std_logic;
		indata : in std_logic_vector(31 downto 0);
		outdata : out std_logic_vector(31 downto 0)
	);
end pc;


architecture pc_arch of pc is
begin
	process(clk)
	variable tmpdata: integer;
	begin
		if rising_edge(clk) then
			if cl = '1' then tmpdata := 0; --videti da li treba--
			elsif ld = '1' then tmpdata := to_integer(unsigned(to_stdLogicVector(indata)));
			end if;
		end if;
		outdata<= to_bitvector(std_logic_vector(to_unsigned(tmpdata, 32))) after Tpd;
	end process;
end pc_arch;