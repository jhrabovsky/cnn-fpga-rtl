
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity delay_buffer is
    Generic (
        LENGTH : natural := 1;
        DATA_WIDTH: natural := 8
    );
    
    Port ( 
        din : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        dout : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        clk, ce : in std_logic 
    );
end delay_buffer;

architecture Behavioral of delay_buffer is

-- 1bit increased the bit-width of the register because of the zero length => vector must be at least 1 bit long 
signal buff_reg : std_logic_vector(DATA_WIDTH * LENGTH downto 0);

begin
    
    atleast_2_length_gen: if (LENGTH > 1) generate
        process (clk) is
        begin
            if (rising_edge(clk)) then
                if (ce = '1') then
                    -- the MSB '0' is added because of the zero length vector
                    buff_reg <= '0' & buff_reg(DATA_WIDTH * (LENGTH-1) - 1 downto 0) & din;
                end if;
            end if; 
        end process;

        dout <= buff_reg(DATA_WIDTH * LENGTH - 1 downto DATA_WIDTH * (LENGTH-1));
    end generate;

    one_length_gen: if (LENGTH = 1) generate
        process (clk) is
        begin
            if (rising_edge(clk)) then
                if (ce = '1') then
                    -- the MSB '0' is added because of the zero length vector
                    buff_reg <= '0' & din;
                end if;
            end if; 
        end process;

        dout <= buff_reg(DATA_WIDTH - 1 downto 0);
    end generate;
    
    zero_length_gen: if (LENGTH = 0) generate
        dout <= din;
    end generate;

end Behavioral;
