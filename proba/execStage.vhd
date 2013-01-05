library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
		
		
		dataOp	: in std_logic;
		shiftOp	: in std_logic;
		LoadStore : in std_logic;
		
		result 		: out std_logic_vector(31 downto 0);
		isBranch 	: out std_logic;
		newPc		: out std_logic_vector(31 downto 0);
		newOpcode	: out std_logic_vector(3 downro 0);
	);
	
end EXecStage;


arhitecture behavior of EXecStage is
	signal ALUout	: std_logic_vector(31 downto 0);
	signal aluN		: std_logic;
	signal aluZ		: std_logic;
	signal aluC		: std_logic;
	signal aluV		: std_logic;
	signal PC		: std_logic_vector(31 downto 0);
	signal branch	: std_logic;
	signal sp		: integer :=0;
	signal opc		: std_logic_vector(3 downto 0);

	signal rds		: std_logic_vecotr(4 downto 0);
	signal rdsValue : std_logic_vecotr(31 downto 0);
	
	signal prevRd 	: std_logic_vector(4 downto 0);
	signal dirtyBit : std_logic;
	signal prevALUout : std_logic_vector(31 downto 0);
begin

process is
	variable A_input, B_input, C_out: std_logic_vector(31 downto 0);

	wait until clk = '1'
	
	if (reset='1') then
		ALUout <= X"00_00_00_00";
		branch <= '0';
		PC <= X"00_00_00_00";
		rds <= '00000';
		sp := 0;
		opc <= "" -- NOP INSTRUCTION
		prevRd <= "0000";
		dirtyBit <= '0';
		prevALUout <= X"00_00_00_00";
	
		
	elsif (flush='1') then
		ALUout <= X"00_00_00_00";
		branch <= '0';
		PC <= X"00_00_00_00";
		rds <= '00000';
		sp := 0;
		opc <= "" -- NOP INSTRUCTION
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
			
			
			when andOpCode =>
				ALUout <= A_input and B_input;
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				
				prevRd <= VC;
				dirtyBit <= '1';
				preALUout <= A_input and B_input;
			when eorOpCode =>
				ALUout <= A_input and B_input;
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '1';
				prevRd <= VC;
				prevALUout <= A_input xor B_input;
			when subOpCode =>
				ALUout <= A_input - B_input;
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '1';
				prevRd <= VC;
				prevALUout <= A_input - B_input;
			when rsbOpCode =>
				ALUout <= B_inout - A_input;
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '1';
				prevRd <= VC;
				prevALUout <= B_input - A_input;
			when addOpCode =>
				ALUout <= A_input + B_input;
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '1';
				prevRd <= VC;
				prevALUout <= A_input + B_input;
			when adcOpCode =>
				
			when sbcOpCode =>
			
			when rscOpCode =>
			
			when tstOpCode =>
				ALUout <= A_input and B_input;
				branch <= '0';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '1';
				prevRd <= VC;
				prevALUout <= A_input and B_input;
			when teqOpCode =>
				
			when cmpOpCode =>
			
			when cmnOpCode =>
			
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
				PC <= A_input + imm;
				ALUout <= X"00000000";
				
				branch <= '1';
				rdsValue <= X"00_00_00_00";
				
				dirtyBit <= '0';
				prevRd <= "00000";
				prevALUout <= X"00_00_00_00";
			when jsrOpCode =>
				stack(sp) <= currentPc;
			when rtsOpCode =>
			
			when beqOpCode =>
				if(A_input = B_input) then
					ALUout <= X"00_00_00_00";
					PC <= currentPc + imm;
					branch <= '1';
					rdsValue <= X"00_00_00_00";
				else branch <= '0';
				end if;
				
				dirtyBit <= '0';
				prevRd <= "00000";
				prevALUout <= X"00_00_00_00";
			when bnqOpCode =>
				if(A_input = B_input) then branch <= '0';
				else
					PC <= currentPc + imm;
					rdsValue <= X"00_00_00_00";
					branch <= '1'
				end if;
				
				dirtyBit <= '0';
				prevRd <= "00000";
				prevALUout <= X"00_00_00_00";
			when bltOpCode =>
				if(A_input < B_input) then
					ALUout <= X"00_00_00_00";
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
			
			when popOpCode =>
			
			when nopOpCode =>
		end case;
			
	end if;
	
end process;

result <= ALUout;
isBranch <= branch;
newPc <= PC;
newOpcode <= opc




end EXecStage;