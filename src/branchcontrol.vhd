library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity branchcontrol is
    Generic (n_bits : integer := 32);
    Port ( PL : in std_logic_vector(1 downto 0);
           BC : in STD_LOGIC_VECTOR(3 downto 0);
           PC : in STD_LOGIC_VECTOR (31 downto 0);
           PC_Link : in STD_LOGIC_VECTOR (31 downto 0);
           EX_PC_Link : in STD_LOGIC_VECTOR (31 downto 0);
           MA :     in STD_LOGIC_VECTOR(1 downto 0);
           MB :     in STD_LOGIC_VECTOR(1 downto 0);
           SEL_B :  in STD_LOGIC;
           A      : in std_logic_vector(n_bits-1 downto 0); 
           B      : in std_logic_vector(n_bits-1 downto 0);
           KNS    : in std_logic_vector(n_bits-1 downto 0); 
           ALU_data : in std_logic_vector(31 downto 0);
           MEM_data:  in std_logic_vector(31 downto 0);
           c_WB_regA : in std_logic;
           c_WB_regB : in std_logic;
           STALL_REG_IN : in std_logic;
           DA_IN       :   in STD_LOGIC_VECTOR ( 3 downto 0);
           PL_EX : in STD_LOGIC_VECTOR(1 downto 0);
           BC_EX : in STD_LOGIC_VECTOR(3 downto 0);
           BA    : in STD_LOGIC_VECTOR(3 downto 0);
           MEM_Jump_Flag : in std_logic;
           Jump_Flag : out std_logic;
           PCLoad : out STD_LOGIC;
           STALL_REG_OUT : out std_logic;
           DA_OUT       :   out STD_LOGIC_VECTOR ( 3 downto 0);
           PCValue : out STD_LOGIC_VECTOR (31 downto 0));
end branchcontrol;

architecture Behavioral of branchcontrol is

component ArithmeticUnit is
    Generic (n_bits : integer := 32);
    Port ( A : in std_logic_vector (n_bits-1 downto 0);
           B : in std_logic_vector (n_bits-1 downto 0);
           FS : in std_logic_vector (1 downto 0);
           D : out std_logic_vector (n_bits-1 downto 0);
           CO : out std_logic;
           OV : out std_logic);
end component;

component Zero is
    Generic (n_bits : integer := 32);
    port(   Data : in std_logic_vector (n_bits-1 downto 0); D : out std_logic);
end component;

component Buf is
    port(   I : in std_logic;  D : out std_logic);
end component;

signal Z,N,P,C,V, branch_flag: std_logic;
signal PC_sel : std_logic_vector(1 downto 0);
signal PCValue_s, PCValue_s_2, Data, OpA, OpB, OpB_s, AD : STD_LOGIC_VECTOR (31 downto 0);
signal A_ALU, B_ALU : STD_LOGIC_VECTOR (31 downto 0);
signal DA_s, DA_OUT_s : std_logic_vector(3 downto 0);
signal s_and, c_and : std_logic;

begin

P <= not N and not Z; -- positive flag

with BC(2 downto 0) select
    branch_flag <= 	Z 		when "010", -- Equal
					not Z 	when "011", -- Not Equal
					P 		when "100", -- Greater than
					not N 	when "101", -- Greater or equal
					N 		when "110", -- Lower than
					not P 	when "111", -- Lower or equal
					'1'     when others;

PCLoad <= PL(0);
PC_sel <= PL(1) & (not BC(2) and not BC(1) and not BC(0));

with PC_sel select
	PCValue_s <= 	PC + AD		when "00", -- Branch
				    AD 			when "10", -- Jump
				    PC			when others; -- NOP

PCValue_s_2 <= PCValue_s when branch_flag = '1' else PC_Link;

with MA(1) select
    A_ALU <= A        when '0',
             ALU_data when others;
with c_WB_regA select
    OpA <=  A_ALU    when '0',
            MEM_data when others;

with MB(1) select
    B_ALU <= B        when '0',
             ALU_data when others;
with c_WB_regB select
    OpB_s <=  B_ALU    when '0',
              MEM_data when others;

OpB <= OpB_s when SEL_B = '0' else KNS;
AD <= OpB_s when SEL_B = '1' else KNS;

-- instantiate the functional unit
AU1 : ArithmeticUnit port map (A => OpA, B => OpB, FS => "11", D => Data, CO=>C, OV=>V);
Zero1: Zero port map (Data => Data, D => Z);
Buf1: Buf port map (I=> Data(n_bits-1), D=> N);

-- Outputs
Jump_Flag <= branch_flag;
STALL_REG_OUT <= STALL_REG_IN NOR (branch_flag and PL(0));

DA_s <= DA_IN and branch_flag & branch_flag & branch_flag & branch_flag;
DA_OUT_s <= DA_IN when PL(0) = '0' else DA_s;
DA_OUT <= DA_OUT_s;

c_and <= '1' when BA = "1111" else '0'; 
s_and <= c_and and PL(0) and PL_EX(0) and BC_EX(3) and MEM_Jump_Flag;
PCValue <= PCValue_s_2 when s_and = '0' else EX_PC_Link;

end Behavioral;