
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity maxpooling_layer is
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
end maxpooling_layer;

architecture Behavioral of maxpooling_layer is

------------------------------------------------
--          COMPONENTS - DECLARATION          --
------------------------------------------------

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
        compute_en : out std_logic
    );
end component;

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

signal data_a_to_compute, data_b_to_compute : std_logic_vector(DATA_WIDTH - 1 downto 0);
signal compute_en : std_logic;

begin

------------------------------------------------
--             MEMORY - FIFOS                 --
------------------------------------------------

    memory : memory_part
        generic map (
            DATA_LENGTH => DATA_WIDTH,
            ROW_LENGTH => ROW_LENGTH
        )
        port map (
            clk => clk,
            rst => rst,
            din => din,
            din_valid => din_valid,
            dout_a => data_a_to_compute,
            dout_b => data_b_to_compute,
            compute_en => compute_en
        );    
        
------------------------------------------------
--           COMPUTATION - PROCESSING         --
------------------------------------------------
                
    compute : compute_part
        generic map (
            DLENGTH => DATA_WIDTH
        )
        port map (
            clk => clk,
            rst => rst,
            run => compute_en,
            din_a => data_a_to_compute,
            din_b => data_b_to_compute,
            dout => dout,
            dout_valid => dout_valid
        );     
                   
end Behavioral;
