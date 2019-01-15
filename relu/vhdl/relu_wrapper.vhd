library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity relu_wrapper is
    Port (
        din: in std_logic_vector(9 downto 0);
        dout: out std_logic_vector(9 downto 0)
    );
end relu_wrapper;

architecture Structural of relu_wrapper is

begin

    relu_inst : entity WORK.relu
        generic map (
            WIDTH => 10
        )
        port map (
            din => din,
            dout => dout
        );

end Structural;
