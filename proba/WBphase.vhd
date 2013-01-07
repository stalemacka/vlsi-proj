library ieee;
use ieee.std_logic_1164.all;
use work.UserConstants.all;


entity WBphase is
generic (num_reg_bits : natural :=5;
			word_size: natural :=32);
port (
	clk : in std_logic;
	regDestAddr : in std_logic_vector(num_reg_bits-1 downto 0);
	loadValue : in std_logic_vector(word_size -1 downto 0); --na ovo ce se povezati dbus ka kesu
	exeResult : in std_logic_vector(word_size -1 downto 0);
	opcode : in std_logic_vector(3 downto 0);
	loadInstr : in std_logic;
	
	resultValue : out std_logic_vector(word_size-1 downto 0);
	wbWrite : out std_logic;
	regAddr : out std_logic_vector(num_reg_bits-1 downto 0)
);

end WBphase;

architecture wbPhase_behav of WBphase is

begin

process(clk)
begin
	if (rising_edge(clk)) then
		wbWrite <= '0';
		if (loadInstr = '1') then
			wbWrite <= '1';
			regAddr <= regDestAddr;
			resultValue <= loadValue;
		else
			case opcode is
				when andOpCode | eorOpCode | subOpCode | rsbOpCode | addOpCode | adcOpCode |  sbcOpCode
					| rscOpCode | orrOpCode | bicOpCode | movOpCode | mvnOpCode =>
						wbWrite <= '1';
						regAddr <= regDestAddr;
						resultValue <= exeResult;
						
			end case;
		end if;
					
	end if;	
	
end process;
	
end wbPhase_behav;