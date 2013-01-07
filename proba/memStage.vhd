library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.UserConstants.all;


entity MEMoryStage is
	port (
		dBus : out std_logic_vector(31 downto 0);
		aBus : out std_logic_vector(31 downto 0);
		mIO  : out std_logic;
		
		clk : in std_logic;
		reset : in std_logic;
		stall : in std_logic;
		
		opcode : in std_logic_vector(3 downto 0);
		value : in std_logic_vector(31 downto 0);
		ALUout : in std_logic_vector(31 downto 0);
		regIn  : in reg_inc_dec;
		
		isLoad : out std_logic;
		isOther : out std_logic;
		regOut : out reg_inc_dec;
		aluOutWrite : out std_logic_vector(31 downto 0);
		
		isHalt : out std_logic
	);
	
end entity MEMoryStage;


architecture MEMoryStage of MEMoryStage is
begin
process is
begin
		wait until clk = '1';
		if (reset = '1') then
			isLoad <= '0';
			isOther <= '0';
			isHalt <= '0';
		elsif (stall = '0') then
			mIO <= 'Z';
			isLoad <= '0';
			isOther <= '0';
			
			 
			case opcode is
				when loadOpCode | andOpCode | eorOpCode | subOpCode | rsbOpCode | addOpCode | adcOpCode | sbcOpCode | rscOpCode | tstOpCode | teqOpCode | cmpOpCode | cmnOpCode | orrOpCode | movOpCode | branchOpCode | mvnOpCode =>
					regOut <= regIn;
					if (opcode = loadOpCode) then
						aBus <= ALUout;
						dBus <= (dBus'range => 'Z');
						mIO <= '0';
						isLoad <= '1';
					else
						aluOutWrite <= ALUout;
						isOther <= '1';
					end if;
				
				when storeOpCode =>
					aBus <= ALUout;
					dBus <= value;
					mIO <= '1';
				when haltOpCode =>
					isHalt <= '1';
				when others =>
					null;
			end case;
		end if;
end process;
end architecture MEMoryStage;