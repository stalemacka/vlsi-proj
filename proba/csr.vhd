library iee;
use ieee.std_logic_1164.all;

entity CSR is
port (
data_in: in std_logic_vector(31 downto 0);
data_out: out std_logic_vector(31 downto 0);
csr_in: in std_logic);
end CSR;


architecture csr_arch of csr is
begin
--mozda staviti clk
if (csr_in) then
	data_out <= data_in;
end if;
end csr_arch