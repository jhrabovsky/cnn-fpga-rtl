
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter_down_dynamic is
	Generic (
		THRESHOLD_WIDTH : natural
	);
	
    Port ( 
        clk : in std_logic;
        ce : in std_logic;
        clear : in std_logic;
		set : in std_logic;
		threshold : in std_logic_vector(THRESHOLD_WIDTH - 1 downto 0);
        tc : out std_logic -- terminal count
    );
end counter_down_dynamic;

architecture Behavioral of counter_down_dynamic is

signal count_reg : unsigned(THRESHOLD_WIDTH - 1 downto 0) := (others => '1');
signal count_next : unsigned(THRESHOLD_WIDTH - 1 downto 0);
signal threshold_reg : unsigned(THRESHOLD_WIDTH - 1 downto 0) := (others => '1');

begin
    
    process (clk) is
    begin
        if (rising_edge(clk)) then
			if (set = '1') then
				count_reg <= unsigned(threshold);
				threshold_reg <= unsigned(threshold);
			elsif (clear = '1') then
                count_reg <= threshold_reg;
            elsif (ce = '1') then
                count_reg <= count_next;
            end if;
        end if;
    end process;
    
	count_next <= threshold_reg when count_reg = 0 else
                  count_reg - 1;
                  
    tc <= '1' when count_reg = 0 else
          '0';

end Behavioral;
