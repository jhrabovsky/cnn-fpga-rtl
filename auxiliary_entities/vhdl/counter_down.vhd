
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter_down is
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
end counter_down;

architecture Behavioral of counter_down is 

signal count_next : unsigned(THRESHOLD_WIDTH - 1 downto 0);
signal count_reg : unsigned(THRESHOLD_WIDTH - 1 downto 0) := (others => '0');

begin
    counter_upd: process (CLK_IN)
    begin   
        if (rising_edge(CLK_IN)) then
            if (RST = '1') then
                count_reg <= to_unsigned(THRESHOLD, THRESHOLD_WIDTH);
            elsif (EN = '1') then
                count_reg <= count_next;
            end if;
        end if;
    end process counter_upd;

    count_next <= to_unsigned(THRESHOLD, THRESHOLD_WIDTH) when count_reg = 0 else
                  count_reg - 1;
    
    TS <= '1' when count_reg = 0 else
          '0';
    
    COUNT <= std_logic_vector(count_reg);

end Behavioral;
