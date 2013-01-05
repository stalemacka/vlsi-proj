library ieee;
--uzeti od registara--
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity ir is
	generic (Tpd : Time := unit_delay);
	port (
		clk : in std_logic;
		irIn : in bit;
		instruction : in std_logic_vector(word_size-1 downto 0);		
		cond : out std_logic_vector(3 downto 0); -- staviti genericki
		typeI : out std_logic_vector(3 downto 0);
		opcode : out std_logic_vector(3 downto 0); -- staviti genericki
		pBit, uBit, bBit, wBit, lsBit, someBit, checkBit: out std_logic;
		rnMask, rd, rsRot, rm : out std_logic_vector(3 downto 0);
		imm: out std_logic_vector(7 downto 0);
		shiftA : out std_logic_vector(4 downto 0);
		shift : out std_logic_vector(1 downto 0);
		offIntNum : out std_logic_vector(23 downto 0);
		loadImm : out std_logic_vector(11 downto 0)		
	);
end ir;


architecture ir_behav of ir is
begin

instDec: process (clk)
	begin
	if rising_edge(clk) then
			if (irIn = '1') then
				cond <= instruction(31 downto 28);
				typeI <= instruction(27 downto 25);
				opcode <= instruction(24 downto 21);
				pBit <= instruction(24);
				uBit <= instruction(23);
				bBit <= instruction(22);
				wBit <= instruction(21);
				lsBit <= instruction(20);
				someBit <= instruction(4);
				checkBit <= instruction(7);
				rnMask <= instruction(19 downto 16);
				rd <= instruction(15 downto 12);
				rsRot <= instruction(11 downto 8);
				rm <= instruction(3 downto 0);
				imm <= instruction(7 downto 0);
				shiftA <= instruction(11 downto 7);
				shift <= instruction(6 downto 5);
				offIntNum <= instruction(23 downto 0);
				loadImm <= instruction(11 downto 0);
			end if;	
	end if;	
end process instDec; 
			
end ir_behav;