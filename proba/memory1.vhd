library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity memory is
	generic (--Tpd : Time := unit_delay;
			word_size : natural := 32;
			mem_size : natural := 2**32;
			addr_unit_size : natural := 8;
			module_num : natural := 16); --proveriti
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

	type mem_module is array (0 to mem_size/module_num-1) of std_logic_vector(addr_unit_size-1 downto 0);
	type mem_array is array (0 to module_num-1) of mem_module;
	type clkCount is array (0 to module_num/(word_size/addr_unit_size)-1) of integer;
	type addrMod is array (0 to module_num/(word_size/addr_unit_size)-1) of integer;
	type dataArray is array (0 to module_num/(word_size/addr_unit_size)-1) of std_logic_vector(word_size-1 downto 0);
	
	signal mem_block : mem_array;	
	signal currAddr, ordNum : integer;
	signal counters : clkCount;
	signal offsets : addrMod;
	signal word1, word2, word3, word4 : std_logic;
	signal data : dataArray;

begin	

process (clk, rdbus, wrbus)
	begin
		if rising_edge(clk) then
			if (rdbus = '1' or wrbus = '1') then
				currAddr <= conv_integer(abus);
				ordNum <= integer((currAddr mod module_num) / (word_size/addr_unit_size));
				if (counters(ordNum) = 0) then
					if (rdbus= '1') then
						counters(ordNum) <= 11 ;
					else 
						counters(ordNum) <= 10; --!!!;
					end if;
					offsets(ordNum) <= integer(conv_integer(abus(word_size-1 downto 4))); --!!!
					case ordNum is
						when 0 => word1 <= '1';
						when 1 => word2 <= '1';
						when 2 => word3 <= '1';
						when 3 => word4 <= '1';
					end case;
					if (wrbus = '1') then
						data(ordNum) <= dbus;
					end if;
				end if;
			end if;
		end if;
	end process;
	
--/*write: process (clk) --videti da li uspeva ovo sa read/write
--	begin
--		if rising_edge(clk) then
--			if wrbus = '1' then
--			--	currAddr := conv_integer(abus);
--				for i in 0 to 9 loop --videti koji broj ovde treba
--					wait until rising_edge(clk);
--				end loop;
--				for i in 0 to 3 loop
--					currAddr := conv_integer(abus);
--					mem_block(currAddr) <= dbus(word_size-1 downto word_size-8);
--					mem_block(currAddr+1) <= dbus(word_size-9 downto word_size-16);
--					mem_block(currAddr+2) <= dbus(word_size-17 downto word_size-24);
--					mem_block(currAddr+3) <= dbus(word_size-25 downto 0);
--					done <= '1';
--					wait until proceed = '1';
--					--done <= '0';
--				end loop;
--				--mem_block(conv_integer(abus)) <= dbus; --proveriti ovo za unsigned
--			end if;
--		end if;
--	end process;*/

process (word1, clk)	
begin
	if (word1 = '1') then
		if rising_edge(clk) then
			counters(0) <= counters(0) -1;
			if (counters(0) = 0) then
				if (rdbus = '1') then
					dbus(word_size-1 downto word_size-8) <= mem_block(0)(offsets(0));
					dbus(word_size-9 downto word_size-16) <= mem_block(1)(offsets(0));
					dbus(word_size-17 downto word_size-24) <= mem_block(2)(offsets(0));
					dbus(word_size-25 downto 0) <= mem_block(3)(offsets(0));
					done <='1';
				else
					mem_block(0)(offsets(0)) <= data(0)(word_size-1 downto word_size-8);
					mem_block(1)(offsets(0)) <= data(0)(word_size-9 downto word_size-16);
					mem_block(2)(offsets(0)) <= data(0)(word_size-17 downto word_size-24);
					mem_block(3)(offsets(0)) <= data(0)(word_size-25 downto 0);
					done <='1';
				end if;
				word1 <= '0';
			end if;
		end if;
	end if;
end process;

process (word2, clk)	
begin
	if (word2 = '1') then
		if rising_edge(clk) then
			counters(1) <= counters(1) -1;
			if (counters(1) = 0) then
				if (rdbus = '1') then
					dbus(word_size-1 downto word_size-8) <= mem_block(4)(offsets(1));
					dbus(word_size-9 downto word_size-16) <= mem_block(5)(offsets(1));
					dbus(word_size-17 downto word_size-24) <= mem_block(6)(offsets(1));
					dbus(word_size-25 downto 0) <= mem_block(7)(offsets(1));
					done <='1';
				else
					mem_block(4)(offsets(1)) <= data(1)(word_size-1 downto word_size-8);
					mem_block(5)(offsets(1)) <= data(1)(word_size-9 downto word_size-16);
					mem_block(6)(offsets(1)) <= data(1)(word_size-17 downto word_size-24);
					mem_block(7)(offsets(1)) <= data(1)(word_size-25 downto 0);
					done <= '1';
				end if;
				word2 <= '0';
			end if;
		end if;
	end if;
end process;

process (word3, clk)	
begin
	if (word3 = '1') then
		if rising_edge(clk) then
			counters(2) <= counters(2) -1;
			if (counters(2) = 2) then
				if (rdbus = '1') then
					dbus(word_size-1 downto word_size-8) <= mem_block(8)(offsets(2));
					dbus(word_size-9 downto word_size-16) <= mem_block(9)(offsets(2));
					dbus(word_size-17 downto word_size-24) <= mem_block(10)(offsets(2));
					dbus(word_size-25 downto 0) <= mem_block(11)(offsets(2));
					done <='1';
				else
					mem_block(8)(offsets(2)) <= data(2)(word_size-1 downto word_size-8);
					mem_block(9)(offsets(2)) <= data(2)(word_size-9 downto word_size-16);
					mem_block(10)(offsets(2)) <= data(2)(word_size-17 downto word_size-24);
					mem_block(11)(offsets(2)) <= data(2)(word_size-25 downto 0);
					done <='1';
				end if;
				word3 <= '0';
			end if;
		end if;
	end if;
end process;


process (word4, clk)	
begin
	if (word4 = '1') then
		if rising_edge(clk) then
			counters(3) <= counters(3) -1;
			if (counters(3) = 0) then
				if (rdbus = '1') then
					dbus(word_size-1 downto word_size-8) <= mem_block(12)(offsets(3));
					dbus(word_size-9 downto word_size-16) <= mem_block(13)(offsets(3));
					dbus(word_size-17 downto word_size-24) <= mem_block(14)(offsets(3));
					dbus(word_size-25 downto 0) <= mem_block(15)(offsets(3));
					done <='1';
				else
					mem_block(12)(offsets(3)) <= data(3)(word_size-1 downto word_size-8);
					mem_block(13)(offsets(3)) <= data(3)(word_size-9 downto word_size-16);
					mem_block(14)(offsets(3)) <= data(3)(word_size-17 downto word_size-24);
					mem_block(15)(offsets(3)) <= data(3)(word_size-25 downto 0);
					done <='1';
				end if;
				word4 <= '0';
			end if;
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
		  