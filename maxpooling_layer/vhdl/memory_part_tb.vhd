
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity memory_part_tb is
end memory_part_tb;

architecture Behavioral of memory_part_tb is

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

component memory_part is
    Generic (
        DATA_LENGTH : integer := 9;
        ROW_LENGTH : integer := 28
    );
    
    Port ( 
        clk, rst : in std_logic;
        din : in std_logic_vector(DATA_LENGTH - 1 downto 0);
        din_valid : in std_logic;
        dout_a, dout_b : out std_logic_vector(DATA_LENGTH - 1 downto 0);
        start_proc : out std_logic
    );
end component;
 
constant ROW_LENGTH : integer := 8;
constant DATA_LENGTH : integer := 9;

constant T : time := 10ns;
signal clk, rst, load, run : std_logic;

type IMAGE_INT is array (0 to ROW_LENGTH * 4 - 1) of integer;
constant INPUT_MAP_INT : IMAGE_INT := (32, 31, 30, 29, 28, 27, 26, 25, 24,
                                       23, 22, 21, 20, 19, 18, 17, 16,
                                       15, 14, 13, 12, 11, 10, 9, 8,
                                       7, 6, 5, 4, 3, 2, 1);

signal IMAGE_VECTOR : std_logic_vector(DATA_LENGTH * (ROW_LENGTH * 4) - 1 downto 0);

signal din, dout_a, dout_b : std_logic_vector(DATA_LENGTH - 1 downto 0);
signal start_proc, din_valid : std_logic;

begin
    set_image_vector : for I in 0 to ROW_LENGTH * 4 - 1 generate
        IMAGE_VECTOR(DATA_LENGTH * (I+1) - 1 downto DATA_LENGTH * I) <= std_logic_vector(to_signed(INPUT_MAP_INT(I), DATA_LENGTH));
    end generate set_image_vector;

    uut : memory_part
    generic map (
        DATA_LENGTH => DATA_LENGTH,
        ROW_LENGTH => ROW_LENGTH 
    )
    port map (
      clk => clk,
      rst => rst,
      din => din,
      din_valid => din_valid,
      dout_a => dout_a,
      dout_b => dout_b,
      start_proc => start_proc  
    );
                
    input_buffer : shift_reg
        generic map (
            LENGTH => ROW_LENGTH * 4,
            DATA_WIDTH => DATA_LENGTH
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

    stimuli_basic : process is
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
        
        wait for 2*T;
        din_valid <= '0';
        
        wait for T;  
        din_valid <= '1';
        
        wait;     
  
    end process stimuli_basic;
    
--    stimuli_edge_full : process is
--    begin
--        run <= '0';
--        load <= '0';
--        din_valid <= '0';
        
--        -- RESET systemu 
--        rst <= '1';
--        wait for T;
--        rst <= '0';
--        wait for 2*T;
        
--        -- LOAD input registra
--        load <= '1';
--        wait for T;
        
--        -- SPUSTENIE spracovania
--        load <= '0';
--        wait for T;
        
--        din_valid <= '1';            
--        run <= '1';
--        wait for 15*T;
        
--        din_valid <= '0';
--        wait for 3*T;  
        
--        din_valid <= '1';
        
--        wait;     
--    end process stimuli_edge_full;
        
end Behavioral;
