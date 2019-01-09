
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter_up is
    Generic (
        THRESHOLD : natural;
        THRESHOLD_WIDTH : natural
    );
    Port ( CLK_IN : in STD_LOGIC;
           RST: in STD_LOGIC;
           EN : in STD_LOGIC;
           COUNT : out STD_LOGIC_VECTOR(THRESHOLD_WIDTH - 1 downto 0);
           TS : out STD_LOGIC
    );
end counter_up;

architecture Behavioral of counter_up is

signal count_next : unsigned(THRESHOLD_WIDTH - 1 downto 0);
signal count_reg : unsigned(THRESHOLD_WIDTH - 1 downto 0);

begin
    counter_upd: process (CLK_IN)
    begin
        if (rising_edge(CLK_IN)) then
            if (RST = '1') then
                count_reg <= (others => '0');
            elsif (EN = '1') then
                count_reg <= count_next;
            end if;
        end if;
    end process counter_upd;

    count_next <= (others => '0') when count_reg = to_unsigned(THRESHOLD, THRESHOLD_WIDTH) else
                  count_reg + 1;

    TS <= '1' when count_reg = to_unsigned(THRESHOLD, THRESHOLD_WIDTH) else
          '0';

    COUNT <= std_logic_vector(count_reg);

end Behavioral;
