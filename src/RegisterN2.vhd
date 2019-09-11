library ieee;
use ieee.std_logic_1164.all;

entity RegisterN2 is
    generic(
        n_bits : natural := 31
        );
	port(	CLK: in std_logic;
            D: in std_logic_vector(n_bits-1 downto 0);
			Enable: in std_logic;
			Q: out std_logic_vector(n_bits-1 downto 0):=(others => '0')
			);
end RegisterN2;

architecture structural of RegisterN2 is
begin
	Q <= D when CLK'event and CLK='0' and Enable='1';
end structural;
