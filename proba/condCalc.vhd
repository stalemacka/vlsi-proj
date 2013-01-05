library ieee;
use work.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;



entity condCalc is
--generic (word_size: integer :=32);
port (condField : in std_logic_vector(3 downto 0);
		flags : in std_logic_vector(3 downto 0);--, val2 : in std_logic_vector(word_size-1 downto 0);
		--mode : in std_logic_vector(4 downto 0);
		condVal : out std_logic);
end condCalc;

architecture condCalc_behav of condCalc is
--signal flags: std_logic_vector(3 downto 0); - ako bude trebalo vise stat. registara

begin
process (condField)
begin
	condVal <= '0';
--	flags 
	case condField is
		when eq => condVal <= flags(2);	
		when ne => condVal <= not flags(2);
		when cs => condVal <= flags(1);
		when cc => condVal <= not flags(1);
		when mi => condVal <= flags(3);
		when pl => condVal <= not flags(3);
		when vs => condVal <= flags(0);
		when vc => condVal <= not flags(0);
		when hi => condVal <= flags(1) and not flags(2);
		when ls => condVal <= not flags(1) or flags(2);
		when ge => condVal <= (flags(3) = flags(0));--(flags(3) and flags(0)) or (not flags(3) and not flags(0));
		when lt => condVal <= (flags(3) /= flags(0)); --(flags(3) and not flags(0)) or (not flags(3) and flags(0));
		when gt => condVal <= not flags(2) and (flags(3) = flags(0));-- and (flags(3) and flags(0)) or (not flags(3) and not flags(0));
		when le => condVal <= flags(2) and (flags(3) /= flags(0));--and (flags(3) and not flags(0)) or (not flags(3) and flags(0));
		when al => condVal <= '1';
		when others ; --ili dodeliti 0 ako ne moze
	end case;
end process;
end condCalc_behav;
