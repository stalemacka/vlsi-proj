library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.UserConstants.all;


entity MEMoryStage is
	port (
		dBus : inout std_logic_vector(31 downto 0);
		aBus : out std_logic_vector(31 downto 0);
		rdMem, wrMem  : out std_logic;
		
		clk : in std_logic;
		reset : in std_logic;
		stall : in std_logic;
		opcode : in std_logic_vector(3 downto 0);
		opcodeOut : out std_logic_vector(3 downto 0);
		ALUout : in std_logic_vector(31 downto 0);
		regIn  : in std_logic_vector(3 downto 0);
		
		regOut : out std_logic_vector(3 downto 0);
		result : in std_logic_vector(31 downto 0);
		--aluOutWrite : out std_logic_vector(31 downto 0);
		
		load, store, regOp : in std_logic;
		loadOut : out std_logic;
		mem_done : in std_logic;
		dstVal : out std_logic_vector(31 downto 0);
		waitingForMemory : out std_logic
	);
	
end MEMoryStage;


architecture MEMoryStage_behav of MEMoryStage  is
type states is (WORKING, MEMWAITING);


signal waitingMemory, reading, writing : std_logic;
signal state : states;

begin
process(clk)
begin
	if (rising_edge(clk)) then
		if (reset = '1') then
			--isLoad <= '0';
			--isOther <= '0';
			--isHalt <= '0';
			state <= WORKING;
			reading <= '0';
			writing <= '0';
		else 
			case state is
				when WORKING =>
					if (stall = '0' and waitingMemory = '0') then
--			/*rdMem <= 'Z';
--			wrMem <= 'Z';*/
--			isLoad <= '0';
--			isOther <= '0';	
						loadOut <= load;
						opcodeOut <= opcode;
						if (load = '1') then
							regOut <= regIn;
							aBus <= ALUout;
							dBus <= (dBus'range => 'Z');
							rdMem <= '1';
							reading <= '1';
							waitingForMemory <= '1';
							waitingMemory <= '1';
							--wait until mem_done = '1';
							state <= MEMWAITING;							
						elsif (regOp = '1') then
							--aluOutWrite <= ALUout;
							regOut <= regIn;
							dstVal <= ALUout;
						elsif (store = '1') then
							aBus <= ALUout;
							dBus <= result;
							wrMem <= '1';	
							waitingForMemory <= '1';
							waitingMemory <= '1';
							writing <= '1';							
							state <= MEMWAITING;
							--wait until mem_done = '1';
							--waitingForMemory <= '0';
						end if;
					end if;
					
				when MEMWAITING =>
					if (mem_done = '1' and stall = '0') then --!!! videti da li je ovaj stall neophodno
						if (reading = '1') then
							dstVal <= dBus;
							reading <= '0';
							rdMem <= 'Z';
						else	
							writing <= '0';
							wrMem <= 'Z';
						end if;
							waitingForMemory <= '0';
							waitingMemory <= '0';
							state <= WORKING;						
					end if;
			end case;
		end if; --reset
	end if;
--			/*
--				when haltOpCode =>
--					isHalt <= '1';
--				when others =>
--					null;
--			end case;
--		end if;*/
end process;

end MEMoryStage_behav;