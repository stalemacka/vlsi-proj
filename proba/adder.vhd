 library ieee;
use work.all;
use ieee.std_logic_1164.all;


entity adder is
generic (word_size_B : integer :=4);
port (indata : in std_logic_vector(word_size_B*8-1 downto 0);
		result: out std_logic_vector(word_size_B*8-1 downto 0));
end adder;


architecture addBehav of adder is
begin
variable tmp : integer;
begin
	tmp := conv_integer(indata);
	tmp := tmp + word_size_B;
	result <= std_logic_vector(to_unsigned(indata, word_size_B*8)));

end addBehav;