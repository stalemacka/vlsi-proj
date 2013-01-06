library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.UserConstants.all;
entity EXecStage is
	port(
		clk		: in std_logic;
		reset	: in std_logic;
		stall	: in std_logic;
		flush	: in std_logic;
		
		currentPc	: in std_logic_vector(31 downto 0);
		opcode	: in std_logic_vector(3 downto 0);
		
		imm		: in std_logic_vector(31 downto 0);
		A		: in std_logic_vector(31 downto 0);
		B		: in std_logic_vector(31 downto 0);
		C		: in std_logic_vector(31 downto 0);
		
		VA		: in std_logic_vector(4 downto 0);
		VB		: in std_logic_vector(4 downto 0);
		VC		: in std_logic_vector(4 downto 0);
		
		cBit	: in std_logic;
		sBit	: in std_logic;
		
		
		branchAndLink : in std_logic;
		r14		: reg_inc_dec;
		
		dataOp	: in std_logic;
		shiftOp	: in std_logic;
		LoadStore : in std_logic;
		
		aluNout		: out std_logic;
		aluZout		: out std_logic;
		aluVout		: out std_logic;
		aluCout		: out std_logic;
		result 		: out std_logic_vector(31 downto 0);
		isBranch 	: out std_logic;
		newPc		: out std_logic_vector(31 downto 0);
		newOpcode	: out std_logic_vector(3 downto 0)
	);
	
end EXecStage;


architecture EXecStage of EXecStage is
	signal ALUout	: std_logic_vector(31 downto 0);
	signal tmpALUout: std_logic_vector(32 downto 0);
	signal aluN		: std_logic;
	signal aluZ		: std_logic;
	signal aluC		: std_logic;
	signal aluV		: std_logic;
	signal PC		: std_logic_vector(31 downto 0);
	signal branch	: std_logic;
	signal sp		: integer :=0;
	signal stack	: steck_mem;	
	signal opc		: std_logic_vector(3 downto 0);

	signal rds		: std_logic_vector(4 downto 0);
	signal rdsValue : std_logic_vector(31 downto 0);
		
	signal prevRd 	: std_logic_vector(4 downto 0);
	signal dirtyBit : std_logic;
	signal prevALUout : std_logic_vector(31 downto 0);
	signal r14tmp	: reg_inc_dec;
begin

process is
	variable A_input, B_input, C_out: std_logic_vector(31 downto 0);
begin
	wait until clk = '1';
	
	aluZ <= '0';
	aluN <= '0';
	aluC <= '0';
	aluV <= '0';
	
	if (reset='1') then
		ALUout <= X"00_00_00_00";
		branch <= '0';
		PC <= X"00_00_00_00";
		rds <= "00000";
		sp := 0;
		opc <= ""; --TODO NOP INSTRUCTION
		prevRd <= "0000";
		dirtyBit <= '0';
		prevALUout <= X"00_00_00_00";
	
		
	elsif (flush='1') then
		ALUout <= X"00_00_00_00";
		branch <= '0';
		PC <= X"00_00_00_00";
		rds <= "00000";
		sp := 0;
		opc <= ""; --TODO NOP INSTRUCTION
		prevRd <= "0000";
		dirtyBit <= '0';
		prevALUout <= X"00_00_00_00";
		
	
	elsif (stall='0') then
	
		opc <= opcode;
		pc <= currentPc;
		rds <= VC;
		
		A_input <= A; -- TODO ako je load, ako je aluopp, ako je iz prethodne
		
		B_input <= B; -- TODO ako je load, ako je aluopp, ako je iz prethodne
	
		C_input <= C;
		
		
		case opc is
			when loadOpCode | storeOpCode =>
				ALUout <= A_input + imm;
				branch <= '0';
				if (opc = storeOpCode) then
					rdsValue <= B_input;
				else
					rdsValue <= X"00_00_00_00";
				end if;
				
			
			when andOpCode =>
				ALUout <= A_input and B_input;
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				
				prevRd <= VC;
				dirtyBit <= '1';
				prevALUout <= A_input and B_input;
			when eorOpCode =>
				ALUout <= A_input and B_input;
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '1';
				prevRd <= VC;
				prevALUout <= A_input xor B_input;
			when subOpCode =>
				ALUout <= A_input - B_input;
				if (sBit = '1') then 
					aluV <= (not A_input(A_input'left) and B_input(B_input'left) and ALUout(ALUout'left)) or (A_input(A_input'left) and not B_input(B_input'left) and not ALUout(ALUout'left));
				end if;
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '1';
				prevRd <= VC;
				prevALUout <= A_input - B_input;
			when rsbOpCode =>
				ALUout <= B_input - A_input;
				if (sBit = '1') then 
					aluV <= (not B_input(B_input'left) and A_input(A_input'left) and ALUout(ALUout'left)) or (B_input(B_input'left) and not A_input(A_input'left) and not ALUout(ALUout'left));
				end if;
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '1';
				prevRd <= VC;
				prevALUout <= B_input - A_input;
			when addOpCode =>
				ALUout <= A_input + B_input;
				if (sBit = '1') then 
					aluV <= (not A_input(A_input'left) and not B_input(B_input'left) and ALUout(ALUout'left)) or (A_input(A_input'left) and B_input(B_input'left) and not ALUout(ALUout'left));
					tmpALUout <= A_input + B_input;
					aluC <= tmpALUout(tmpALUout'left);
				end if;
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '1';
				prevRd <= VC;
				prevALUout <= A_input + B_input;
			when adcOpCode =>
				ALUout <= A_input + B_input + cBit;
				if (sBit = '1') then 
					tmpALUout <= A_input + B_input + cBit;
					aluC <= tmpALUout(tmpALUout'left);
				end if;
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '1';
				prevRd <= VC;
				prevALUout <= A_input + B_input + cBit;
			when sbcOpCode =>
				ALUout <= A_input - B_input + cBit;
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '1';
				prevRd <= VC;
				prevALUout <= A_input - B_input + cBit;
			when rscOpCode =>
				ALUout <= B_input - A_input + cBit;
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '1';
				prevRd <= VC;
				prevALUout <= B_input - A_input + cBit;
			when tstOpCode =>
				ALUout <= A_input and B_input;
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '1';
				prevRd <= VC;
				prevALUout <= A_input and B_input;
			when teqOpCode =>
				if (A_input = B_input) then
					ALUout <= X"00_00_00_01";
					prevALUout <= X"00_00_00_01";
				else
					ALUout <= X"00_00_00_00";
					prevALUout <= X"00_00_00_00";
				end if;
				
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				dirtyBit <= '1';
				prevRd <= VC;
			when cmpOpCode =>
				if (A_input = B_input) then
					ALUout <= X"00_00_00_00";
					prevALUout <= X"00_00_00_00";
				elsif (A_input > B_input) then
					ALUout <= X"00_00_00_01";
					prevALUout <= X"00_00_00_01";
				else
					ALUout <= X"11_11_11_11";
					prevALUout <= X"11_11_11_11";
				end if;
				
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				dirtyBit <= '1';
				prevRd <= VC;
			when cmnOpCode =>
				if (A_input = not B_input) then
					ALUout <= X"00_00_00_00";
					prevALUout <= X"00_00_00_00";
				elsif (A_input > not B_input) then 
					ALUout <= X"00_00_00_01";
					prevALUout <= X"00_00_00_01";
				else
					ALUout <= X"11_11_11_11";
					prevALUout <= X"11_11_11_11";
				end if;
				
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				dirtyBit <= '1';
				prevRd <= VC;
			when orrOpCode =>
				ALUout <= A_input and B_input;
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '1';
				prevRd <= VC;
				prevALUout <= A_input and B_input;
			when movOpCode =>
				ALUout <= A_input;
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '1';
				prevRd <= VC;
				prevALUout <= A_input;
			when bicOpCode =>
				ALUout <= A_input and (not B_input);
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '1';
				prevRd <= VC;
				prevALUout <= A_input;
			when mvnOpCode =>
				ALUout <= not A_input;
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '1';
				prevRd <= VC;
				prevALUout <= not A_input;
			when jmpOpCode =>
				if (branchAndLink = '1') then
					r14tmp <= currentPc;
				end if;
				PC <= A_input + imm;
				ALUout <= X"00000000";
				
				branch <= '1';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '0';
				prevRd <= "00000";
				prevALUout <= X"00_00_00_00";
			when jsrOpCode =>
				if (branchAndLink = '1') then
					r14tmp <= currentPc;
				end if;
				stack(sp) <= currentPc;
				sp <= sp + 1;
				PC <= A_input + imm;
				branch <= '1';
				ALUout <= X"00_00_00_00";
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '0';
				prevRd <= "00000";
				prevALUout <= X"00_00_00_00";
				
			when rtsOpCode =>
				if (branchAndLink = '1') then
					r14tmp <= currentPc;
				end if;
				sp <= sp - 1;
				PC <= stack(sp);
				branch <= '1';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '0';
				prevRd <= "00000";
				prevALUout <= X"00_00_00_00";
			when beqOpCode =>
				if(A_input = B_input) then
					ALUout <= X"00_00_00_00";
					if (branchAndLink = '1') then
						r14tmp <= currentPc;
					end if;
					PC <= currentPc + imm;
					branch <= '1';
					rdsValue <= X"00_00_00_00";
				else branch <= '0';
				end if;
				
				dirtyBit <= '0';
				prevRd <= "00000";
				prevALUout <= X"00_00_00_00";
			when bnqOpCode =>
				if(A_input = B_input) then 
					branch <= '0';
				else
					if (branchAndLink = '1') then
						r14tmp <= currentPc;
					end if;
					PC <= currentPc + imm;
					rdsValue <= X"00_00_00_00";
					branch <= '1';
				end if;
				
				dirtyBit <= '0';
				prevRd <= "00000";
				prevALUout <= X"00_00_00_00";
			when bltOpCode =>
				if(A_input < B_input) then
					ALUout <= X"00_00_00_00";
					if (branchAndLink = '1') then
						r14tmp <= currentPc;
					end if;
					PC <= currentPc + imm;
					branch <= '1';
					rdsValue <= X"00_00_00_00";
				else branch <= '0';
				end if;
				
				dirtyBit <= '0';
				prevRd <= "00000";
				prevALUout <= X"00_00_00_00";
			when bgtOpCode =>
				if(A_input > B_input) then
					ALUout <= X"00_00_00_00";
					if (branchAndLink = '1')
						r14tmp <= currentPc;
					end if;
					PC <= currentPc + imm;
					branch <= '1';
					rdsValue <= X"00_00_00_00";
				else branch <= '0';
				end if;
				
				dirtyBit <= '0';
				prevRd <= "00000";
				prevALUout <= X"00_00_00_00";
			when bleOpCode =>
				if(A_input <= B_input) then
					ALUout <= X"00_00_00_00";
					if (branchAndLink = '1')
						r14tmp <= currentPc;
					end if;
					PC <= currentPc + imm;
					branch <= '1';
					rdsValue <= X"00_00_00_00";
				else branch <= '0';
				end if;
				
				dirtyBit <= '0';
				prevRd <= "00000";
				prevALUout <= X"00_00_00_00";
			when bgeOpCode =>
				if(A_input >= B_input) then
					ALUout <= X"00_00_00_00";
					if (branchAndLink = '1')
						r14tmp <= currentPc;
					end if;
					PC <= currentPc + imm;
					branch <= '1';
					rdsValue <= X"00_00_00_00";
				else branch <= '0';
				end if;
				
				dirtyBit <= '0';
				prevRd <= "00000";
				prevALUout <= X"00_00_00_00";
			when haltOpCode =>
				branch <= '0';
				rdsValue <= X"00_00_00_00";	
				
				dirtyBit <= '0';
				prevRd <= "00000";
				prevALUout <= X"00_00_00_00";
			when pushOpCode =>
				stack(sp) <= A_input;
				sp <= sp + 1;
				-- TODO greska za overflow
				branch <= '0';
				ALUout <= X"00_00_00_00";
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '0';
				prevRd <= "00000";
				prevALUout <= X"00_00_00_00";
			when popOpCode =>
				sp <= sp - 1;
				-- TODO ako je sp = 0
				
				ALUout <= stack(sp);
				rdsValue <= X"00_00_00_00";
				branch <= '0';
				
				dirtyBit <= '1';
				prevRd <= VC;
				prevALUout <=  stack(sp);
			when nopOpCode =>
				dirtyBit <= '0';
				prevRd <= "00000";
				prevALUout <= X"00_00_00_00";
		end case;
			
	end if;
	
	if (sBit = '1') then 
		if (ALUout = X"00_00_00_00") then
			aluZ <= '1';
		end if;
		aluN <= ALUout(ALUout'left);
	end if;
end process;



result <= ALUout;
isBranch <= branch;
newPc <= PC;
newOpcode <= opc;
r14 <= r14tmp;

aluNout <= aluN;
aluZout <= aluZ;
aluCout <= aluC;
aluVout <= aluV;



end EXecStage;