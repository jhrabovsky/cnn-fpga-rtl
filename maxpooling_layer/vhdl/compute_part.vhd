
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity compute_part is
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
end compute_part;

architecture Behavioral of compute_part is

component counter_mod_n is
    Generic (
        N : integer
    );
    
    Port ( 
        clk : in std_logic;
        rst : in std_logic;
        ce : in std_logic;
        clear : in std_logic;
        tc : out std_logic
    );
end component;

signal din_a_uns, din_b_uns : unsigned(DLENGTH - 1 downto 0);

signal max_1a_reg, max_1a_next : unsigned(DLENGTH - 1 downto 0);
signal max_1b_reg, max_1b_next : unsigned(DLENGTH - 1 downto 0);
signal ce_a, ce_b : std_logic;

signal max_2_reg, max_2_next : unsigned(DLENGTH - 1 downto 0); 

signal ce_reg, ce_next : std_logic;
signal run_reg, run_next : std_logic;
signal dout_valid_reg, dout_valid_next : std_logic;

begin

    din_a_uns <= unsigned(din_a);
    din_b_uns <= unsigned(din_b);
   
    regs : process (clk) is
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                max_1a_reg <= (others => '0');
                max_1b_reg <= (others => '0');
                max_2_reg <= (others => '0');
                ce_reg <= '0';
                run_reg <= '0';
            else
                dout_valid_reg <= dout_valid_next;
                run_reg <= run_next;
                max_2_reg <= max_2_next;
                
                if (run = '1') then
                    if (ce_a = '1') then
                        max_1a_reg <= max_1a_next;
                    end if;
                    
                    if (ce_b = '1') then
                        max_1b_reg <= max_1b_next;                     
                    end if;
                             
                    -- STRIEDANIE REG_A A REG_B
                    ce_reg <= ce_next;                
                end if;
            end if;            
        end if;
    end process regs;
    
-------------------------------------------------        
--      RIADENIE REGS MEDZI MAX_1 A MAX_2      --
-------------------------------------------------        

    ce_next <= not ce_reg;
    ce_a <= ce_reg;  
    ce_b <= not ce_reg;
    
    dout_valid_next <= ce_next and run_reg;
    run_next <= run;

--------------------------------------------------         
-- PARALELNE ZAPOJENIE MAX_1A A MAX_1B DO MAX_2 -- 
--------------------------------------------------         
  
    max_1a_next <= din_a_uns when (din_a_uns > din_b_uns) else
                  din_b_uns;  
    
    max_1b_next <= max_1a_next;
    
    max_2_next <= max_1a_reg when (max_1a_reg > max_1b_reg) else
                max_1b_reg;

--------------------------------------------------                
--           VYSTUPY: DATA A RIADENIE           --
--------------------------------------------------
                
    dout <= std_logic_vector(max_2_reg); 
    dout_valid <= dout_valid_reg;
    
end Behavioral;
