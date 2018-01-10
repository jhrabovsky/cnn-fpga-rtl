
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity counter_mod_n is
    Generic (
        N : integer
    );
    
    Port ( 
        clk : in std_logic;
        rst : in std_logic;
        ce : in std_logic;
        clear : in std_logic;
        tc : out std_logic -- terminal count
    );
end counter_mod_n;

architecture Behavioral of counter_mod_n is

function log2c (N : integer) return integer is
    variable m, p : integer;
begin
    m := 0;
    p := 1;
    while p < N loop
        m := m + 1;
        p := p * 2;
    end loop;
    return m;
end log2c; 

signal count_reg, count_next : unsigned(log2c(N) - 1 downto 0);

begin
    
    process (clk, rst) is
    begin
        if (rst = '1') then
            count_reg <= (others => '0');
        elsif (rising_edge(clk)) then
            if (clear = '1') then
                count_reg <= (others => '0');
            elsif (ce = '1') then
                count_reg <= count_next;
            end if;
        end if;
    end process;
    
    count_next <= (others => '0') when (count_reg = to_unsigned(N - 1, count_reg'LENGTH)) else
                  count_reg + 1;
                  
    tc <= '1' when (count_reg = to_unsigned(N - 1, count_reg'LENGTH)) else
          '0';

end Behavioral;
