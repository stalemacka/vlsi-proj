library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--vrv treba izbaciti na ABUS/DBUS, dodati 0!
entity cache is 
generic (Tpd: Time := unit_delay;
			 cache_size_blocks: natural := 2**12; --videti da li 16kb
			 word_size: natural := 32;
			 block_size: natural := 2**2;
			 tag_length: natural := 15); --proveriti
port (clk: in bit;
		  tagCPU: in std_logic_vector (tag_length-1 downto 0); --videti mozda da se velicina menja--
		  dataCPU: out std_logic_vector (word_size-1 downto 0); --ovde moze da ide word_size
		  rdMem: out std_logic; --mislim da je ovako jer moze biti i u 'Z'
		  wrMem: out std_logic; --mozda prosledjivati celu adresu a ne samo tag
		  hit: out std_logic;
		  
		  cpuInMemOut: inout std_logic_vector (word_size-1 downto 0); --ovde moze da ide word_size
		  tagMem : out std_logic_vector (tag_length-1 downto 0);
		  mem_done: in std_logic;
		  dataMem: in std_logic_vector (word_size-1 downto 0) --ovde moze da ide word_size
		  
	);
end cache;

--uvesti stanja!!!

architecture cache_behav of cache is 
	
	type cache_entry is record	
		VBit, DBit : std_logic;
		tag : std_logic_vector(tag_length-1 downto 0);
		data : array (0 to block_size-1) of std_logic_vector(word_size-1 downto 0);
	end record;
	
	type cache_array is array (0 to cache_size_blocks -1) of cache_entry;
	
	type cache_state is (IDLE, MISS, MISS_WB);
	
	variable i: integer range 0 to cache_size_blocks;
	variable notFound: boolean;
	variable entryNum : natural;
	
	shared variable bla : std_logic;
	shared variable tmpTag : std_logic_vector(tag_length-1 downto 0);
	--videti da li moze shared variable
	signal cache_mem : cache_array;
	signal state : cache_state;
	signal cntValue : std_logic_vector(cache_size_blocks-1)
	component reg
		generic (Tpd : Time := unit_delay
					cache_size_block : natural := 2**12);
		port ( -- da li treba clk?
			cl : in bit;
			inc : in bit;
			outData : out std_logic_vector(cache_size_block-1 downto 0)
		);
	end component;
	

begin	

	cnt : reg port map ( -- da li treba clk?
			cl => clCnt;
			inc => incCnt;
			outData : cntValue
		);
	entryNum := to_unsigned(conv_integer(cntValue));
	
	i := 0;
	notFound := true;
	while (i<cache_size_blocks and notFound)
		if (cache_mem(i).tag = tag) then
			if (cache_mem(i).VBit = '1') then
				hit <= '1';
				notFound := false;
			end if;
		else
			i := i+1;
		end if;
	end while;
				
	process(clk)
	begin	
		if (rising_edge(clk)) then
			--dodati reset
			case state is
				when IDLE =>
					if (hit='0' and mem_done='0') then
						if (cache_mem(entryNum).VBit='1' and cache_mem(entryNum).DBit='1') then
							state <= MISS_WB;
							wrMem <= '1';
							cache_mem(entryNum).VBit <= '0';
							cpuInMemOut <= cache_mem(entryNum).data;
							tagMem <= cache_mem(entryNum).tag;
							tmpTag := tagCPU;
						else
							state <= MISS;
							rdMem <= '1';
							cache_mem(entryNum).VBit <= '0';
							tagMem <= tmpTag;
						end if;
					elsif (hit='1') then
						if (rd = '1') then
							dataCPU <= cache_mem(i).data; --mozda -1?
						elsif (wr = '1') then
							cache_mem(i).data <= cpuInMemOut;
							cache_mem(i).DBit <= '1';
						end if;
					end if;
					
				when MISS_WB =>
					if (mem_done='1') then
						state <= MISS;
						rdMem <= '1';
						tagMem <= tmpTag;
					end if;
				
				when MISS =>
					if (mem_done='1') then
						cache_mem(entryNum).VBit <= '1';
						cache_mem(entryNum).DBit <= '0';
						cache_mem(entryNum).tag <= tmpTag;
						cache_mem(entryNum).data <= dataMem;
						hit <= '1';
						dataCPU <= dataMem;
						incCnt <= '1';
						state <= IDLE;
					end if;
				when others => 
					null; --proveriti ovo 
			end case;
		end if;
	end process;
						
		
end cache_behav;
