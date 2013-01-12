library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.UserConstants.all;


entity MEMoryStage is
	port (
		dBus : out std_logic_vector(31 downto 0);
		aBus : out std_logic_vector(31 downto 0);
		rdMem, wrMem  : out std_logic;
		
		clk : in std_logic;
		reset : in std_logic;
		stall : in std_logic;
		
		opcode : in std_logic_vector(3 downto 0);
		--value : in std_logic_vector(31 downto 0);
		ALUout : in std_logic_vector(31 downto 0);
		regIn  : in std_logic_vector(4 downto 0);
		
		isLoad : out std_logic;
		isOther : out std_logic;
		regOut : out std_logic_vector(4 downto 0);
		result  in std_logic_vector(31 downto 0);
		--aluOutWrite : out std_logic_vector(31 downto 0);
		
		isHalt : out std_logic;
		load, store, regOp : in std_logic;
		mem_done : in std_logic;
		dstVal : out std_logic_vector(31 downto 0)
	);
	
end MEMoryStage;


architecture MEMoryStage of MEMoryStage_behav is
begin
process(clk)
begin
	if (rising_edge(clk)) then
		if (reset = '1') then
			isLoad <= '0';
			isOther <= '0';
			isHalt <= '0';
		elsif (stall = '0') then
			/*rdMem <= 'Z';
			wrMem <= 'Z';*/
			isLoad <= '0';
			isOther <= '0';			
			/* 
			case opcode is
				when loadOpCode | andOpCode | eorOpCode | subOpCode | rsbOpCode | addOpCode | adcOpCode | sbcOpCode | rscOpCode
					| orrOpCode | movOpCode | branchOpCode | mvnOpCode =>*/
			if (load = '1') then
				regOut <= regIn;
				aBus <= ALUout;
				dBus <= (dBus'range => 'Z');
				rdMem <= '1';
				wait until mem_done = '1';
				dstVal <= dBus;
			elsif (regOp = '1') then
				--aluOutWrite <= ALUout;
				regOut <= regIn;
				dstVal <= ALUout;
			elsif (store = '1') then
				aBus <= ALUout;
				dBus <= result;
				wrMem <= '1';	
				wait until mem_done = '1';
		end if;
	end if;
			/*
				when haltOpCode =>
					isHalt <= '1';
				when others =>
					null;
			end case;
		end if;*/
end process;

process (mem_done)
begin
	rdMem <= '0';
	wrMem <= '0';
end process;

end MEMoryStage_behav;