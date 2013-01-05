library ieee;
use work.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.userConstants.all;

--uvesti u odnosu na mod dodatne registre
entity regFile is
generic ( 
				 num_reg_bits : integer := 5;
				 reg_size : integer := 32;
				 Tpd : Time := unit_delay
				 );
				 
	port ( -- MYB H i L
				clk : in std_logic;
				mode : in std_logic_vector(4 downto 0);
				reset : in std_logic;
				read_addr1 : in std_logic_vector(num_reg_bits - 1 downto 0);
				read_addr2 : in std_logic_vector(num_reg_bits - 1 downto 0);
				read_4shift : in std_logic_vector(num_reg_bits - 1 downto 0);
				write_addr : in std_logic_vector(num_reg_bits - 1 downto 0);
				outVal1 : out std_logic_vector(reg_size - 1 downto 0);				
				outVal2 : out std_logic_vector(reg_size - 1 downto 0);	
				outShiftVal : out std_logic_vector(7 downto 0);
				inVal : in std_logic_vector(reg_size - 1 downto 0);
				wEn : std_logic;
				r1En, r2En, rshiftEn : in std_logic
			);	
end regFile;


architecture regFile_behav of regFile is
	subtype reg is std_logic_vector(reg_size - 1 downto 0);
	type reg_array is array(0 to 2**num_reg_bits - 1) of reg;
	
	signal registers : reg_array;
	
begin
		
write: process(clk)			
	begin
		if rising_edge(clk) then
			if (wEn = '1') then
				registers(conv_integer(write_addr)) <= inVal;	
			end if;	
	end if;	
end process write;
	
read1: process(clk, r1En)
	begin	
		if rising_edge(clk) then
			if (r1En = '1') then
				outVal1 <= registers(conv_integer(read_addr1));
			end if;
		end if;
	end process read1;
	
read2: process(clk, r2En) --mozda dodati adresu
	begin	
		if rising_edge(clk) then
			if (r2En = '1') then
				outVal2 <= registers(conv_integer(read_addr2));
			end if;
		end if;
	end process read2;

readShift: process(clk, rshiftEn) --mozda dodati adresu
	begin	
		if rising_edge(clk) then
			if (rshiftEn = '1') then
				outShiftVal <= registers(conv_integer(read_4shift))(7 downto 0);
			end if;
		end if;
	end process readShift;
-- mozda staviti citanje van procesa
end regFile_behav;