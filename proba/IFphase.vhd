library ieee;
use work.all;
use ieee.std_logic_1164.all;


entity IFphase is
generic ( --Tpd : Time := unit_delay;
			word_size : natural := 32
			);
			
port (clk: in std_logic;
		reset: in std_logic;
		stall: in std_logic;
		
		pcBranch : in std_logic_vector(word_size-1 downto 0);
		isBranch: in std_logic;
		rdMem: out std_logic;
		pc_out: out std_logic_vector(word_size-1 downto 0);
		busToCache : out std_logic_vector(word_size-1 downto 0);
		busFromCache : in std_logic_vector(word_size-1 downto 0);
		mem_done : in std_logic;
		
		cond : out std_logic_vector(3 downto 0); -- staviti genericki
		typeI : out std_logic_vector(2 downto 0);
		opcode : out std_logic_vector(3 downto 0); -- staviti genericki
		lsBit, someBit, checkBit: out std_logic;
		rnMask, rd, rsRot, rm : out std_logic_vector(3 downto 0);
		imm: out std_logic_vector(7 downto 0);
		shiftA : out std_logic_vector(4 downto 0);
		shift : out std_logic_vector(1 downto 0);
		offIntNum : out std_logic_vector(23 downto 0);
		loadImm : out std_logic_vector(11 downto 0);
		waitingForMemory : out std_logic
		);
		
end IFphase;

architecture ifPhase_behav of IFphase is

component pc is
port(clk : in std_logic;
		cl, ld: in std_logic;
		indata : in std_logic_vector(31 downto 0);
		outdata : out std_logic_vector(31 downto 0));
end component pc;

component ir is
port (clk : in std_logic;
		irIn : in std_logic;
		instruction : in std_logic_vector(word_size -1 downto 0);		
		cond : out std_logic_vector(3 downto 0); -- staviti genericki
		typeI : out std_logic_vector(2 downto 0);
		opcode : out std_logic_vector(3 downto 0); -- staviti genericki
		lsBit, someBit, checkBit: out std_logic;
		rnMask, rd, rsRot, rm : out std_logic_vector(3 downto 0);
		imm: out std_logic_vector(7 downto 0);
		shiftA : out std_logic_vector(4 downto 0);
		shift : out std_logic_vector(1 downto 0);
		offIntNum : out std_logic_vector(23 downto 0);
		loadImm : out std_logic_vector(11 downto 0)
);
end component ir;

component mux2 is
generic (
		word_size : integer := 32
		--Tpd  : Time := unit_delay  --any value 
);
port (
		value1, value0 : in std_logic_vector(word_size-1 downto 0);
		value : out std_logic_vector(word_size-1 downto 0);
		value_selector : in std_logic
);
	  
end component mux2;

component adder is
generic (word_size_B : integer :=4);
port (indata : in std_logic_vector(word_size_B*8-1 downto 0);
		result: out std_logic_vector(word_size_B*8-1 downto 0);
		enable: in std_logic
		);
end component adder;

signal currPc, nextPc, pcOutIntern: std_logic_vector(word_size-1 downto 0);
signal pcLoad, irLoad, waitingMem : std_logic;
--da li stall ili poseban pcload
--treba gledati i upis u pc preko instrukcije!
begin
--pcLoad <= '1'; --ili variable ovde
irLoad <= '1';
muxIF: mux2 port map(value0=>nextPc, value1=>pcBranch, value=>pcOutIntern, value_selector=>isBranch ); --u currpc je bas vrednost koja treba ako nema skoka
--currPc ako je stall, pc_out ako nema skoka i nije stall, pcBranch ako ima skoka
newPc: adder port map(indata=>currPc, result=>nextPc, enable => not stall); --nextPc
pcReg: pc port map(clk=>clk, ld=>mem_done, indata=>pcOutIntern, outdata=>currPc, cl=>'0'); --videti da li moze ovako
irReg:ir port map (clk => clk, irIn => irLoad, instruction => busFromCache, cond => cond, typeI => typeI, opcode => opcode,
		lsBit => lsBit, someBit => someBit, checkBit => checkBit,
		rnMask => rnMask, rd => rd, rsRot => rsRot, rm => rm,	imm => imm,
		shiftA => shiftA,	shift => shift, offIntNum => offIntNum, loadImm => loadImm);

process (clk)
begin
--muxIF: mux2 port map(value0=>currPc, value1=>currPc, value2=>pc_out, value3=>pcBranch, value=>pcToRead, value_selector=> );
	if (rising_edge(clk)) then
		if (stall = '0' and waitingMem = '0') then
			rdMem<='1';
			waitingMem <= '1'; --videti da li treba oba
			busToCache <= currPc;
			waitingForMemory <= '1';
		--	pcLoad <= '1';
			--wait until mem_done = '1';
			--pcLoad <= '0'; --videti da li ovako
		else 
			--nextPc <= currPc;
		end if;
		pc_out <= nextPc;

	--u mux-u ce se izabrati pc
	end if;
end process;

--process (mem_done)
--begin
--	if (mem_done='1') then	
--		rdMem <= '0';
--		waitingMem <= '0';
--		waitingForMemory <= '1';
--	end if;
--end process;

end ifPhase_behav;
