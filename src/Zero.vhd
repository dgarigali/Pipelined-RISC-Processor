library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Zero is
    Generic (n_bits : integer := 32);
    port(   Data : in std_logic_vector (n_bits-1 downto 0);
            D : out std_logic);
end Zero;

architecture Behavioral of Zero is
begin

    D <= '1' when Data=(n_bits-1 downto 0=>'0') else '0'; 

end Behavioral;
