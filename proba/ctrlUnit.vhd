library ieee;
use work.all;
use work.userConstants.all;
use ieee.std_logic_1164.all;


entity ctrlUnit is
port (
	clk : in std_logic;
	reset : in std_logic;
	opcodeEx : in std_logic_vector(3 downto 0);
	opcodeId : in std_logic_vector(3 downto 0);
	src1Id, src2Id, shiftId, dstEx : in std_logic_vector(3 downto 0);
	exeLoad : in std_logic;
	cstReg, stReg : in std_logic;
	stallEx, stallId, stallIf, stallMem : out std_logic;
	flushEx, flushId : out std_logic;
	branchTaken : in std_logic;
	memWaitingIf, memWaitingMem: in std_logic
);
end ctrlUnit;



architecture ctrlUnit_behav of ctrlUnit is
type states is (WORKING, IFWAITING, MEMWAITING);

signal state : states;

begin

process (clk)
begin
	
	if (rising_edge(clk)) then
		if (reset = '1') then
			stallEx <= '0';
			stallId <= '0';
			stallIf <= '0';
			stallMem <= '0';
			flushEx <= '0';
			flushId <= '0';
		else
			case state is
				when WORKING =>
					if (memWaitingMem = '1') then
						stallMem <= '1';
						stallEx <= '1';
						stallId <= '1';
						stallIf <= '1';
						state <= MEMWAITING;
					elsif (memWaitingIf = '0') then
						stallIf <= '1';
					else
						stallEx <= '0';
						stallId <= '0';
						stallIf <= '0';
						stallMem <= '0';
						flushEx <= '0';
						flushId <= '0';			
					end if;
				
				when MEMWAITING =>
					if (memWaitingMem = '0') then
						stallMem <= '0';
						stallEx <= '0';
						stallId <= '0';
						stallIf <= '0';
						state <= WORKING;
					end if;
					
				when IFWAITING => 
					if (memWaitingIf = '0') then
						stallIf <= '0';
					end if;
			end case;
			
			if (exeLoad = '1') then --vrv dodati uslove sa stall !!!
							case opcodeId is
								when andOpCode | eorOpCode | subOpCode | rsbOpCode | addOpCode | adcOpCode |  sbcOpCode
								| rscOpCode | orrOpCode | bicOpCode | movOpCode | mvnOpCode =>
									if (src1Id = dstEx or src2Id = dstEx or shiftId = dstEx) then
										stallId <= '1';
										stallIf <= '1';
										flushEx <= '1'; --treba prakticno staviti noop u exe
									end if;
								when tstOpCode | teqOpCode | cmpOpCode | cmnOpCode =>
									if ((stReg = '0' and cstReg = '0') and (src1Id = dstEx or src2Id = dstEx or shiftId = dstEx)) then
										stallId <= '1';
										stallIf <= '1';
										flushEx <= '1'; --treba prakticno staviti noop u exe
									end if;
							end case;	
			elsif (branchTaken = '1') then --ovo moze da se desi samo ako je branch u exe vazi, pa zato elsif
				flushId <= '1';
				flushEx <= '1';
			end if;
		end if;
	end if;	
end process;



end ctrlUnit_behav;