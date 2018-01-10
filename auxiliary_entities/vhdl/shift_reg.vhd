
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity shift_reg is
    Generic (
        LENGTH : integer := 1;
        DATA_WIDTH: integer := 8
    );
    
    Port ( 
        din : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        dout : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        load_data : in std_logic_vector(LENGTH * DATA_WIDTH - 1 downto 0);
        load : in std_logic;
        clk : in std_logic; 
        ce : in std_logic 
    );
end shift_reg;

architecture Behavioral of shift_reg is

signal buff_reg : std_logic_vector(DATA_WIDTH * LENGTH - 1 downto 0);
 
begin

    process (clk) is
    begin
        if (rising_edge(clk)) then
            if (load = '1') then
                buff_reg <= load_data;
            elsif (ce = '1') then
                buff_reg <= buff_reg(DATA_WIDTH * (LENGTH-1) - 1 downto 0) & din;
            end if;
        end if; 
    end process;

    dout <= buff_reg(DATA_WIDTH * LENGTH - 1 downto DATA_WIDTH * (LENGTH-1));

end Behavioral;
