library ieee;
use work.all;
use ieee.std_logic_1164.all;
use work.UserConstants.all;


entity IDphase is
port (clk: std_logic;
		csr_flags: in std_logic_vector(3 downto 0);
		
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
		
		aluOp : out std_logic_vector(3 downto 0);
		operand1 : out std_logic_vector(word_size-1 downto 0);
		operand2 : out std_logic_vector(word_size-1 downto 0);
		isCmp : out std_logic;
		shiftType : out std_logic_vector(1 downto 0);
		shiftOut : out std_logic_vector(4 downto 0);
		rotateOut : out std_logic_vector(3 downto 0)
		);
		
end IDphase;

architecture idPhase_behav of IDphase is

component regFile
generic ( 
				 num_reg_bits : integer := 5;
				 reg_size : integer := 32;
				 Tpd : Time := unit_delay
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

component condCalc
port (condField : in std_logic_vector(3 downto 0);
		flags : in std_logic_vector(3 downto 0);--, val2 : in std_logic_vector(word_size-1 downto 0);
		condVal : out std_logic);
end component;

component mux2 is
	generic (
		word_size : integer := 32;
		Tpd  : Time := 5ns  --any value 
	);
	port (
		value1, value0 : in std_logic_vector(word_size-1 downto 0);
		value : out std_logic_vector(word_size-1 downto 0);
		value_selector : in bit
	);
end component;


signal condVal: std_logic;
signal operand1Addr, operand2Addr, shiftAddr : std_logic_vector(num_reg_bits -1 downto 0);
signal shift_intern: std_logic_vector(4 downto 0);
signal regShift: std_logic_vector(7 downto 0);
signal read1, read2, readShift : std_logic;
signal regOp2: std_logic_vector(reg_size-1 downto 0);
signal op2Sel: std_logic;
--signal imm_intern

begin

condition: condCalc port map (condField => cond, flags => csr_flags,
		condVal => condVal);
registers: regFile port map (
		clk => clk,	reset => reset, read_addr1 =>operand1Addr, read_addr2 =>operand2Addr, read_4shift=> shiftAddr,
		write_addr => , outVal1 => operand1, outVal2 => operand2, outShiftVal => regShift,
		inVal => , wEn => , r1En => read1, r2En => read2, rshiftEn=> readShift
); --zanemarice se operand2 gde nije potreban

process (clk)
begin	--postaviti sve na nule
	if (rising_edge(clk)) then
		if (condVal = '1') then --inace ubaciti nop
			shiftType <= shift;
			shiftOut <= "00000";
			isCmp <= '0';
			case typeI is		
				when dpis_rs_srr_sr => 
					if (pBit = '1' and uBit = '0') then 
						if (lsBit = '1') then
							--isCmp <= '1'; --videti da li treba
							operand1Addr <= rnMask;
							operand2Addr <= rm;
							read1 <= '1';
							read2 <= '1';
							if (someBit = '1') then 
								if (checkBit /= '0') then --prekid
								else 
									readShift <= '1';
									shiftAddr <= rsRot;
									if (conv_integer(regShift) < 32) then shiftOut <= regShift(4 downto 0);
									else shiftOut <= "00000"; -- videti sta sa carry
									end if;
								end if;
							end if;
						else 
							--ovde treba za pristup csr-u
						end if;
					else --nisu one sto se 'preklapaju', neke od dp_is si
						 operand1Addr <= rnMask;
						 operand2Addr <= rm;
						 read1 <= '1';
						 read2 <= '1';
						 if (someBit = '1') then 
							if (checkBit /= '0') then --prekid
							else 
								readShift <= '1';
								shiftAddr <= rsRot;
								if (conv_integer(regShift) < 32) then shiftOut <= regShift(4 downto 0);
								else shiftOut <= "00000"; -- videti sta sa carry
								end if;	
							end if;
						 end if;
					end if;
				
				when dp_sr_i => 
					if (pBit = '1' and uBit = '0') then 
						if (lsBit = '1') then							
							operand1Addr <= rnMask;
							read1 <= '1';
							rotateOut <= rsRot;
							op2Sel <= '1';							
						else --pristup csru
						end if;
					else
						operand1Addr <= rnMask;
						read1 <= '1';
						rotateOut <= rsRot;
						--op2Sel <= '1';
					end if;
					
				when ls_r => 
					if (someBit /= '0') then --prekid
					else
						read1 <= '1';
						read2 <= '1';
						operand1Addr <= rnMask;
						operand2Addr <= rm;
						--shiftAmount vec ima;
					end if;
					
				when ls_i =>
					-- videti da li je oznacena vrednost
					read1 <= '1';
					operand1Addr <= rnMask;
					--op2Sel <= '1';
				
				when br =>
						
						
						
			end case;
	end if;
end if;


--muxOp1: mux2 port map (value0 => regOp1, value1 => , value => operand1, value_selector => op1Sel);
--muxOp2: mux2 port map (value0 => regOp2, value1 => imm, value => operand2, value_selector => op2Sel);  

end process;


end idPhase_behav;

