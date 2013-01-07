library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity adder is
generic (word_size_B : integer :=4);
port (indata : in std_logic_vector(word_size_B*8-1 downto 0);
		result: out std_logic_vector(word_size_B*8-1 downto 0));
end adder;


architecture addBehav of adder is
variable tmp : integer;

begin
process
begin
	tmp := conv_integer(indata);
	tmp := tmp + word_size_B;
	result <= std_logic_vector(to_unsigned(tmp, word_size_B*8));
end process;
end addBehav;