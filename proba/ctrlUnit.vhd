library ieee;
use work.all;
use work.userConstants.all;
use ieee.std_logic_1164.all;


entity ctrlUnit is
port (
	opcodeEx : in std_logic_vector(3 downto 0);
	opcodeId : in std_logic_vector(3 downto 0);
	src1Id, src2Id, shiftId, dstEx : in std_logic_vector(num_reg_bits - 1 downto 0);
	exeLoad : in std_logic;
	isCmp : in std_logic;
	stallEx, stallId, stallIf : out std_logic;
	flushEx, flushId, flushIf : out std_logic
);
end ctrlUnit;



architecture ctrlUnit_behav is 

begin

process (clk)
begin
	
	if (rising_edge(clk)) then
		stallEx <= '0';
		stallId <= '0';
		stallIf <= '0';
		flushEx <= '0';
		flushId <= '0';
		flushIf <= '0';
		
		if (exeLoad = '1') then
			case opcodeId is
				when andOpCode | eorOpCode | subOpCode | rsbOpCode | addOpCode | adcOpCode |  sbcOpCode
				| rscOpCode | orrOpCode | bicOpCode | movOpCode | mvnOpCode =>
					if (src1Id = dstEx or src2Id = dstEx or shiftId = dstEx) then
						stallId <= '1';
						stallIf <= '1';
						flushEx <= '1'; --treba prakticno staviti noop u exe
					end if;
				when tstOpCode | teqOpCode | cmpOpCode | cmnOpCode =>
					if ((isCmp = '1') and (src1Id = dstEx or src2Id = dstEx or shiftId = dstEx)) then
						stallId <= '1';
						stallIf <= '1';
						flushEx <= '1'; --treba prakticno staviti noop u exe
					end if;
			end case;		
		
		end if;
	end if;	
end ctrlUnit_behav;