library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity InstructionDecode is
    Port ( Instruction : in STD_LOGIC_VECTOR (31 downto 0);
            -- Data dependency control inputs
           EX_DA : in STD_LOGIC_VECTOR ( 3 downto 0);
           MEM_DA : in STD_LOGIC_VECTOR ( 3 downto 0);
           WB_DA : in STD_LOGIC_VECTOR ( 3 downto 0);
           EX_MD  : in STD_LOGIC_VECTOR( 1 downto 0);
           MEM_MD : in STD_LOGIC_VECTOR( 1 downto 0);
            -- Control dependency control inputs
           PL_EX    : in STD_LOGIC_VECTOR ( 1 downto 0);
           EX_Jump_Flag : in std_logic;
            -- Instruction operands (OF => Operand Fetch)
           AA       : out STD_LOGIC_VECTOR ( 3 downto 0);
           MA       : out STD_LOGIC_VECTOR(1 downto 0);
           BA       : out STD_LOGIC_VECTOR ( 3 downto 0);
           MB       : out STD_LOGIC_VECTOR(1 downto 0);
           KNS      : out STD_LOGIC_VECTOR (31 downto 0);
           SEL_B    : out STD_LOGIC;
           -- execution control (EX => Execute)
           FS       : out STD_LOGIC_VECTOR ( 3 downto 0);
           PL       : out STD_LOGIC_VECTOR ( 1 downto 0);
           BC       : out STD_LOGIC_VECTOR ( 3 downto 0);
           -- memory control (MEM => Memory)
           MMA      : out STD_LOGIC_VECTOR ( 1 downto 0);
           MMB      : out STD_LOGIC_VECTOR ( 1 downto 0);
           MW       : out STD_LOGIC;
            -- Instruction Result (WB => Write-Back)
           MD       : out STD_LOGIC_VECTOR ( 1 downto 0);
           DA       : out STD_LOGIC_VECTOR ( 3 downto 0);
           -- For banch control block
           c_WB_regA : out std_logic;
           c_WB_regB : out std_logic;
           -- Data dependency control outputs
           STALL_CLK    : out STD_LOGIC;
           STALL_REG    : out STD_LOGIC
        );
end InstructionDecode;

architecture Structural of InstructionDecode is

component branchcontrol2 is
    Generic (n_bits : integer := 32);
    Port ( PL : in std_logic_vector(1 downto 0);
           BC : in STD_LOGIC_VECTOR(3 downto 0);
           PC : in STD_LOGIC_VECTOR (31 downto 0);
           MB :     in STD_LOGIC_VECTOR(1 downto 0);
           SEL_B :  in STD_LOGIC;
           A      : in std_logic_vector(n_bits-1 downto 0); 
           B      : in std_logic_vector(n_bits-1 downto 0);
           KNS    : in std_logic_vector(n_bits-1 downto 0); 
           ALU_data : in std_logic_vector(31 downto 0);
           MEM_data:  in std_logic_vector(31 downto 0);
           PCLoad : out STD_LOGIC;
           PCValue : out STD_LOGIC_VECTOR (31 downto 0));
end component;

type storage_type is array (0 to 63) of std_logic_vector(31 downto 0);

signal decode_memory: storage_type := (
  --------------------------------------------------------------------------------------------------------------------------------  
  --  OPCODE =>  PL  &  dAA    & dBA     & dDA     &  FS     &  KNSSel &  MASel &  MBSel &  MMA   & MMB   &  MW  &  MDSel
  --  (dec)  (31-30) & (29-26) & (25-22) & (21-18) & (17-14) & (13-11) & (10-9) & (8-7)  & (6-5)  & (4-3) &  (2) & (1-0)  
  --------------------------------------------------------------------------------------------------------------------------------  
          0 =>  "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"0"   &  "XXX"  &  "00"  &  "00"  &  "XX"  & "XX"  &  '0' &  "00",  -- ADD    R[DR],R[SA],R[SB]
          1 =>  "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"0"   &  "001"  &  "00"  &  "X1"  &  "XX"  & "XX"  &  '0' &  "00",  -- ADDI   R[DR],R[SA],SIMM18
          2 =>  "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"3"   &  "XXX"  &  "00"  &  "00"  &  "XX"  & "XX"  &  '0' &  "00",  -- SUB    R[DR],R[SA],R[SB]
          3 =>  "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"3"   &  "001"  &  "00"  &  "X1"  &  "XX"  & "XX"  &  '0' &  "00",  -- SUBI   R[DR],R[SA],SIMM18
--------------------------------------------------------------------------------------------------------------------------------  
--    OPCODE =>  PL  &  dAA    & dBA     & dDA     &  FS     &  KNSSel &  MASel &  MBSel &  MMA   & MMB   &  MW  &  MDSel
--------------------------------------------------------------------------------------------------------------------------------  
          4 =>  "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"4"   &  "XXX"  &  "00"  &  "00"  &  "XX"  & "XX"  &  '0' &  "00",  -- AND    R[DR],R[SA],R[SB]
          5 =>  "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"4"   &  "101"  &  "00"  &  "X1"  &  "XX"  & "XX"  &  '0' &  "00",  -- ANDIL  R[DR],R[SA],IMM16
          6 =>  "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"4"   &  "111"  &  "00"  &  "X1"  &  "XX"  & "XX"  &  '0' &  "00",  -- ANDIH  R[DR],R[SA],IMM16
          7 =>  "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"5"   &  "XXX"  &  "00"  &  "00"  &  "XX"  & "XX"  &  '0' &  "00",  -- NAND   R[DR],R[SA],R[SB]
          8 =>  "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"6"   &  "XXX"  &  "00"  &  "00"  &  "XX"  & "XX"  &  '0' &  "00",  -- OR     R[DR],R[SA],R[BA]
          9 =>  "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"6"   &  "100"  &  "00"  &  "X1"  &  "XX"  & "XX"  &  '0' &  "00",  -- ORIL   R[DR],R[SA],IMM16
          10 => "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"6"   &  "110"  &  "00"  &  "X1"  &  "XX"  & "XX"  &  '0' &  "00",  -- ORIH   R[DR],R[SA],IMM16
          11 => "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"7"   &  "XXX"  &  "00"  &  "00"  &  "XX"  & "XX"  &  '0' &  "00",  -- NOR    R[DR],R[SA],R[SB]
          12 => "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"8"   &  "XXX"  &  "00"  &  "00"  &  "XX"  & "XX"  &  '0' &  "00",  -- XOR    R[DR],R[SA],R[SB]
          13 => "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"9"   &  "XXX"  &  "00"  &  "00"  &  "XX"  & "XX"  &  '0' &  "00",  -- XNOR   R[DR],R[SA],R[SB]
--------------------------------------------------------------------------------------------------------------------------------  
--    OPCODE =>  PL  &  dAA    & dBA     & dDA     &  FS     &  KNSSel &  MASel &  MBSel &  MMA   & MMB   &  MW  &  MDSel
--------------------------------------------------------------------------------------------------------------------------------  
          14 => "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"A"   &  "XXX"  &  "XX"  &  "00"  &  "XX"  & "XX"  &  '0' &  "00",  -- LSL    R[DR],R[SB]
          15 => "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"B"   &  "XXX"  &  "XX"  &  "00"  &  "XX"  & "XX"  &  '0' &  "00",  -- LSR    R[DR],R[SB]
          16 => "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"E"   &  "XXX"  &  "XX"  &  "00"  &  "XX"  & "XX"  &  '0' &  "00",  -- ROL    R[DR],R[SB]
          17 => "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"F"   &  "XXX"  &  "XX"  &  "00"  &  "XX"  & "XX"  &  '0' &  "00",  -- ROR    R[DR],R[SB]
          18 => "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"C"   &  "XXX"  &  "XX"  &  "00"  &  "XX"  & "XX"  &  '0' &  "00",  -- ASL    R[DR],R[SB]
          19 => "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"D"   &  "XXX"  &  "XX"  &  "00"  &  "XX"  & "XX"  &  '0' &  "00",  -- ASR    R[DR],R[SB]
--------------------------------------------------------------------------------------------------------------------------------  
--    OPCODE =>  PL  &  dAA    & dBA     & dDA     &  FS     &  KNSSel &  MASel &  MBSel &  MMA   & MMB   &  MW  &  MDSel
--------------------------------------------------------------------------------------------------------------------------------  
          20 => "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"0"   &  "XXX"  &  "00"  &  "00"  &  "11"  & "XX"  &  '0' &  "01",  -- LD     R[DA],(R[AA]+R[BA])
          21 => "00" &  "XXXX" & "XXXX"  & "XXXX"  &  x"0"   &  "001"  &  "00"  &  "X1"  &  "11"  & "XX"  &  '0' &  "01",  -- LDI    R[DA],(R[AA]+SIMM18)
          22 => "00" &  "XXXX" & "XXXX"  &  x"0"   &  x"0"   &  "010"  &  "00"  &  "01"  &  "11"  & "10"  &  '1' &  "10",  -- ST     (R[AA]+SIMM18),R[SB]
--------------------------------------------------------------------------------------------------------------------------------  
--    OPCODE =>  PL  &  dAA    & dBA     & dDA     &  FS     &  KNSSel &  MASel &  MBSel &  MMA   & MMB   &  MW  &  MDSel
--------------------------------------------------------------------------------------------------------------------------------  
          23 => "01" &  "XXXX" & "XXXX"  &  x"F"   &  x"3"   &  "011"  &  "00"  &  "00"  &  "XX"  & "XX"  &  '0' &  "10",  -- B.cond  (R[SA] cond R[SB]),SIMM14
          24 => "01" &  "XXXX" & "XXXX"  &  x"F"   &  x"3"   &  "011"  &  "00"  &  "01"  &  "XX"  & "XX"  &  '0' &  "10",  -- BI.cond (R[SA] cond SIMM14),R[SB]
          25 => "11" &  "XXXX" &  x"0"   &  x"F"   &  x"3"   &  "100"  &  "00"  &  "10"  &  "XX"  & "XX"  &  '0' &  "10",  -- J.cond (R[SA] cond R[0]), UIMM16
          26 => "11" &  "XXXX" & "XXXX"  &  x"F"   &  x"3"   &  "011"  &  "00"  &  "01"  &  "XX"  & "XX"  &  '0' &  "10",  -- JI.cond (R[SA] cond SIMM14),R[SB]
     others =>  "00" &   x"0"  &  x"0"   &  x"0"   &  x"0"   &  "000"  &  "00"  &  "00"  &  "00"  & "00"  &  '0' &  "10"   -- NOP
);

signal Opcode : std_logic_vector(5 downto 0);
signal mem_out : std_logic_vector(31 downto 0);

signal SA,dAA : std_logic_vector(3 downto 0);
signal SB,dBA : std_logic_vector(3 downto 0);
signal DR,dDA : std_logic_vector(3 downto 0);
signal MASel, MBSel, MDSel : std_logic_vector(1 downto 0);
signal KNSSel : std_logic_vector(2 downto 0);
signal AA_s, BA_s, DA_s : std_logic_vector(3 downto 0);

-- data dependency control 

-- comparators
signal c_read_regA, c_read_regB : std_logic; -- checks if register A/B is being read
signal c_write_regA, c_write_regB : std_logic; -- checks if register from EX/MEM/WB is to be written
signal c_regA_EX, c_regA_MEM, c_regA_WB : std_logic; -- checks if write reg is equal to read regA
signal c_regB_EX, c_regB_MEM, c_regB_WB : std_logic; -- checks if write reg is equal to read regB
signal c_PL, c_ST : std_logic; -- checks if current instruction is jump/branch or store (regB is always read)

-- and/ors
signal out_AND1, out_AND2, out_AND3, out_AND4, out_AND5, out_AND6, out_AND7, out_AND8, out_AND9, out_AND10, out_AND11, out_AND12, out_AND13, out_AND14, out_AND15 : std_logic;
signal out_OR1, out_OR2, out_OR3, out_OR4, out_OR5, out_OR6, out_OR7, out_OR8 : std_logic;

-- control dependency control
signal nop : std_logic;

begin

-- Retrieve Instruction Fields
Opcode <= Instruction(31 downto 26);
DR     <= Instruction(25 downto 22);
SA     <= Instruction(21 downto 18);
SB     <= Instruction(17 downto 14);
BC     <= Instruction(25 downto 22);

-- Constant value (KNS) is always extended to 32 bits, depending on KNSSel
with KNSSel select
    KNS  <= (31 downto 18=>'0') & Instruction(17 downto 0)             when "000",
            (31 downto 18=>Instruction(17)) & Instruction(17 downto 0) when "001",
            (31 downto 18=>Instruction(25)) & Instruction(25 downto 22) & Instruction(13 downto 0) when "010",
            (31 downto 14=>Instruction(13)) & Instruction(13 downto 0) when "011",
            (31 downto 16=>'0')             & Instruction(15 downto 0) when "100",
            (31 downto 16=>'1')             & Instruction(15 downto 0) when "101",
            Instruction(15 downto 0)        & (31 downto 16=>'0')      when "110",
            Instruction(15 downto 0)        & (31 downto 16=>'1')      when others;

-- Fetch decode bits from memory
mem_out <= decode_memory(to_integer(unsigned(Opcode)));

-- Assign memory outputs
SEL_B <= MBSel(0);

PL    <= mem_out(31 downto 30) when nop = '0' else "00"; -- differ branch from jump
dDA   <= mem_out(21 downto 18);
dAA   <= mem_out(29 downto 26);
dBA   <= mem_out(25 downto 22);
MASel <= mem_out(10 downto 9);
MBSel <= mem_out( 8 downto 7);
FS    <= mem_out(17 downto 14);
KNSSel<= mem_out(13 downto 11);
MMA   <= mem_out( 6 downto 5);
MMB   <= mem_out( 4 downto 3);
MW    <= mem_out(2) when nop = '0' else '0'; -- mux for NOP operation
MDSel <= mem_out( 1 downto 0);

with MASel(1) select
    AA_s <= SA  when '0',
          dAA when others;
AA <= AA_s;

with MBSel(1) select
    BA_s <= SB  when '0',
          dBA when others;
BA <= BA_s; 

with MDSel(1) select
    DA_s <= DR  when '0',
            -- avoid storing in register when is not a branch/jump and link or when condition is not taken
            dDA AND Instruction(25) & Instruction(25) & Instruction(25) & Instruction(25) when others; 
DA <= DA_s when nop = '0' else x"0"; -- mux for NOP operation
           
MA(1) <= out_OR1;
MA(0) <= MASel(0) when out_OR1 = '0' else out_OR7;

MB(1) <= out_OR3;
MB(0) <= MBSel(0) when out_OR3 = '0' else out_OR8;

MD <= (Instruction(25) AND mem_out(30)) & MDSel(0); -- register can also store PC + 1

-- comparators
c_read_regA <= not MASel(0);
c_read_regB <= not MBSel(0);

c_write_regA <= '0' when AA_s = "0000" else '1'; 
c_write_regB <= '0' when BA_s = "0000" else '1';

c_regA_EX <= '1' when EX_DA = AA_s else '0';
c_regA_MEM <= '1' when MEM_DA = AA_s else '0';
c_regA_WB <= '1' when WB_DA = AA_s else '0';

c_regB_EX <= '1' when EX_DA = BA_s else '0';
c_regB_MEM <= '1' when MEM_DA = BA_s else '0';
c_regB_WB <= '1' when WB_DA = BA_s else '0';

c_PL <= mem_out(30);
c_ST <= '1' when Instruction(31 downto 26) = "010110" else '0';

-- AND/ORs
out_AND1 <= c_read_regA and c_write_regA;
out_AND2 <= out_AND1 and c_regA_EX;
out_AND3 <= out_AND1 and c_regA_MEM;
out_AND4 <= out_AND1 and c_regA_WB;
out_AND5 <= out_OR2 and c_write_regB;
out_AND6 <= out_AND5 and c_regB_EX;
out_AND7 <= out_AND5 and c_regB_MEM;
out_AND8 <= out_AND5 and c_regB_WB;
out_AND9 <= out_OR4 and EX_MD(0);
out_AND10 <= out_OR4 and c_PL;
out_AND11 <= c_PL and MEM_MD(0) and out_OR5;
out_AND13 <= PL_EX(0) and EX_Jump_Flag;
out_AND14 <= not out_AND2 and out_AND3;
out_AND15 <= not out_AND6 and out_AND7;

out_OR1 <= out_AND2 OR out_AND3;
out_OR2 <= c_read_regB OR c_PL OR c_ST;
out_OR3 <= out_AND6 OR out_AND7;
out_OR4 <= out_AND2 OR out_AND6;
out_OR5 <= out_AND3 OR out_AND7;
out_OR6 <= out_AND9 OR out_AND10 OR out_AND11;
out_OR7 <= EX_MD(0) OR out_AND14;
out_OR8 <= EX_MD(0) OR out_AND15;

-- stalls control
nop <= out_OR6 OR out_AND13;
STALL_REG <= out_OR6;
STALL_CLK <= not out_OR6;

-- for branch control block
c_WB_regA <= out_AND4 and not out_AND3;
c_WB_regB <= out_AND8 and not out_AND7;

end Structural;