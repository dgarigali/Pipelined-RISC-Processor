library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity InstructionMemory is
    Port ( Address : in STD_LOGIC_VECTOR (7 downto 0);
           DataOut : out STD_LOGIC_VECTOR (31 downto 0));
end InstructionMemory;

architecture Structural of InstructionMemory is
type storage_type is array (0 to 255) of std_logic_vector(31 downto 0);

----------------------------------------------------------------------------------------------------
-- MEMORY
----------------------------------------------------------------------------------------------------
signal storage: storage_type := (
        
		--    OPCODE &   DR   &   SA   &   SB   &        KNS        -- ASSEMBLY CODE
        0 => "00000100010000000000001000000000",   --  ADDI    R1,R0,#512
        1 => "00000100100000000000000000000001",   --  ADDI    R2,R0,#1
        2 => "01011000000001001000000000000000",   --  ST      0(R1),R2
        3 => "00000000010001001000000000000000",   --  ADD     R1,R1,R2
        4 => "01011000000001001000000000000000",   --  ST      0(R1),R2
        5 => "00001100110001111111111111110110",   --  SUBI    R3,R1,#-10
        6 => "00000111100000000000010000000000",   --  ADDI    R14,R0,#1024
        7 => "01010001000001000000000000000000",   --  LD      R4,R0(R1)
        8 => "01010101010001111111111111111111",   --  LDI     R5,-1(R1)
        9 => "00000001100100010100000000000000",   --  ADD     R6,R4,R5
       10 => "01011000000001011000000000000001",   --  ST      1(R1),R6
       11 => "00000100010001000000000000000001",   --  ADDI    R1,R1,#1
       12 => "01011100110001001111111111111011",   --  B.NEQ   -5,R1,R3
       13 => "00000100110000000000001000000000",   --  ADDI    R3,R0,#512
       14 => "00001010000011000100000000000000",   --  SUB     R8,R3,R1
       15 => "01010101110001000000000000000000",   --  LDI     R7,0(R1)
       16 => "00000111010000000000000000010100",   --  ADDI    R13,R0,#20
       17 => "01101011101000110100000000000000",   --  JIL.LT  R13,R8,0
       18 => "01011100100100010000000000001001",   --  B.EQ    9,R4,R4
       19 => "00000000000000000000000000000000",   --  ADD     R0,R0,R0
       20 => "00000100100010000000000000000001",   --  ADDI    R2,R2,#1
       21 => "01010110010001111111111111111111",   --  LDI     R9,-1(R1)
       22 => "00000001110111100100000000000000",   --  ADD     R7,R7,R9
       23 => "00001100010001000000000000000001",   --  SUBI    R1,R1,#1
       24 => "00000110001000000000000000000001",   --  ADDI    R8,R8,#1
       25 => "00000111111111111111111111111111",   --  ADDI    R15,R15,#-1
       26 => "01101000010000111100000000000000",   --  JI      
       27 => "01011110010000000000000000000001",   --  BL      1
       28 => "01101000010000111100000000000000",   --  JI      R15
	   others => x"00000000" -- NOP
	 );
	 
begin

DataOut <= storage(to_integer(unsigned(Address)));
	
end Structural;
