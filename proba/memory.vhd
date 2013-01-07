library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity memory is
	generic (--Tpd : Time := unit_delay;
			word_size : natural := 32;
			 mem_size : natural := 2**32;
			 addr_unit_size : natural := 8); --proveriti
	port (clk: in std_logic;
		  abus: in std_logic_vector (31 downto 0); --videti mozda da se velicina menja--
		  dbus: inout std_logic_vector (31 downto 0); --ovde moze da ide word_size
		  rdbus: in std_logic; --mislim da je ovako jer moze biti i u 'Z'
		  wrbus: in std_logic;
		  
		  proceed: in std_logic; --postaviti na 0 u memoriji
		  done: out std_logic
	);
end memory;


architecture mem_arch of memory is 
	
	type mem_array is array (0 to mem_size -1) of std_logic_vector(addr_unit_size-1 downto 0);
	signal mem_block : mem_array;
	
	variable currAddr : integer;

begin	
read:	process (clk)
	begin
		if rising_edge(clk) then
			if rdbus = '1' then
				
				for i in 0 to 10 loop --videti koji broj ovde treba
					wait until rising_edge(clk);
				end loop;
				for i in 0 to 3 loop
					currAddr := conv_integer(abus);
					dbus(word_size-1 downto word_size-8) <= mem_block(currAddr);
					dbus(word_size-9 downto word_size-16) <= mem_block(currAddr+1);
					dbus(word_size-17 downto word_size-24) <= mem_block(currAddr+2);
					dbus(word_size-25 downto 0) <= mem_block(currAddr+3);
					done <= '1';
					wait until proceed = '1';
					done <= '0';
					--currAddr:=currAddr+4;
				end loop;
				--dbus <= mem_block(conv_integer(abus));
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
			--	currAddr := conv_integer(abus);
				for i in 0 to 9 loop --videti koji broj ovde treba
					wait until rising_edge(clk);
				end loop;
				for i in 0 to 3 loop
					currAddr := conv_integer(abus);
					mem_block(currAddr) <= dbus(word_size-1 downto word_size-8);
					mem_block(currAddr+1) <= dbus(word_size-9 downto word_size-16);
					mem_block(currAddr+2) <= dbus(word_size-17 downto word_size-24);
					mem_block(currAddr+3) <= dbus(word_size-25 downto 0);
					done <= '1';
					wait until proceed = '1';
					--done <= '0';
				end loop;
				--mem_block(conv_integer(abus)) <= dbus; --proveriti ovo za unsigned
			end if;
		end if;
	end process;

process(proceed)
begin
	if (proceed = '1') then
		done <= '0';
	end if;
end process;
end mem_arch;
		  