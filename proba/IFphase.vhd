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
		typeI : out std_logic_vector(3 downto 0);
		opcode : out std_logic_vector(3 downto 0); -- staviti genericki
		pBit, uBit, bBit, wBit, lsBit, someBit, checkBit: out std_logic;
		rnMask, rd, rsRot, rm : out std_logic_vector(3 downto 0);
		imm: out std_logic_vector(7 downto 0);
		shiftA : out std_logic_vector(3 downto 0);
		shift : out std_logic_vector(1 downto 0);
		offIntNum : out std_logic_vector(23 downto 0);
		loadImm : out std_logic_vector(11 downto 0)
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
		typeI : out std_logic_vector(3 downto 0);
		opcode : out std_logic_vector(3 downto 0); -- staviti genericki
		pBit, uBit, bBit, wBit, lsBit, someBit, checkBit: out std_logic;
		rnMask, rd, rsRot, rm : out std_logic_vector(3 downto 0);
		imm: out std_logic_vector(7 downto 0);
		shiftA : out std_logic_vector(3 downto 0);
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
		result: out std_logic_vector(word_size_B*8-1 downto 0)
		);
end component adder;

signal currPc, nextPc, pcOutIntern: std_logic_vector(word_size-1 downto 0);
signal pcLoad, irLoad : std_logic;


begin
pcLoad <= '1'; --ili variable ovde
irLoad <= '1';
muxIF: mux2 port map(value0=>currPc, value1=>pcBranch, value=>pc_out, value_selector=>isBranch ); --u currpc je bas vrednost koja treba ako nema skoka
--currPc ako je stall, pc_out ako nema skoka i nije stall, pcBranch ako ima skoka
newPc: adder port map(indata=>pcOutIntern, result=>nextPc); --nextPc
pcReg: pc port map(clk=>clk, ld=>pcLoad, indata=>nextPc, outdata=>currPc, cl=>'0'); --videti da li moze ovako
irReg:ir port map (clk => clk, irIn => irLoad, instruction => busFromCache, cond => cond, typeI => typeI,	opcode => opcode,
		pBit => pBit, uBit => uBit, bBit => bBit, wBit => wBit, lsBit => lsBit, someBit => someBit, checkBit => checkBit,
		rnMask => rnMask, rd => rd, rsRot => rsRot, rm => rm,	imm => imm,
		shiftA => shiftA,	shift => shift, offIntNum => offIntNum, loadImm => loadImm);

process (clk)
begin
--muxIF: mux2 port map(value0=>currPc, value1=>currPc, value2=>pc_out, value3=>pcBranch, value=>pcToRead, value_selector=> );

if (rising_edge(clk)) then
	if (stall = '0') then
		rdMem<='1';
		busToCache <= pcOutIntern;
		wait until mem_done = '1';
	else 
		nextPc <= currPc;
	end if;


--u mux-u ce se izabrati pc

end if;
end process; -- ne znam da li u proces stavljati
pc_out <= pcOutIntern;
end ifPhase_behav;
