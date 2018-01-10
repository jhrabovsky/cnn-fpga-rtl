
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity maxpooling_tb is
end maxpooling_tb;

architecture Behavioral of maxpooling_tb is

component maxpooling is
    Generic (
        DATA_WIDTH : integer := 9;
        ROW_LENGTH : integer := 28
    );
        
    Port ( 
        clk, rst : in std_logic;
        din : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        din_valid : in std_logic;
        dout : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        dout_valid : out std_logic
    );
end component;

component shift_reg is
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
end component;

constant T : time := 10ns;
signal clk, rst, load, run : std_logic;

signal din, dout : std_logic_vector(8 downto 0);
signal din_valid, dout_valid : std_logic;

constant N : integer := 32;

type IMAGE_INT is array (0 to N - 1) of integer;
constant INPUT_MAP_INT : IMAGE_INT := (0, 0, 1, 1, 1, 2, 4, 3,
                                       0, 1, 1, 2, 3, 1, 1, 2,
                                       1, 5, 4, 3, 5, 6, 7, 3,
                                       4, 2, 6, 6, 2, 7, 8, 1);
----------------------
-- OCAKAVANY VYSTUP --
--    1, 2, 3, 4    --
--    5, 6, 7, 8    --
----------------------

signal IMAGE_VECTOR : std_logic_vector(9 * N - 1 downto 0);

begin
    
    set_image_vector : for I in 0 to N - 1 generate
        IMAGE_VECTOR(9 * (I+1) - 1 downto 9 * I) <= std_logic_vector(to_signed(INPUT_MAP_INT(I), 9));
    end generate set_image_vector;


    uut : maxpooling
        generic map (
            DATA_WIDTH => 9,
            ROW_LENGTH => 8
        )
        port map (
            clk => clk,
            rst => rst,
            din => din,
            din_valid => din_valid, 
            dout => dout,
            dout_valid => dout_valid
        );
    
    input_buffer : shift_reg
        generic map (
            LENGTH => N,
            DATA_WIDTH => 9
        )
        port map (
            din => din,
            dout => din,
            load_data => IMAGE_VECTOR,
            load => load,
            clk => clk,
            ce => run
        );
                
    clk_gen : process is
    begin
        clk <= '0';
        wait for T/2;
        clk <= '1';
        wait for T/2;
    end process clk_gen;

    stimuli : process is
    begin
        run <= '0';
        load <= '0';
        din_valid <= '0';
        
        -- RESET systemu 
        rst <= '1';
        wait for T;
        rst <= '0';
        wait for 2*T;
        
        -- LOAD input registra
        load <= '1';
        wait for T;
        
        -- SPUSTENIE spracovania
        load <= '0';
        wait for T;
        
        din_valid <= '1';
        run <= '1';    
        wait for 4*T;
        
        din_valid <= '0';
        run <= '0';
        wait for 4*T;
        
        din_valid <= '1';
        run <= '1';
       
        wait;     
        
    end process stimuli;

end Behavioral;
