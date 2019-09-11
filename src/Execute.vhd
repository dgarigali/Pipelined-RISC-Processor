library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Execute is
  Generic (n_bits : integer := 32);
  Port (
    A      : in std_logic_vector(n_bits-1 downto 0); 
    B      : in std_logic_vector(n_bits-1 downto 0);
    MA     : in STD_LOGIC_VECTOR(1 downto 0);
    MB     : in STD_LOGIC_VECTOR(1 downto 0);
    EX_SEL_B  : in STD_LOGIC;
    KNS    : in std_logic_vector(n_bits-1 downto 0); 
    FS     : in std_logic_vector( 3 downto 0);
    ALU_data : in std_logic_vector(31 downto 0);
    MEM_data:  in std_logic_vector(31 downto 0);
    MemD   : out std_logic_vector(n_bits-1 downto 0);
    DataD  : out std_logic_vector(n_bits-1 downto 0) 
  );
end Execute;

architecture Structural of Execute is

component FunctionalUnit
  Generic (n_bits : integer := 32);
    Port ( A : in std_logic_vector (n_bits-1 downto 0);
           B : in std_logic_vector (n_bits-1 downto 0);
           FS : in std_logic_vector (3 downto 0);
           D : out std_logic_vector (n_bits-1 downto 0);
           FL : out std_logic_vector (3 downto 0));
end component;

signal OpA, OpB, OpB_s, AD : std_logic_vector(n_bits-1 downto 0);
signal Flags : std_logic_vector(3 downto 0); -- {Z,C,N,V}

begin

-- select operands for the functional unit
with MA select 
    OpA <=  A           when "00",
            KNS         when "01",
            ALU_data    when "10",
            MEM_data    when others;

with MB select 
    OpB_s <=  ALU_data    when "10",
              MEM_data    when "11",
              B           when others;

OpB <= OpB_s when EX_SEL_B = '0' else KNS;
AD <= OpB_s when EX_SEL_B = '1' else KNS;
MemD <= OpB_s;

-- instantiate the functional unit
ALU: FunctionalUnit port map( A => OpA , B => OpB , FS => FS, D => DataD, FL => Flags);

end Structural;