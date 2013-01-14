library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity adder is
generic (word_size_B : integer :=4);
port (indata : in std_logic_vector(word_size_B*8-1 downto 0);
		result: out std_logic_vector(word_size_B*8-1 downto 0);
		enable: in std_logic);
end adder;


architecture addBehav of adder is

begin
process (enable)
variable tmp : integer;
begin
	if (enable = '1') then
		tmp := conv_integer(indata);
		tmp := tmp + word_size_B;
		result <= std_logic_vector(to_unsigned(tmp, word_size_B*8));
	end if;
end process;
end addBehav;