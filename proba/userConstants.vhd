library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package UserConstants is

-- opcodes for instructions
	constant andOpCode	:	std_logic_vector(3 downto 0) :=	"0000";
	constant eorOpCode	: 	std_logic_vector(3 downto 0) := "0001";
	constant subOpCode	:	std_logic_vector(3 downto 0) := "0010";
	constant rsbOpCode	:	std_logic_vector(3 downto 0) := "0011";
	constant addOpCode	:	std_logic_vector(3 downto 0) := "0100";
	constant adcOpCode	:	std_logic_vector(3 downto 0) := "0101";
	constant sbcOpCode	: 	std_logic_vector(3 downto 0) := "0110";
	constant rscOpCode	:	std_logic_vector(3 downto 0) := "0111";
	constant tstOpCode	:	std_logic_vector(3 downto 0) := "1000";
	constant teqOpCode	:	std_logic_vector(3 downto 0) := "1001";
	constant cmpOpCode	:	std_logic_vector(3 downto 0) := "1010";
	constant cmnOpCode	:	std_logic_vector(3 downto 0) := "1011";
	constant orrOpCode	:	std_logic_vector(3 downto 0) := "1100";
	constant movOpCode	:	std_logic_vector(3 downto 0) := "1101";
	constant bicOpCode	:	std_logic_vector(3 downto 0) := "1110";
	constant mvnOpCode	:	std_logic_vector(3 downto 0) := "1111";

	constant jmpOpCode	: 	std_logic_vector(3 downto 0) := "";
	constant jsrOpCode  : 	std_logic_vector(3 downto 0) := "";
	constant rtsOpCode	: 	std_logic_vector(3 downto 0) := "";
	constant branchOpCode : std_logic_vector(3 downto 0) := "";
	constant branchAndLinkOpCode : std_logic_vector(3 downto 0) := "";

	-- shift
	constant lsl	:	std_logic_vector(1 downto 0) := "00";
	constant lsr	: 	std_logic_vector(1 downto 0) := "01";
	constant asr	:	std_logic_vector(1 downto 0) := "10";
	constant rorS	:	std_logic_vector(1 downto 0) := "11";



	-- branch
	
	-- jmp
	
	--load/store/halt
	constant loadOpCode : std_logic_vector(3 downto 0) := "";
	constant storeOpCode: std_logic_vector(3 downto 0) := "";
	constant pushOpCode : std_logic_vector(3 downto 0) := "";
	constant popOpCode	: std_logic_vector(3 downto 0) := "";
	constant nopOpCode  : std_logic_vector(3 downto 0) := "";
	constant haltOpCode : std_logic_vector(3 downto 0) := "";
	-- conditions

	constant eq		:	std_logic_vector(3 downto 0) := "0000";
	constant ne		:	std_logic_vector(3 downto 0) := "0001";
	constant cs		:	std_logic_vector(3 downto 0) := "0010";
	constant cc		:	std_logic_vector(3 downto 0) := "0011";
	constant mi		:	std_logic_vector(3 downto 0) := "0100";
	constant pl		:	std_logic_vector(3 downto 0) := "0101";
	constant vs		:	std_logic_vector(3 downto 0) := "0110";
	constant vc		:	std_logic_vector(3 downto 0) := "0111";
	constant hi		:	std_logic_vector(3 downto 0) := "1000";
	constant ls		:	std_logic_vector(3 downto 0) := "1001";
	constant ge		:	std_logic_vector(3 downto 0) := "1010";
	constant lt		:	std_logic_vector(3 downto 0) := "1011";
	constant gt		:	std_logic_vector(3 downto 0) := "1100";
	constant le		:	std_logic_vector(3 downto 0) := "1101";
	constant al		:	std_logic_vector(3 downto 0) := "1110";
	constant err 	:  std_logic_vector(3 downto 0) := "1111";
 	
	--types
	
	constant dpis_rs_srr_sr : std_logic_vector(2 downto 0) := "000";
	constant dp_sr_i : std_logic_vector(2 downto 0) := "001";
	constant ls_r : std_logic_vector(2 downto 0) := "011";
	constant ls_i : std_logic_vector(2 downto 0) := "010";
	constant br : std_logic_vector(2 downto 0) := "101";
	constant swi_s : std_logic_vector(2 downto 0) := "111";

	
	--razne constant
	constant commonRegs : integer := 8;
	constant exclusiveRegs : integer := 7;

end UserConstants;