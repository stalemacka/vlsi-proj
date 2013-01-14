library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.UserConstants.all;


entity IDphase is
generic (num_reg_bits : natural :=4;
			word_size : natural :=32;
			reg_size : natural :=32);
port (clk: std_logic;
		reset: std_logic;
		pc_in: std_logic_vector(word_size-1 downto 0);
		flush, stall : in std_logic;
		
		cond : in std_logic_vector(3 downto 0); -- staviti genericki
		typeI : in std_logic_vector(2 downto 0);
		opcode : in std_logic_vector(3 downto 0); -- staviti genericki
		lsBit, someBit, checkBit: in std_logic;
		rnMask, rd, rsRot, rm : in std_logic_vector(3 downto 0);
		imm: in std_logic_vector(7 downto 0);
		shiftA : in std_logic_vector(4 downto 0);
		shift : in std_logic_vector(1 downto 0);
		offIntNum : in std_logic_vector(23 downto 0);	
		loadImm : in std_logic_vector(11 downto 0);
		writeRegAddr: in std_logic_vector(num_reg_bits-1 downto 0);
		writeRegData: in std_logic_vector(word_size-1 downto 0);
		wrReg: in std_logic;
		condOut : out std_logic_vector(3 downto 0);
		typeIOut : out std_logic_vector(2 downto 0);
		opcodeOut : out std_logic_vector(3 downto 0);
		operand1 : out std_logic_vector(word_size-1 downto 0);
		operand2 : out std_logic_vector(word_size-1 downto 0);
		isLoad, isStore, isCmp, isLink, isStop : out std_logic;
		shiftType : out std_logic_vector(1 downto 0);
		shiftOut : out std_logic_vector(7 downto 0);
		rotateOut : out std_logic_vector(3 downto 0);		
		immValToRot : out std_logic_vector(31 downto 0);
		src1Addr, src2Addr, dstAddr : out std_logic_vector(3 downto 0);
		shouldShift: out std_logic;
		stReg, cstReg : out std_logic
		);
		
end IDphase;

architecture idPhase_behav of IDphase is

component regFile
generic ( 
				 num_reg_bits : integer := 4;
				 reg_size : integer := 32
				-- Tpd : Time := unit_delay
			);
				 
	port (	clk : in std_logic;
				reset : in std_logic;
				read_addr1 : in std_logic_vector(num_reg_bits - 1 downto 0);
				read_addr2 : in std_logic_vector(num_reg_bits - 1 downto 0);
				read_4shift : in std_logic_vector(num_reg_bits - 1 downto 0);
				write_addr : in std_logic_vector(num_reg_bits - 1 downto 0);
				outVal1 : out std_logic_vector(reg_size - 1 downto 0);				
				outVal2 : out std_logic_vector(reg_size - 1 downto 0);	
				outShiftVal : out std_logic_vector(7 downto 0);			
				inVal : in std_logic_vector(reg_size - 1 downto 0);
				wEn : std_logic;
				r1En, r2En, rshiftEn : std_logic
			);	
end component;

component mux2 is
	generic (
		word_size : integer := 32
	);
	port (
		value1, value0 : in std_logic_vector(word_size-1 downto 0);
		value : out std_logic_vector(word_size-1 downto 0);
		value_selector : in std_logic
	);
end component;

component adder is
generic (word_size_B : integer :=4);
port (indata : in std_logic_vector(word_size_B*8-1 downto 0);
		result: out std_logic_vector(word_size_B*8-1 downto 0));
end component;

signal condVal,shiftSel : std_logic;
signal operand1Addr, operand2Addr, shiftAddr : std_logic_vector(num_reg_bits -1 downto 0);
signal shift_intern: std_logic_vector(4 downto 0);
signal regShift: std_logic_vector(7 downto 0);
signal read1, read2, readShift, op2Sel : std_logic;
signal regOp2: std_logic_vector(reg_size-1 downto 0);
signal tmpImm : std_logic_vector(word_size-1 downto 0);
--signal imm_intern

begin

registers: regFile port map (
		clk => clk,	reset => reset, read_addr1 =>operand1Addr, read_addr2 =>operand2Addr, read_4shift=> shiftAddr,
		write_addr => writeRegAddr, outVal1 => operand1, outVal2 => regOp2, outShiftVal => regShift,--videti da li ovde povezati shiftout
		inVal => writeRegData, wEn => wrReg, r1En => read1, r2En => read2, rshiftEn=> readShift
); --zanemarice se operand2 gde nije potreban

muxOp2: mux2 port map (value0 => regOp2, value1 => tmpImm, value => operand2, value_selector => op2Sel);  
muxShift: mux2 generic map (word_size => 8) port map  (value0 => '0' & '0' & '0' & shiftA, value1 => regShift, value => shiftOut, value_selector => shiftSel);  

process (clk)
begin	--postaviti sve na nule
	if (rising_edge(clk)) then
		--if (condVal = '1') then --inace ubaciti nop
		if (flush = '1') then 
			shiftType <= shift;
			--shiftOut <= "00000000";
			isCmp <= '0';
			isLoad <= '0';
			isStore <= '0';
			--isBranch <= '0';
			isLink <= '0';
			read1<='0';
			read2<='0';
			readShift <= '0';
			rotateOut <= "0000";
			shouldShift <= '0';
			op2Sel <= '0';
			stReg <= '0';
			cstReg <= '0';
			isStop <= '0';
			shiftSel <= '0';
		else
			shiftType <= shift;
		--	shiftOut <= "00000000";
		--	isCmp <= '0';
			isLoad <= '0';
			isStore <= '0';
			--isBranch <= '0';
			isLink <= '0';
			read1<='0';
			read2<='0';
			readShift <= '0';
			rotateOut <= "0000";
			shouldShift <= '0';
			op2Sel <= '0';
			stReg <= '0';
			cstReg <= '0';
			isStop <= '0';
			shiftSel <= '0';
			
			case typeI is		
				when dpis_rs_srr_sr => 
					if (opcode(3) = '1' and opcode(2) = '0') then 
						if (lsBit = '1') then
							isCmp <= '1'; --videti da li treba
							operand1Addr <= rnMask;
							operand2Addr <= rm;
							read1 <= '1';
							read2 <= '1';
							shouldShift <= '1';
							if (someBit = '1') then 
								if (checkBit /= '0') then --prekid
								else 
									readShift <= '1';
									shiftAddr <= rsRot;	
									shiftSel <= '1';
									--shiftOut <= regShift;-- da li ce ovde doci dobra vrednost?! 
									--if (conv_integer(regShift) < 32) then shiftOut <= regShift(4 downto 0);
									--else shiftOut <= "00000"; -- videti sta sa carry									
								end if;
--							else
--								--shiftOut <= shiftA;
							end if;
						else 
							--ovde treba za pristup csr-u							
							if (opcode(1) = '0') then cstReg <= '1';
							else stReg <= '1';
							end if;
							if (opcode(0) = '1') then
								read2 <= '1';
								operand2Addr <= rm;
								operand1Addr <= rnMask;
							else
								dstAddr <= rd;								
							end if;
						end if;
					else --nisu one sto se 'preklapaju', neke od dp_is si
						 operand1Addr <= rnMask;
						 operand2Addr <= rm;
						 read1 <= '1';
						 read2 <= '1';
						 shouldShift <= '1';
						 if (someBit = '1') then 
							if (checkBit /= '0') then --prekid
							else 
								readShift <= '1';
								shiftAddr <= rsRot;
								shiftSel <= '1';
								--if (conv_integer(regShift) < 32) then shiftOut <= regShift(4 downto 0);
								--else shiftOut <= "00000"; -- videti sta sa carry
								--shiftOut <= regShift;
							end if;
--						 else
--							shiftOut <= shiftA;
						 end if;						 
					end if;
				
				when dp_sr_i => 
					if (opcode(3) = '1' and opcode(2) = '0') then 
						if (lsBit = '1') then							
							operand1Addr <= rnMask;
							read1 <= '1';
							rotateOut <= rsRot;							
							op2Sel <= '1';	
							tmpImm (7 downto 0) <= imm;
							tmpImm (word_size-1 downto 8) <= (others => '0'); 							
							immValToRot <= tmpImm;
						else --pristup csru
							if (opcode(1) = '0') then cstReg <= '1';
							else stReg <= '1';
							end if;
							operand1Addr <= rnMask;
							rotateOut <= rsRot;
							tmpImm (7 downto 0) <= imm;
							tmpImm (word_size-1 downto 8) <= (others => '0'); 							
							immValToRot <= tmpImm;
							op2Sel <= '1';
						end if;
					else
						operand1Addr <= rnMask;
						read1 <= '1';
						rotateOut <= rsRot;
						op2Sel <= '1';
						tmpImm (7 downto 0) <= imm;
						tmpImm (word_size-1 downto 8) <= (others => '0'); 							
						immValToRot <= tmpImm;
					end if;
					
				when ls_r => 
					if (someBit /= '0') then --prekid
					else
						read1 <= '1';
						read2 <= '1';
						operand1Addr <= rnMask;
						operand2Addr <= rm;
						if (opcode(3)='1') then isLoad <='1';
						else isStore <='1';
						end if;
						--shiftAmount vec ima;
					end if;
					
				when ls_i =>
					-- videti da li je oznacena vrednost
					read1 <= '1';
					operand1Addr <= rnMask;
					if (opcode(3)='1') then isLoad <='1';
					else isStore <='1';
					end if;
					op2Sel <= '1';
					tmpImm(11 downto 0) <= loadImm;
					tmpImm(31 downto 12) <= (others => '0');
					immValToRot <= tmpImm;
				when br => 
					--isBranch <= '1';	
					if (lsBit = '1') then 
						isLink <= '1';
					end if;
				
				when swi_s =>
					if (opcode(3) = '0') then 
						isStop <= '1';
					else
					end if;
				
				when others => null; --!!! interrupt
			end case;
		condOut <= cond;
		typeIOut <= typeI;
		opcodeOut <= opcode;
		src1Addr <= operand1Addr;
		src2Addr <= operand2Addr;
		dstAddr <= rd;
	end if;
end if;


--muxOp1: mux2 port map (value0 => regOp1, value1 => , value => operand1, value_selector => op1Sel);


end process;


end idPhase_behav;

