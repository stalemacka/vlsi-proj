library ieee;
use work.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.userConstants.all;

--uvesti u odnosu na mod dodatne registre
-- za pc posebno izvesti neki signal
entity regFile is
generic ( 
				 num_reg_bits : integer := 5;
				 reg_size : integer := 32
				-- Tpd : Time := unit_delay
				 );
				 
	port ( -- MYB H i L
				clk : in std_logic;
				mode : in std_logic_vector(4 downto 0);
				reset : in std_logic;
				read_addr1 : in std_logic_vector(num_reg_bits - 1 downto 0);
				read_addr2 : in std_logic_vector(num_reg_bits - 1 downto 0);
				read_4shift : in std_logic_vector(num_reg_bits - 1 downto 0);
				write_addr : in std_logic_vector(num_reg_bits - 1 downto 0);
			--	pcVal : in std_logic_vector(reg_size-1 downto 0);
				
				outVal1 : out std_logic_vector(reg_size - 1 downto 0);				
				outVal2 : out std_logic_vector(reg_size - 1 downto 0);	
				outShiftVal : out std_logic_vector(4 downto 0);
				inVal : in std_logic_vector(reg_size - 1 downto 0);
				wEn : std_logic;
				r1En, r2En, rshiftEn : in std_logic
			);	
end regFile;


architecture regFile_behav of regFile is
	subtype reg is std_logic_vector(reg_size - 1 downto 0);
	type reg_arrayC is array(0 to commonRegs-1) of reg;
	--type reg_arrayE is array(0 to exclusiveRegs-1) of reg;
	type all_exclusive is array (0 to 2, 0 to exclusiveRegs - 1) of reg;
	
	signal registersShared : reg_arrayC;
	signal registersExcl : all_exclusive;
	
	variable numReg, numReg2, numRegS : integer;
	
begin
		
write: process(clk)			
	begin
		if rising_edge(clk) then
			if (wEn = '1') then
				numReg := conv_integer(read_addr1);
				if (numReg < 8) then
					registersShared(conv_integer(write_addr)) <= inVal;
				elsif (numReg < 15) then
					registersExcl(conv_integer(mode), numReg-commonRegs) <= inVal;
				end if;
					
			end if;	
	end if;	
end process write;
	
read1: process(clk, r1En)
	begin	
		if rising_edge(clk) then
			if (r1En = '1') then
				numReg := conv_integer(read_addr1);
				if (numReg < 8) then
					outVal1 <= registersShared(numReg);
				elsif (numReg < 15) then
					outVal1 <= registersExcl(conv_integer(mode), numReg-commonRegs);
				end if;
			end if;
		end if;
	end process read1;
	
read2: process(clk, r2En) --mozda dodati adresu
	begin	
		if rising_edge(clk) then
			if (r2En = '1') then
				numReg2 := conv_integer(read_addr2);
				if (numReg2 < 8) then
					outVal2 <= registersShared(numReg2);
				elsif (numReg2 < 15) then
					outVal2 <= registersExcl(conv_integer(mode), numReg2-commonRegs);
				end if;
			end if;
		end if;
	end process read2;

readShift: process(clk, rshiftEn) --mozda dodati adresu
	variable regVal: natural;
	begin	
		if rising_edge(clk) then --ovo vrv izbaciti
			if (rshiftEn = '1') then
				numRegS := conv_integer(read_4shift);
				if (numRegS < 8) then
					regVal := conv_integer(registersShared(numRegS)(4 downto 0));
					if (regVal < 32) then 
						outShiftVal <= registersShared(numRegS)(4 downto 0); --u specifikaciji stoji
					else
						outShiftVal <= (others => '0');
					end if;
				elsif (numRegS < 15) then
					regVal := conv_integer(registersExcl(conv_integer(mode), numRegS-commonRegs)(4 downto 0));
					if (regVal < 32) then 
						outShiftVal <= registersExcl(conv_integer(mode), numRegS-commonRegs)(4 downto 0);
					else
						outShiftVal <= (others => '0');
					end if;
				end if;
			end if;
		end if;
	end process readShift;
-- mozda staviti citanje van procesa
end regFile_behav;