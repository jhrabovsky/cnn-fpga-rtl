library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

entity relu is
    Generic (
        WIDTH: natural
    );

    Port (
        din: in std_logic_vector(WIDTH - 1 downto 0);
        dout: out std_logic_vector(WIDTH - 1 downto 0)
    );
end relu;

architecture rtl of relu is
begin

    dout <= (others => '0') when din(WIDTH - 1) = '1' else din;

end rtl;
