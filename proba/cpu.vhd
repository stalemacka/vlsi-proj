library ieee;
use ieee.std_logic_1164.all;

entity cpu is
port(
	clk : in std_logic;
	reset : in std_logic;
	
	addrToInstCache : out std_logic_vector(31 downto 0);
	dataFromInstCache : in std_logic_vector(31 downto 0);
	rdInstr : out std_logic;
	
	addrToDataCache : out std_logic_vector(31 downto 0);
	dataToFromDataCache : inout std_logic_vector(31 downto 0);
	rdData : out std_logic;
	wrData : out std_logic
	);
end cpu;

architecture cpu_behav of cpu is

component IFphase is
generic ( --Tpd : Time := unit_delay;
			word_size : natural := 32
			);
			
port (clk: in std_logic;
		reset: in std_logic;
		stall: in std_logic;
		
		pcBranch : in std_logic_vector(word_size-1 downto 0);
		isBranch: in std_logic;
		rdMem: out std_logic;
		pc_out: out std_logic_vector(word_size-1 downto 0);
		busToCache : out std_logic_vector(word_size-1 downto 0);
		busFromCache : in std_logic_vector(word_size-1 downto 0);
		mem_done : in std_logic;
		
		cond : out std_logic_vector(3 downto 0); -- staviti genericki
		typeI : out std_logic_vector(2 downto 0);
		opcode : out std_logic_vector(3 downto 0); -- staviti genericki
		lsBit, someBit, checkBit: out std_logic;
		rnMask, rd, rsRot, rm : out std_logic_vector(3 downto 0);
		imm: out std_logic_vector(7 downto 0);
		shiftA : out std_logic_vector(4 downto 0);
		shift : out std_logic_vector(1 downto 0);
		offIntNum : out std_logic_vector(23 downto 0);
		loadImm : out std_logic_vector(11 downto 0);
		waitingForMemory : out std_logic
		);
		
end component;

component IDphase is
generic (num_reg_bits : natural :=4;
			word_size : natural :=32;
			reg_size : natural :=32);
port (clk: std_logic;
		reset: std_logic;
		pc_in: std_logic_vector(word_size-1 downto 0);
		flush, stall : in std_logic;
		
		cond : in std_logic_vector(3 downto 0); -- staviti genericki
		typeI : in std_logic_vector(2 downto 0);
		opcode : in std_logic_vector(3 downto 0); -- staviti genericki
		lsBit, someBit, checkBit: in std_logic;
		rnMask, rd, rsRot, rm : in std_logic_vector(3 downto 0);
		imm: in std_logic_vector(7 downto 0);
		shiftA : in std_logic_vector(4 downto 0);
		shift : in std_logic_vector(1 downto 0);
		offIntNum : in std_logic_vector(23 downto 0);	
		loadImm : in std_logic_vector(11 downto 0);
		writeRegAddr: in std_logic_vector(num_reg_bits-1 downto 0);
		writeRegData: in std_logic_vector(word_size-1 downto 0);
		wrReg: in std_logic;
		condOut : out std_logic_vector(3 downto 0);
		typeIOut : out std_logic_vector(2 downto 0);
		opcodeOut : out std_logic_vector(3 downto 0);
		immValToRot : out std_logic_vector(31 downto 0);
		operand1 : out std_logic_vector(word_size-1 downto 0);
		operand2 : out std_logic_vector(word_size-1 downto 0);
		isLoad, isStore, isCmp, isLink, isStop : out std_logic;
		shiftType : out std_logic_vector(1 downto 0);
		shiftOut : out std_logic_vector(7 downto 0);
		rotateOut : out std_logic_vector(3 downto 0);
		
		src1Addr, src2Addr, dstAddr : out std_logic_vector(num_reg_bits-1 downto 0);
		shouldShift: out std_logic;
		stReg, cstReg : out std_logic
		);
		
end component;

component EXecStage is
	port(
		clk : in std_logic;
		reset	: in std_logic;
		stall	: in std_logic;
		flush	: in std_logic;
		
		currentPc : in std_logic_vector(31 downto 0);
		cond : in std_logic_vector(3 downto 0);
		opcode : in std_logic_vector(3 downto 0);
		isLoad, isStore, linkS, stReg, cstReg, stop : in std_logic;
		imm : in std_logic_vector(31 downto 0);
		A : in std_logic_vector(31 downto 0);
		B : in std_logic_vector(31 downto 0);		
		src1, src2, dst, shReg: in std_logic_vector(3 downto 0);		
		rdsValue	: out std_logic_vector(31 downto 0);
		newPc	: out std_logic_vector(31 downto 0);
		opcodeOut : out std_logic_vector(3 downto 0);
		memPh_dstAddr: in std_logic_vector(3 downto 0);
		memPh_dstVal: in std_logic_vector(31 downto 0);
		
		shiftVal : in std_logic_vector(7 downto 0);
		shiftType : in std_logic_vector(1 downto 0);
		shouldShift: in std_logic;
		
		rotate : in std_logic_vector(3 downto 0);
		branchTaken : out std_logic;
		instType : in std_logic_vector(2 downto 0);
		loadOut, storeOut, regOp : out std_logic;
		interrupt : out std_logic;
		dstAddr : out std_logic_vector(3 downto 0);
		dstRegResult : out std_logic_vector(31 downto 0);
		stopCpu : out std_logic
	);	
end component;

component MEMoryStage is
	port (
		dBus : inout std_logic_vector(31 downto 0);
		aBus : out std_logic_vector(31 downto 0);
		rdMem, wrMem  : out std_logic;
		
		clk : in std_logic;
		reset : in std_logic;
		stall : in std_logic;
		
		opcode : in std_logic_vector(3 downto 0);
		opcodeOut : out std_logic_vector(3 downto 0);
		ALUout : in std_logic_vector(31 downto 0);
		regIn  : in std_logic_vector(3 downto 0);
		
		regOut : out std_logic_vector(3 downto 0);
		result : in std_logic_vector(31 downto 0);
		load, store, regOp : in std_logic;
		loadOut : out std_logic;
		mem_done : in std_logic;
		dstVal : out std_logic_vector(31 downto 0);
		waitingForMemory : out std_logic
	);	
end component;

component WBphase is
generic (num_reg_bits : natural :=4;
			word_size: natural :=32);
port (
	clk : in std_logic;
	regDestAddr : in std_logic_vector(num_reg_bits-1 downto 0);
	loadValue : in std_logic_vector(word_size -1 downto 0); --na ovo ce se povezati dbus ka kesu
	exeResult : in std_logic_vector(word_size -1 downto 0);
	opcode : in std_logic_vector(3 downto 0);
	loadInstr : in std_logic;
	
	resultValue : out std_logic_vector(word_size-1 downto 0);
	wbWrite : out std_logic;
	regAddr : out std_logic_vector(num_reg_bits-1 downto 0)
);
end component;

component ctrlUnit is
port (
	clk : in std_logic;
	reset : in std_logic;
	opcodeEx : in std_logic_vector(3 downto 0);
	opcodeId : in std_logic_vector(3 downto 0);
	src1Id, src2Id, shiftId, dstEx : in std_logic_vector(3 downto 0);
	exeLoad : in std_logic;
	stallEx, stallId, stallIf, stallMem : out std_logic;
	flushEx, flushId : out std_logic;
	branchTaken : in std_logic;
	memWaitingIf, memWaitingMem : in std_logic
);
end component;

signal stallIf, stallId, stallEx, stallMem, flushId, flushEx : std_logic;
signal branchAddr, nextPc, pcEx : std_logic_vector(31 downto 0);
signal isBranch : std_logic;
signal instCacheMem_done, dataCacheMem_done : std_logic;
signal conditionIf, conditionId : std_logic_vector(3 downto 0);
signal instrTypeIf, instrTypeId : std_logic_vector(2 downto 0);
signal opcodeIf, opcodeId, opcodeEx, opcodeMem : std_logic_vector(3 downto 0);
signal linkSBit : std_logic;
signal hlpBit1, hlpBit2 : std_logic;
signal src1Mask, src2Reg, src1Id, src2Id, dstReg, dstId, wbDstAddr, rotValIf, rotValId : std_logic_vector(3 downto 0);
signal dstEx, dstMem : std_logic_vector(3 downto 0);
signal imm8bit : std_logic_vector(7 downto 0);
signal shiftAmountId : std_logic_vector(7 downto 0);
signal shiftAmountIf : std_logic_vector(4 downto 0);
signal shiftTypeIf, shiftTypeId : std_logic_vector(1 downto 0);
signal branchOffset : std_logic_vector(23 downto 0);
signal loadOffset : std_logic_vector(11 downto 0);
signal wbDstVal : std_logic_vector(31 downto 0);
signal wbWrite : std_logic;
signal src1Val, src2Val : std_logic_vector(31 downto 0);
signal cmpInstrId, loadInstrId, storeInstrId, brAndLinkInstrId, stopInstrId : std_logic;
signal shouldShift : std_logic;
signal stRegId, cstRegId : std_logic;
signal immRot : std_logic_vector(31 downto 0);
signal storeExRes, alOpRes, dstValMem : std_logic_vector(31 downto 0);
signal loadEx, storeEx, regOpEx, loadMem : std_logic;
signal intr, stopCpu : std_logic; --mozda ovo da ide gore u out!!!
signal instCacheWaiting, dataCacheWaiting : std_logic;


begin

ifPh: IFphase port map (clk => clk, reset => reset, stall => stallIf, pcBranch => branchAddr,
		isBranch => isBranch, rdMem => rdInstr, pc_out => nextPc, busToCache => addrToInstCache,	busFromCache => dataFromInstCache,
		mem_done => instCacheMem_done, cond => conditionIf, typeI => instrTypeIf, opcode => opcodeIf,
		lsBit => linkSBit, someBit => hlpBit1, checkBit => hlpBit2, rnMask => src1Mask, rd => dstReg, 
		rsRot => rotValIf, rm => src2Reg, imm => imm8bit, shiftA => shiftAmountIf, shift => shiftTypeIf, offIntNum => branchOffset, loadImm => loadOffset,
		waitingForMemory => instCacheWaiting
		);
		
idPh: IDphase port map (clk => clk,	reset => reset, pc_in => nextPc,	flush => flushId, stall => stallId,		
		cond => conditionIf, typeI => instrTypeIf, opcode => opcodeIf, lsBit => linkSBit, someBit => hlpBit1, checkBit => hlpBit2,
		rnMask => src1Mask, rd => dstReg, rsRot => rotValIf, rm => src2Reg, imm => imm8bit, shiftA => shiftAmountIf,
		shift => shiftTypeIf, offIntNum => branchOffset, loadImm => loadOffset, writeRegAddr => wbDstAddr, typeIOut => instrTypeId, 
		condOut => conditionId, opcodeOut => opcodeId, immValToRot => immRot, writeRegData => wbDstVal, wrReg => wbWrite, 
		operand1 => src1Val, operand2 => src2Val, isCmp => cmpInstrId, isLoad => loadInstrId, isStore => storeInstrId,
		isLink => brAndLinkInstrId, isStop => stopInstrId,	shiftType => shiftTypeId, shiftOut => shiftAmountId, rotateOut => rotValId,		
		src1Addr => src1Id, src2Addr => src2Id, dstAddr => dstId, shouldShift => shouldShift, stReg => stRegId, cstReg => cstRegId);		

exPh: execStage port map (clk => clk, reset => reset,	stall	=> stallEx, flush	=> flushEx,	currentPc => nextPc, cond => conditionId,-- videti sta ovde!!!
		opcode => opcodeId, isLoad => loadInstrId, isStore => storeInstrId, linkS => brAndLinkInstrId, 
		stReg => stRegId, cstReg => cstRegId, stop => stopInstrId, imm => immRot, A => src1Val, B => src2Val,		
		src1 => src1Id, src2 => src2Id, dst => dstId, shReg => rotValId, rdsValue => storeExRes,
		newPc	=> pcEx, opcodeOut => opcodeEx,	memPh_dstAddr => dstMem, memPh_dstVal => dstValMem, shiftVal => shiftAmountId,
		shiftType => shiftTypeId, shouldShift => shouldShift,	rotate => rotValId,	branchTaken => isBranch, instType => instrTypeId,
		loadOut => loadEx, storeOut => storeEx, regOp => regOpEx, interrupt => intr, dstAddr => dstEx, dstRegResult => alOpRes, stopCpu => stopCpu);	

memPh: memoryStage port map (clk => clk, reset => reset,	stall => stallMem, aBus => addrToDataCache, dBus => dataToFromDataCache,
		rdMem => rdData, wrMem => wrData, opcode => opcodeEx, opcodeOut => opcodeMem, ALUout => alOpRes, regIn => dstEx, regOut => dstMem, result => storeExRes, load => loadEx,
		store => storeEx, regOp => regOpEx, loadOut => loadMem,	mem_done => dataCacheMem_done, dstVal => dstValMem, waitingForMemory => dataCacheWaiting);

wbPh: WBphase port map (clk => clk,	regDestAddr => dstMem, loadValue => dataToFromDataCache,	exeResult => dstValMem,
		opcode => opcodeMem, loadInstr => loadMem, resultValue => wbDstVal, regAddr => wbDstAddr,	wbWrite => wbWrite);

controlUnit : ctrlUnit port map (clk => clk, reset => reset, opcodeEx => opcodeEx, opcodeId => opcodeId, src1Id => src1Id, src2Id => src2Id,
					shiftId => rotValId, dstEx => dstEx, exeLoad => loadEx, stallEx => stallEx, stallId => stallId,
					stallIf => stallIf, stallMem => stallMem, flushEx => flushEx, flushId => flushId, branchTaken => isBranch, memWaitingIf => instCacheWaiting, memWaitingMem => dataCacheWaiting);
end cpu_behav;