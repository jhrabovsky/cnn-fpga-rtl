
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adder is
    Generic (
        DATA_WIDTH : integer := 48
    );
    
    Port (
        din_a : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        din_b : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        dout : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end adder;

architecture Behavioral of adder is

begin

    dout <= std_logic_vector(signed(din_a) + signed(din_b));

end Behavioral;
