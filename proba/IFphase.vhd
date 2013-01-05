library ieee;
use work.all;
use ieee.std_logic_1164.all;


entity IFphase is
generic ( Tpd : Time := unit_delay;
			word_size :natural := 32;
			);
port (clk: in std_logic;
		reset: in std_logic;
		stall: in std_logic;
		
		pcBranch : in std_logic_vector(word_size-1 downto 0);
		
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
port(clk: in std_logic;
	  ld: in std_logic;
	  in_data: in bit_32;
	  out_data: out bit_32);
end component pc;

component ir is
port (clk : in std_logic;
		irIn : in bit;
		instruction : in std_logic_vector(downto 0);		
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
		word_size : integer := 32;
		Tpd  : Time := unit_delay  --any value 
);
port (
		value1, value0 : in std_logic_vector(word_size-1 downto 0);
		value : out std_logic_vector(word_size-1 downto 0);
		value_selector : in bit
);
	  
end component mux2;
/*
component ir is
generic (Tpd : Time := unit_delay);
port (
		clk : in std_logic;
		irIn : in bit;
		instruction : in std_logic_vector(downto 0);		
		cond : out std_logic_vector(3 downto 0); -- staviti genericki
		opcode : out std_logic_vector(3 downto 0); -- staviti genericki
		pBit, uBit, bBit, wBit, lsBit: out std_logic;
		rnMask, rd, rsRot, rm : out std_logic_vector(3 downto 0);
		imm: out std_logic_vector(7 downto 0);
		shiftA : out std_logic_vector(3 downto 0);
		shift : out std_logic_vector(1 downto 0);
		offIntNum : out std_logic_vector(23 downto 0)		
	);
end component ir;*/

component adder is
generic (word_size_B : integer :=4);
port (indata : in std_logic_vector(word_size_B*8-1 downto 0)
		result: out std_logic_vector(word_size_B*8-1 downto 0));
end component adder;

signal currPc, nextPc: std_logic_vector(word_size-1 downto 0);
signal pcLoad : std_logic <= '1';


begin

process (clk)
begin
--muxIF: mux2 port map(value0=>currPc, value1=>currPc, value2=>pc_out, value3=>pcBranch, value=>pcToRead, value_selector=> );
muxIF: mux2 port map(value0=>currPc, value1=>pcBranch, value=>pc_out, value_selector=> ); --u currpc je bas vrednost koja treba ako nema skoka
--currPc ako je stall, pc_out ako nema skoka i nije stall, pcBranch ako ima skoka
newPc: adder port map(indata=>pc_out, outdata=>nextPc); --nextPc

if (rising_edge(clk)) then
	if (stall = '0') then
		rdMem<='1';
		busToCache <= pc_out;
		wait until mem_done = '1';
		irReg:ir port map (clk => clk, irIn => irLoad, instruction => busFromCache, cond => cond, typeI => typeI,	opcode => opcode,
		pBit => pBit, uBit => uBit, bBit => bBit, wBit => wBit, lsBit => lsBit, someBit => someBit, checkBit => checkBit,
		rnMask => rnMask, rd => rd, rsRot => rsRot, rm => rm,	imm => imm,
		shiftA => shiftA,	shift => shift, offIntNum => offIntNum, loadImm => loadImm);
	else 
		nextPc <= currPc;
	end if;
pcReg: pc port map(clk=>clk, ld=>pcLoad, indata=>nextPc, outdata=>currPc); --videti da li moze ovako

--u mux-u ce se izabrati pc

end if;
end process; -- ne znam da li u proces stavljati
end ifPhase_behav;

