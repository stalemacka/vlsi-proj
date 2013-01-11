library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.UserConstants.all;
use work.all;
entity EXecStage is
	port(
		clk		: in std_logic;
		reset	: in std_logic;
		stall	: in std_logic;
		flush	: in std_logic;
		
		currentPc	: in std_logic_vector(31 downto 0);
		opcode	: in std_logic_vector(3 downto 0);
		isLoad, isStore, isCmp: in std_logic;
		
		imm		: in std_logic_vector(31 downto 0);
		A		: in std_logic_vector(31 downto 0);
		B		: in std_logic_vector(31 downto 0);
		C		: in std_logic_vector(31 downto 0);
		
		src1, src2, dst, shReg: in std_logic_vector(4 downto 0);
		
		VA		: in std_logic_vector(4 downto 0);
		VB		: in std_logic_vector(4 downto 0);
		VC		: in std_logic_vector(4 downto 0);
		
		cBit	: in std_logic;
		sBit	: in std_logic;
		mem_done: in std_logic;
		
		branchAndLink : in std_logic;
		
		dataOp	: in std_logic;
		shiftOp	: in std_logic;
		LoadStore : in std_logic;
		
		linkRegister: out std_logic_vector(31 downto 0);
		aluNout		: out std_logic;
		aluZout		: out std_logic;
		aluVout		: out std_logic;
		aluCout		: out std_logic;
		result 		: out std_logic_vector(31 downto 0);
		isBranch 	: out std_logic;
		newPc		: out std_logic_vector(31 downto 0);
		newOpcode	: out std_logic_vector(3 downto 0);
		
		memPh_dst: in std_logic_vector(4 downto 0);
		memPhVal: in std_logic_vector(31 downto 0);
		
		shiftVal : in std_logic_vector(4 downto 0);
		shiftType : in std_logic_vector(1 downto 0);
		shouldShift: in std_logic;
		
		rotate : in std_logic_vector(4 downto 0);
		byte : in std_logic;
	);
	
end EXecStage;


architecture EXecStage of EXecStage is
component condCalc
port (condField : in std_logic_vector(3 downto 0);
		flags : in std_logic_vector(3 downto 0);--, val2 : in std_logic_vector(word_size-1 downto 0);
		condVal : out std_logic);
end component;

	signal ALUout	: std_logic_vector(31 downto 0);
	signal tmpALUout: std_logic_vector(31 downto 0);
	signal aluN		: std_logic;
	signal aluZ		: std_logic;
	signal aluC		: std_logic;
	signal aluV		: std_logic;
	signal PC		: std_logic_vector(31 downto 0);
	signal branch	: std_logic;
	signal sp		: integer :=0;
	signal stackBus	: std_logic_vector(31 downto 0);	
	signal opc		: std_logic_vector(3 downto 0);

	signal rds		: std_logic_vector(4 downto 0);
	signal rdsValue : std_logic_vector(31 downto 0);
		
	signal prevRd 	: std_logic_vector(4 downto 0);
	signal dirtyBit : std_logic;
	signal prevALUout : std_logic_vector(31 downto 0);
	signal linkRegisterTmp : std_logic_vector(31 downto 0);
	
	signal cond		: std_logic;
	signal csr_flags: std_logic_vector(3 downto 0);
	signal condVal  : std_logic;
	
	signal prevDst: std_logic_vector(4 downto 0);
	signal prevVal: std_logic_vector(31 downto 0); 
	
begin
condition: condCalc port map (condField => cond, flags => csr_flags,
		condVal => condVal);
		
process(clk) 
	variable A_input, B_input, C_input: std_logic_vector(31 downto 0);
	variable shVal: std_logic_vector(4 downto 0);
	
begin
	if (rising_edge(clk)) then
	if (condVal) then
	
	aluZ <= '0';
	aluN <= '0';
	aluC <= '0';
	aluV <= '0';
	
	if (reset='1') then
		ALUout <= X"00_00_00_00";
		branch <= '0';
		PC <= X"00_00_00_00"; 
		rds <= "00000";
		sp <= 0;
		opc <= nopOpCode; --TODO NOP INSTRUCTION
		prevRd <= "0000";
		dirtyBit <= '0';
		prevALUout <= X"00_00_00_00";
	
		
	elsif (flush='1') then
		ALUout <= X"00_00_00_00";
		branch <= '0';
		PC <= X"00_00_00_00";
		rds <= "00000";
		sp <= 0;
		opc <= nopOpCode; --TODO NOP INSTRUCTION
		prevRd <= "0000";
		dirtyBit <= '0';
		prevALUout <= X"00_00_00_00";
		
	
	elsif (stall='0') then
	
		opc <= opcode;
		pc <= currentPc;
		rds <= VC;
		
		A_input := A; -- TODO ako je load, ako je aluopp, ako je iz prethodne
		
		B_input := B; -- TODO ako je load, ako je aluopp, ako je iz prethodne
	
		shVal <= shiftVal;
		--C_input := C;
		
		-- prosledjivanje
		if (src1 = prevDst) then
			A_input := prevVal;
		elsif (src1 = memPh_dst) then
			A_input := memPhVal;
		end;
		
		if (src2 = prevDst) then
			B_input := prevVal;
		elsif (src2 = memPh_dst) then
			B_input := memPhVal;
		end if;
		
		if (shReg = prevDst) then
			shVal := prevVal;
		elsif (shReg = memPh_dst) then
			shVal := memPhVal;
		end if;
		
		if (shouldShift = '1' and shVal /= "00000") then
			case shiftType is
				when lsl => B_input := B_input sll conv_integer(shVal);
				when lsr => B_input := B_input srl conv_integer(shVal);
				when asr => B_input := B_input sra conv_integer(shVal);
				when rorS => B_input := B_input ror conv_integer(shVal);
			end case;
		end if;
		
		if (rotate /= "0000") then
			B_input := B_input ror (2*conv_integer(rotate));
		end if;
		
		if (isLoad = '1' or isStore = '1') then 
			ALUout <= std_logic_vector(conv_integer(A_input) + conv_integer(imm));
			branch <= '0';
			if (isStore = '1') then
				rdsValue <= B_input;
			else
				rdsValue <= X"00_00_00_00";
			end if;
		else
			case opc is
				
				when andOpCode =>
					ALUout <= A_input and B_input;
					branch <= '0';
					rdsValue <= X"00_00_00_00";
					
					prevRd <= VC;
					dirtyBit <= '1';
					prevALUout <= A_input and B_input;
					if (sBit = '1') then
						aluN <= ALUout'left;
						aluZ <= not (conv_integer(ALUout) = 0); 
					end if;
					/*N Flag = Rd[31]
						Z Flag = if Rd == 0 then 1 else 0
						C Flag = shifter_carry_out
						V Flag = unaffected*/
				when eorOpCode =>
					ALUout <= A_input xor B_input;
					branch <= '0';
					rdsValue <= X"00_00_00_00";
					
					dirtyBit <= '1';
					prevRd <= VC;
					prevALUout <= A_input xor B_input;
					
				when orrOpCode =>
					ALUout <= A_input or B_input;
					branch <= '0';
					rdsValue <= X"00_00_00_00";
					
					dirtyBit <= '1';
					prevRd <= VC;
					prevALUout <= A_input or B_input;
					
				when subOpCode =>
					ALUout <= std_logic_vector(conv_integer(A_input) - conv_integer(B_input));
					if (sBit = '1') then 
						aluV <= (not A_input(A_input'left) and B_input(B_input'left) and ALUout(ALUout'left)) or (A_input(A_input'left) and not B_input(B_input'left) and not ALUout(ALUout'left));
					end if;
					branch <= '0';
					rdsValue <= X"00_00_00_00";
					
					dirtyBit <= '1';
					prevRd <= VC;
					prevALUout <= std_logic_vector(conv_integer(A_input) - conv_integer(B_input));
					
				when rsbOpCode =>
					ALUout <= std_logic_vector(conv_integer(B_input) - conv_integer(A_input));
					if (sBit = '1') then 
						aluV <= (not B_input(B_input'left) and A_input(A_input'left) and ALUout(ALUout'left)) or (B_input(B_input'left) and not A_input(A_input'left) and not ALUout(ALUout'left));
					end if;
					branch <= '0';
					rdsValue <= X"00_00_00_00";
					
					dirtyBit <= '1';
					prevRd <= VC;
					prevALUout <= std_logic_vector(conv_integer(B_input) - conv_integer(A_input));
					
				when addOpCode =>
					ALUout <= std_logic_vector(conv_integer(A_input) + conv_integer(B_input));
					if (sBit = '1') then 
						aluV <= (not A_input(A_input'left) and not B_input(B_input'left) and ALUout(ALUout'left)) or (A_input(A_input'left) and B_input(B_input'left) and not ALUout(ALUout'left));
						tmpALUout <= std_logic_vector(conv_integer(A_input) + conv_integer(B_input));
						aluC <= tmpALUout(tmpALUout'left);
					end if;
					branch <= '0';
					rdsValue <= X"00_00_00_00";
					
					dirtyBit <= '1';
					prevRd <= VC;
					prevALUout <= std_logic_vector(conv_integer(A_input) + conv_integer(B_input));
					
				when adcOpCode =>
					ALUout <= std_logic_vector(conv_integer(A_input) + conv_integer(B_input)+conv_integer(cBit));
					if (sBit = '1') then 
						tmpALUout <= std_logic_vector(conv_integer(A_input) + conv_integer(B_input)+conv_integer(cBit));
						aluC <= tmpALUout(tmpALUout'left);
					end if;
					branch <= '0';
					rdsValue <= X"00_00_00_00";
					
					dirtyBit <= '1';
					prevRd <= VC;
					prevALUout <= std_logic_vector(conv_integer(A_input) + conv_integer(B_input)+conv_integer(cBit));
					
				when sbcOpCode =>
					ALUout <= std_logic_vector(conv_integer(A_input) - conv_integer(B_input) - conv_integer(not cBit));
					branch <= '0';
					rdsValue <= X"00_00_00_00";
					
					dirtyBit <= '1';
					prevRd <= VC;
					prevALUout <= std_logic_vector(conv_integer(A_input) - conv_integer(B_input) - conv_integer(not cBit));
				
				when rscOpCode =>
					ALUout <= std_logic_vector(conv_integer(B_input) - conv_integer(A_input) - conv_integer(not cBit));
					branch <= '0';
					rdsValue <= X"00_00_00_00";
					
					dirtyBit <= '1';
					prevRd <= VC;
					prevALUout <= std_logic_vector(conv_integer(B_input) - conv_integer(A_input) - conv_integer(not cBit))
				
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
					
					if (sBit = '1') then
						aluN <= ALUout'left;
						aluZ <= not (conv_integer(ALUout) = 0);
					end if;
					/*N Flag = Rd[31]
						Z Flag = if Rd == 0 then 1 else 0
						C Flag = unaffected
						V Flag = unaffected*/
				when mvnOpCode =>
					ALUout <= not A_input;
					branch <= '0';
					rdsValue <= X"00_00_00_00";
					
					dirtyBit <= '1';
					prevRd <= VC;
					prevALUout <= not A_input;

				when branchOpCode =>
					if(condVal = '1') then
						ALUout <= X"00_00_00_00";
						PC <= currentPc + imm;
						branch <= '1';
						rdsValue <= X"00_00_00_00";
					else branch <= '0';
					end if;
					
					dirtyBit <= '0';
					prevRd <= "00000";
					prevALUout <= X"00_00_00_00";
				when branchAndLinkOpCode => --treba srediti postindeksno i sl
					if(condVal = '1') then
						ALUout <= X"00_00_00_00";
						linkRegisterTmp <= currentPc;
						stackBus <= currentPc;
						wait until mem_done = '1';
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
				when nopOpCode =>
					dirtyBit <= '0';
					prevRd <= "00000";
					prevALUout <= X"00_00_00_00";
			end case;
		end if; --load/store
		
		case opc is
			when andOpCode | eorOpCode | subOpCode | rsbOpCode | addOpCode | adcOpCode |  sbcOpCode
				| rscOpCode | orrOpCode | bicOpCode | movOpCode | mvnOpCode => 
					prevDst <= dst;
					prevVal <= ALUout;
		end case;
		
	end if; --reset
	end if; --condval
	end if; --clk
	
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
linkRegister <= linkRegisterTmp;

aluNout <= aluN;
aluZout <= aluZ;
aluCout <= aluC;
aluVout <= aluV;



end EXecStage;