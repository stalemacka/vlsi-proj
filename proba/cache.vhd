library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

--vrv treba izbaciti na ABUS/DBUS, dodati 0!
--menjati da bude po 1B
entity cache is 
generic (--Tpd: Time := unit_delay;
			 cache_size_blocks: natural := 2**12; --videti da li 16kb
			 word_size: natural := 32;
			 block_size: natural := 2**2;
			 tag_length: natural := 28); --proveriti
port (clk: in std_logic;
		rd, wr: in std_logic;
		  addrCPU: in std_logic_vector (31 downto 0); --staviti abus size
		  dataToCPU: out std_logic_vector (word_size-1 downto 0); --ovde moze da ide word_size
		  dataFromCpu: in std_logic_vector (word_size-1 downto 0); --ovde moze da ide word_size
		  rdMem: out std_logic; --mislim da je ovako jer moze biti i u 'Z'
		  wrMem: out std_logic; --mozda prosledjivati celu adresu a ne samo tag
		  opByte: in std_logic;
		  
		  hit: out std_logic;
		 		  
		  dataToMem: out std_logic_vector (word_size-1 downto 0);
		  addrMem : out std_logic_vector (tag_length-1 downto 0);
		  mem_done: in std_logic;
		  dataFromMem: in std_logic_vector (word_size-1 downto 0); --ovde moze da ide word_size
		  memContinue : out std_logic		  
	);
end cache;

--uvesti stanja!!!

architecture cache_behav of cache is 
	component reg
		generic (--Tpd : Time := unit_delay;
					cache_size_block : natural := 2**12);
		port ( -- da li treba clk?
			cl : in std_logic;
			inc : in std_logic;
			outData : out std_logic_vector(cache_size_block-1 downto 0)
		);
	end component;
	
	type blockType is array (0 to block_size-1) of std_logic_vector(word_size-1 downto 0);
	
	type cache_entry is record	
		VBit, DBit : std_logic;
		tag : std_logic_vector(tag_length-1 downto 0);
		data : blockType;
	end record;
	
	type cache_array is array (0 to cache_size_blocks -1) of cache_entry;
	
	type cache_state is (IDLE, MISS, MISS_WB);
	
	variable i: integer range 0 to cache_size_blocks;
	variable notFound: boolean;
	variable entryNum : natural;
	variable hlp: natural;
	
	shared variable bla : std_logic;
	signal tmpTag : std_logic_vector(tag_length-1 downto 0);
	--videti da li t shared variable
	signal cache_mem : cache_array;
	signal state : cache_state;
	signal cntValue : std_logic_vector(cache_size_blocks-1 downto 0);
	signal incCnt, clCnt : std_logic;
	signal localHit : std_logic;

begin	

	cnt : reg port map ( -- da li treba clk?
			cl => clCnt,
			inc => incCnt,
			outData => cntValue
		);
			
process(clk)
begin	
		if (rising_edge(clk)) then
			--dodati reset
			if (rd = '1' or wr = '1') then
			incCnt <= '0';
			case state is
				when IDLE =>
					entryNum := conv_integer(cntValue);--videti za unsigned
					-- da li sve da ide u if
					i := 0;
					notFound := true;
					localHit <= '0';
					while (i<cache_size_blocks and notFound) loop
						if (cache_mem(i).tag = addrCPU(31 downto 4)) then
							if (cache_mem(i).VBit = '1') then
								localHit <= '1';
								notFound := false;
							end if;
						else
							i := i+1;
						end if;
					end loop;
					
					if (localHit='0' and mem_done='0') then
						if (cache_mem(entryNum).VBit='1' and cache_mem(entryNum).DBit='1') then
							state <= MISS_WB;
							wrMem <= '1';
							cache_mem(entryNum).VBit <= '0';
							dataToMem <= cache_mem(entryNum).data(0); --ovo je jedna rec
							i:= 0;
							addrMem(31 downto 4) <= cache_mem(entryNum).tag;
							addrMem(3 downto 0) <= "0000";
							tmpTag <= addrCPU(31 downto 4);
						else
							state <= MISS;
							rdMem <= '1';
							cache_mem(entryNum).VBit <= '0';
							addrMem(31 downto 4) <= addrCPU(31 downto 4);
							addrMem(3 downto 0) <= "0000";
						end if;
					elsif (localHit='1') then
						if (rd = '1') then
							if (opByte = '1') then
								hlp := integer((conv_integer(addrCPU) mod 16) / 4); --videti da li je ovo ceo deo ili ne								
								dataToCPU(31 downto 8) <= (others => '0');
								dataToCPU(7 downto 0) <= cache_mem(i).data(hlp)((3-(hlp mod 4))*8+7 downto (3-(hlp mod 4))*8); --proveriti ovo!!!
							else
								dataToCPU <= cache_mem(i).data(hlp); --ovo je ceo blok, ne moze!!!
							end if;
						elsif (wr = '1') then
							cache_mem(i).DBit <= '1';
							if (opByte = '1') then
								hlp := integer((conv_integer(addrCPU) mod 16) / 4); --videti da li je ovo ceo deo ili ne
								cache_mem(i).data(hlp)((3-(hlp mod 4))*8+7 downto (3-(hlp mod 4))*8) <= dataFromCpu(7 downto 0);
							else
								cache_mem(i).data(hlp) <= dataFromCpu;								
							end if;
						end if;
					end if;
					
				when MISS_WB =>
					for j in 1 to 3 loop
						wait until mem_done = '1';
						--addrMem(31 downto 4) <= cache_mem(entryNum).tag; videti da li moze samo deo da se izmeni
						--memContinue <='0';
						addrMem(3 downto 0) <= std_logic_vector(to_unsigned(4*j, 4));
						dataToMem <= cache_mem(entryNum).data(j);
						memContinue <= '1';
					end loop;
						memContinue <='0';
						wrMem <= '0';
						rdMem <= '1';						
						addrMem(31 downto 4) <= tmpTag;
						addrMem(3 downto 0) <= "0000";						
						state <= MISS;					
				
				when MISS =>
					cache_mem(entryNum).VBit <= '1';
					cache_mem(entryNum).DBit <= '0';
					cache_mem(entryNum).tag <= tmpTag;
					for j in 0 to 3 loop
						wait until mem_done = '1';		
						--memContinue <='0';
						cache_mem(entryNum).data(j) <= dataFromMem;
						addrMem(3 downto 0) <= std_logic_vector(to_unsigned(4*(j+1), 4));
						memContinue <= '1';
					end loop;
					memContinue <= '0';
					localHit <= '1';
					if (rd = '1') then
						hlp := integer((conv_integer(addrCPU) mod 16) / 4);
						if (opByte = '1') then
							--hlp := integer((conv_integer(addrCPU) mod 16) / 4); --videti da li je ovo ceo deo ili ne								
							dataToCPU(31 downto 8) <= (others => '0');
							dataToCPU(7 downto 0) <= cache_mem(entryNum).data(hlp)((3-(hlp mod 4))*8+7 downto (3-(hlp mod 4))*8);
						else
							dataToCPU <= cache_mem(entryNum).data(hlp); --mozda -1?
						end if;
					elsif (wr = '1') then
						cache_mem(entryNum).DBit <= '1';
						if (opByte = '1') then
							hlp := integer((conv_integer(addrCPU) mod 16) / 4); --videti da li je ovo ceo deo ili ne
							cache_mem(entryNum).data(hlp)((3-(hlp mod 4))*8+7 downto (3-(hlp mod 4))*8) <= dataFromCpu(7 downto 0);
						else
							cache_mem(entryNum).data(hlp) <= dataFromCpu;								
						end if;
					end if;
					incCnt <= '1';
					state <= IDLE;
				
				when others => 
					null; --proveriti ovo 
			end case;
			end if; --if rd||wr
		end if;
	end process;
	
	process(mem_done) --proveriti da li ovako
	begin
		if (mem_done = '1') then
			memContinue <= '0';
		end if;
	end process;
hit<=localHit;						
		
end cache_behav;
