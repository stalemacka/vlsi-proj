library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.UserConstants.all;


entity IDphase is
generic (num_reg_bits : natural :=5;
			word_size : natural :=32;
			reg_size : natural :=32);
port (clk: std_logic;
		reset: std_logic;
		csr_flags: in std_logic_vector(3 downto 0);
		pc_in: std_logic_vector(word_size-1 downto 0);
		
		cond : in std_logic_vector(3 downto 0); -- staviti genericki
		typeI : in std_logic_vector(3 downto 0);
		opcode : in std_logic_vector(3 downto 0); -- staviti genericki
		pBit, uBit, bBit, wBit, lsBit, someBit, checkBit: in std_logic;
		rnMask, rd, rsRot, rm : in std_logic_vector(3 downto 0);
		imm: in std_logic_vector(7 downto 0);
		shiftA : in std_logic_vector(4 downto 0);
		shift : in std_logic_vector(1 downto 0);
		offIntNum : in std_logic_vector(23 downto 0);	
		loadImm : in std_logic_vector(11 downto 0);
		writeRegAddr: in std_logic_vector(num_reg_bits-1 downto 0);
		writeRegData: in std_logic_vector(word_size-1 downto 0);
		wrReg: in std_logic;
		
		aluOp : out std_logic_vector(3 downto 0);
		operand1 : out std_logic_vector(word_size-1 downto 0);
		operand2 : out std_logic_vector(word_size-1 downto 0);
		isCmp, isLoad, isStore, isBranch, link, stop : out std_logic;
		shiftType : out std_logic_vector(1 downto 0);
		shiftOut : out std_logic_vector(4 downto 0);
		rotateOut : out std_logic_vector(3 downto 0);
		
		src1, src2, dst, shReg : out std_logic_vector(num_reg_bits-1 downto 0);
		shouldShift: out std_logic;
		stReg, cstReg : out std_logic
		);
		
end IDphase;

architecture idPhase_behav of IDphase is

component regFile
generic ( 
				 num_reg_bits : integer := 5;
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
				r1En, r2En, rshiftEn : std_logic;
				src1, src2: out std_logic_vector(num_reg_bits-1 downto 0)
			);	
end component;

component condCalc
port (condField : in std_logic_vector(3 downto 0);
		flags : in std_logic_vector(3 downto 0);--, val2 : in std_logic_vector(word_size-1 downto 0);
		condVal : out std_logic);
end component;

component mux2 is
	generic (
		word_size : integer := 32;
	);
	port (
		value1, value0 : in std_logic_vector(word_size-1 downto 0);
		value : out std_logic_vector(word_size-1 downto 0);
		value_selector : in bit
	);
end component;

component adder is
generic (word_size_B : integer :=4);
port (indata : in std_logic_vector(word_size_B*8-1 downto 0);
		result: out std_logic_vector(word_size_B*8-1 downto 0));
end adder;

signal condVal: std_logic;
signal operand1Addr, operand2Addr, shiftAddr : std_logic_vector(num_reg_bits -1 downto 0);
signal shift_intern: std_logic_vector(4 downto 0);
signal regShift: std_logic_vector(7 downto 0);
signal read1, read2, readShift : std_logic;
signal regOp2: std_logic_vector(reg_size-1 downto 0);
signal tmpImm : std_logic_vector(word_size-1 downto 0);
--signal imm_intern

begin

registers: regFile port map (
		clk => clk,	reset => reset, read_addr1 =>operand1Addr, read_addr2 =>operand2Addr, read_4shift=> shiftAddr,
		write_addr => writeRegAddr, outVal1 => operand1, outVal2 => regOp2, outShiftVal => shiftOut,--videti da li ovde povezati shiftout
		inVal => writeRegData, wEn => wrReg, r1En => read1, r2En => read2, rshiftEn=> readShift
); --zanemarice se operand2 gde nije potreban

process (clk)
begin	--postaviti sve na nule
	if (rising_edge(clk)) then
		--if (condVal = '1') then --inace ubaciti nop
			shiftType <= shift;
			shiftOut <= "00000";
			isCmp <= '0';
			isLoad <= '0';
			isStore <= '0';
			isBranch <= '0';
			link <= '0';
			read1<='0';
			read2<='0';
			readShift <= '0';
			wrReg<='0';
			rotateOut <= "0000";
			shouldShift <= '0';
			opSel2 <= '0';
			stReg <= '0';
			cstReg <= '0';
			stop <= '0';
			
			case typeI is		
				when dpis_rs_srr_sr => 
					if (pBit = '1' and uBit = '0') then 
						if (lsBit = '1') then
							--isCmp <= '1'; --videti da li treba
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
									--shiftOut <= regShift;-- da li ce ovde doci dobra vrednost?! 
									--if (conv_integer(regShift) < 32) then shiftOut <= regShift(4 downto 0);
									--else shiftOut <= "00000"; -- videti sta sa carry
									end if;
								end if;
							else
								shiftOut <= shiftA;
							end if;
						else 
							--ovde treba za pristup csr-u							
							if (bBit = '0') then cstReg <= '1';
							else stReg <= '1';
							end if;
							if (wBit = '1') then
								read2 <= '1';
								operand2Addr <= rm;
								operand1Addr <= rnMask;
							else
								dst <= rd;								
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
								--if (conv_integer(regShift) < 32) then shiftOut <= regShift(4 downto 0);
								--else shiftOut <= "00000"; -- videti sta sa carry
								--shiftOut <= regShift;
								end if;	
							end if;
						 else
							shiftOut <= shiftA;
						 end if;						 
					end if;
				
				when dp_sr_i => 
					if (pBit = '1' and uBit = '0') then 
						if (lsBit = '1') then							
							operand1Addr <= rnMask;
							read1 <= '1';
							rotateOut <= rsRot;							
							op2Sel <= '1';	
							tmpImm (7 downto 0) <= imm;
							tmpImm (word_size-1 downto 8) <= (others => '0'); 
						else --pristup csru
							if (bBit = '0') then cstReg <= '1';
							else stReg <= '1';
							end if;
							operand1Addr <= rnMask;
							rotateOut <= rsRot;
							tmpImm(7 downto 0) <= imm;
							tmpImm(word_size-1 downto 8) <= (others => '0');
							op2Sel <= '1';
						end if;
					else
						operand1Addr <= rnMask;
						read1 <= '1';
						rotateOut <= rsRot;
						op2Sel <= '1';
						tmpImm (7 downto 0) <= imm;
						tmpImm (word_size-1 downto 8) <= (others => '0'); 
					end if;
					
				when ls_r => 
					if (someBit /= '0') then --prekid
					else
						read1 <= '1';
						read2 <= '1';
						operand1Addr <= rnMask;
						operand2Addr <= rm;
						if (pBit='1') then isLoad <='1';
						else isStore <='1';
						end if;
						--shiftAmount vec ima;
					end if;
					
				when ls_i =>
					-- videti da li je oznacena vrednost
					read1 <= '1';
					operand1Addr <= rnMask;
					if (pBit='1') then isLoad <='1';
					else isStore <='1';
					end if;
					op2Sel <= '1';
					tmpImm(11 downto 0) <= loadImm;
					tmpImm(31 downto 12) <= (others => '0');
				
				when br => 
					isBranch <= '1';	
					if (lsBit = '1') then 
						link <= '1';
					end if;
				
				when swi_s =>
					if (pBit = '0') then 
						stop <= '1';
					else
					end if;
			end case;
		src1 <= operand1Addr;
		src2 <= operand2Addr;
		dst <= rd;
	--end if;
end if;


--muxOp1: mux2 port map (value0 => regOp1, value1 => , value => operand1, value_selector => op1Sel);
muxOp2: mux2 port map (value0 => regOp2, value1 => tmpImm, value => operand2, value_selector => op2Sel);  

end process;


end idPhase_behav;

