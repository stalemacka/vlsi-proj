library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
	generic (Tpd : Time := unit_delay;
			 mem_size : natural := 2**32;
			 word_size : natural := 32); --proveriti
	port (clk: in bit;
		  abus: in std_logic_vector (31 downto 0); --videti mozda da se velicina menja--
		  dbus: inout std_logic_vector (31 downto 0); --ovde moze da ide word_size
		  rdbus: in std_logic; --mislim da je ovako jer moze biti i u 'Z'
		  wrbus: in std_logic
	);
end memory;


architecture mem_arch of memory is 
	
	type mem_array is array (0 to mem_size -1) of std_logic_vector(word_size-1 downto 0);
	signal mem_block : mem_array;

begin	
read:	process (clk)
	begin
		if rising_edge(clk) then
			if rdbus = '1' then
				dbus <= mem_block(to_integer(unsigned(abus))) after Tpd;
			 --da li treba jos nesto???
			else 
				for i in dbus'range loop 
					dbus(i)<='Z';
				end loop;	
			end if;
		end if;
	end process;
	
write:	process (clk) --videti da li uspeva ovo sa read/write
	begin
		if rising_edge(clk) then
			if wrbus = '1' then
				mem_block(to_integer(unsigned(abus))) <= dbus after Tpd; --proveriti ovo za unsigned
			end if;
		end if;
	end process;
	
end mem_arch;
		  