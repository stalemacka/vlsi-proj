library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity PSR is
port (
data_in: in std_logic_vector(31 downto 0);
data_out: out std_logic_vector(31 downto 0);
psr_in: in std_logic;
mask : in std_logic_vector(31 downto 0);
modeType : in std_logic_vector(1 downto 0) --ako je ssr za koji je mod
);
end PSR;


architecture psr_arch of PSR is
signal currVal : std_logic_vector(31 downto 0);

begin
--mozda staviti clk
process(psr_in)

begin
	if (psr_in = '1') then
		if (modeType = "00") then --cpsr
			currVal <= (currVal and not mask) or (data_in and mask);
		else 
			if (conv_integer(currVal(4 downto 0)) > 2) then --prekid
			else
				currVal <= (currVal and not mask) or (data_in and mask);
			end if;
		end if;
	end if;
end process;

data_out <= currVal; --!!!
end psr_arch;