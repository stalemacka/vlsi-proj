library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.userConstants.all;



entity condCalc is
--generic (word_size: integer :=32);
port (condField : in std_logic_vector(3 downto 0);
		flags : in std_logic_vector(3 downto 0);--, val2 : in std_logic_vector(word_size-1 downto 0);
		--mode : in std_logic_vector(4 downto 0);
		condVal : out std_logic);
end condCalc;

architecture condCalc_behav of condCalc is
--signal flags: std_logic_vector(3 downto 0); - ako bude trebalo vise stat. registara
	--condVal <= '0';
--	flags 
begin
	with condField select
		condVal <= flags(2) when eq, 
					  not flags(2) when ne, 
					  flags(1) when cs,
					  not flags(1) when cc,
					  flags(3) when mi,
					  not flags(3) when pl,
					  flags(0) when vs,
					  not flags(0) when vc,
					  flags(1) and not flags(2) when hi,
					  not flags(1) or flags(2) when ls,
					  not (flags(3) xor flags(0)) when ge,--(flags(3) and flags(0)) or (not flags(3) and not flags(0));
					  flags(3) xor flags(0) when lt, --(flags(3) and not flags(0)) or (not flags(3) and flags(0));
					  not flags(2) and not (flags(3) xor flags(0)) when gt, -- and (flags(3) and flags(0)) or (not flags(3) and not flags(0));
					  flags(2) and (flags(3) xor flags(0)) when le, --and (flags(3) and not flags(0)) or (not flags(3) and flags(0));
					  '1' when al,
					  '0'	when others; --videti da li ovde gresku neku ili tako nesto
end condCalc_behav;
