
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity compute_part_tb is
end compute_part_tb;

architecture Behavioral of compute_part_tb is

component compute_part is
    Generic (
        DLENGTH : integer := 9
    );
    
    Port ( 
        clk, rst : in std_logic;
        run : in std_logic;
        din_a : in std_logic_vector(DLENGTH - 1 downto 0);
        din_b : in std_logic_vector(DLENGTH - 1 downto 0);
        dout : out std_logic_vector(DLENGTH - 1 downto 0);
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

constant ROW_LENGTH : integer := 8;
constant DATA_LENGTH : integer := 9;

signal din_a, din_b, dout : std_logic_vector(DATA_LENGTH - 1 downto 0);
signal dout_valid : std_logic;

type IMAGE_INT is array (0 to ROW_LENGTH * 2 - 1) of integer;
constant INPUT_MAP_INT_A : IMAGE_INT := (2, 1, 1, 4, 6, 8, 1, 2,
                                         0, 2, 4, 5, 6, 7, 8, 1);

constant INPUT_MAP_INT_B : IMAGE_INT := (0, 1, 2, 3, 4, 5, 6, 7,
                                         1, 0, 2, 4, 5, 6, 7, 3);
                                         
signal IMAGE_VECTOR_A, IMAGE_VECTOR_B : std_logic_vector(DATA_LENGTH * (ROW_LENGTH * 2) - 1 downto 0);

begin
    uut: compute_part
    generic map (
        DLENGTH => DATA_LENGTH
    )
    port map (
        clk => clk,
        rst => rst,
        run => run,
        din_a => din_a,
        din_b => din_b,
        dout => dout,
        dout_valid => dout_valid
    );
    
    set_image_vectors : for I in 0 to ROW_LENGTH * 2 - 1 generate
        IMAGE_VECTOR_A(DATA_LENGTH * (I+1) - 1 downto DATA_LENGTH * I) <= std_logic_vector(to_unsigned(INPUT_MAP_INT_A(I), DATA_LENGTH));
        IMAGE_VECTOR_B(DATA_LENGTH * (I+1) - 1 downto DATA_LENGTH * I) <= std_logic_vector(to_unsigned(INPUT_MAP_INT_B(I), DATA_LENGTH));
    end generate set_image_vectors;
    
    input_buffer_a : shift_reg
        generic map (
            LENGTH => ROW_LENGTH * 2,
            DATA_WIDTH => DATA_LENGTH
        )
        port map (
            din => din_a,
            dout => din_a,
            load_data => IMAGE_VECTOR_A,
            load => load,
            clk => clk,
            ce => run
        );
     
    input_buffer_b : shift_reg
        generic map (
            LENGTH => ROW_LENGTH * 2,
            DATA_WIDTH => DATA_LENGTH
        )
        port map (
            din => din_b,
            dout => din_b,
            load_data => IMAGE_VECTOR_B,
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
        
        -- RESET systemu 
        rst <= '1';
        wait for T;
        rst <= '0';
        wait for 2*T;
        
        -- LOAD input registra
        load <= '1';
        wait for T;
        load <= '0';
        
        -- SPUSTENIE spracovania
        run <= '1';
        
        -- PRERUSENIE VST DAT => PRICHOD NEPLATNYCH DAT
        wait for 9*T;
        run <= '0';
        
        -- POKRACOVANIE VST DAT => OPATOVNY PRICHOD PLATNYCH DAT 
        wait for 3*T;
        run <= '1';
        
        wait for 3*T;
        run <= '0';
        
        wait for 4*T;
        run <= '1';
         
        wait;          
    end process stimuli;

end Behavioral;
