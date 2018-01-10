
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity se_chain is
    Generic (
        KERNEL_SIZE : integer := 5; -- Number of elements (SE)
        DATA_WIDTH : natural := 8;
        DATA_FRAC_LEN : natural := 4;
        COEF_WIDTH : natural := 8;
        COEF_FRAC_LEN : natural := 4;
        RESULT_WIDTH : natural := 9;
        RESULT_FRAC_LEN : natural := 0   
    );
    
    Port (
        din : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        w : in std_logic_vector(COEF_WIDTH * (KERNEL_SIZE**2) - 1 downto 0);
        dp : out std_logic_vector(RESULT_WIDTH * KERNEL_SIZE - 1 downto 0);
        clk : in std_logic;
        ce : in std_logic;
        coef_load : in std_logic;
        rst : in std_logic           
    );
end se_chain;

architecture Behavioral of se_chain is

---------------------------------------------
--               COMPONENTS                --
---------------------------------------------

component systolic_fir is
    Generic (
        N : integer := 5;
        MODE : string
    );
    
    Port ( 
           xn : in std_logic_vector(17 downto 0);
           yn : out std_logic_vector(47 downto 0);
           bcout : out std_logic_vector(17 downto 0);
           W : in std_logic_vector(30 * N - 1 downto 0); 
           clk : in std_logic;
           ce : in std_logic;
           coef_load : in std_logic;
           rst : in std_logic
    );
end component;

---------------------------------------------
--               SIGNALS                   --
---------------------------------------------

signal dp_scaled : std_logic_vector (48 * KERNEL_SIZE - 1 downto 0);
signal din_scaled : std_logic_vector (17 downto 0);
signal w_scaled : std_logic_vector (30 * (KERNEL_SIZE**2) - 1 downto 0);

signal xout : std_logic_vector(18 * KERNEL_SIZE - 1 downto 0);

---------------------------------------------
--            CONSTANTS FOR SCALING        --
---------------------------------------------

constant RES_ORIG_FRAC_LEN : integer := DATA_FRAC_LEN + COEF_FRAC_LEN;

begin         
    ---------------------------------------------
    --               SCALING SIGNALS           --
    ---------------------------------------------
    
    -- prevod vstupnych dat - znamienkove rozsirenie
    din_scaled(DATA_WIDTH - 1 downto 0) <= din;
    din_scaled(17 downto DATA_WIDTH) <= (others => din(din'HIGH));

    -- prevod vah => znamienkove rozsirenie
    w_scaling : for I in 0 to KERNEL_SIZE**2 - 1 generate    
        w_scaled(30 * I + COEF_WIDTH - 1 downto 30 * I) <= w(COEF_WIDTH * (I+1) - 1 downto COEF_WIDTH * I); -- povodny vstupny koeficient
        w_scaled(30 * I + 29 downto 30 * I + COEF_WIDTH) <= (others => w(COEF_WIDTH * (I+1) - 1)); -- znamienkove rozsirenie
    end generate;
    
    ---------------------------------------------
    --               RESULT TRIMMING           --
    ---------------------------------------------

    --------------------------------------------------------------------------------
    --                         ORIGINAL RESULT FROM DSP                           --
    --------------------------------------------------------------------------------
    --   INTEGER PART (48-FRACTION_PART)  --  FRACTION PART (RES_ORIG_FRAC_LEN)   --
    --------------------------------------------------------------------------------

    -- dp_scaled(48 * I) ==> LSB for I-th result
    -- dp_scaled(48 * I + 47) ==> MSB for I-th result
    dp_scaling : for I in 0 to (KERNEL_SIZE - 1) generate
        dp(RESULT_WIDTH * (I+1) - 1 downto RESULT_WIDTH * I) <= dp_scaled(48 * I + 47) & dp_scaled(48 * I + RES_ORIG_FRAC_LEN + RESULT_WIDTH - RESULT_FRAC_LEN - 2 downto 48 * I + RES_ORIG_FRAC_LEN) & dp_scaled(48 * I + RES_ORIG_FRAC_LEN - 1 downto 48 * I + RES_ORIG_FRAC_LEN - RESULT_FRAC_LEN);    
    end generate;
              
    ---------------------------------------------
    --           STRUCTURE FOR 2D-CONV         --
    ---------------------------------------------
              
    SE: for I in 0 to KERNEL_SIZE-1 generate
        SE_first: if (I = 0) generate
            SE_0 : systolic_fir
                    generic map (
                        N => KERNEL_SIZE,
                        MODE => "DIRECT"
                    )                     
                    port map (
                        xn => din_scaled,
                        yn => dp_scaled(48 * (I+1) - 1 downto 48 * I),
                        bcout => xout(18 * (I+1) - 1 downto 18 * I),
                        W => w_scaled(30 * KERNEL_SIZE * (I+1) - 1 downto 30 * KERNEL_SIZE * I),
                        clk => clk,
                        ce => ce,
                        coef_load => coef_load,
                        rst => rst                                              
                    );
        end generate;
        
        SE_I: if (I > 0 and I < KERNEL_SIZE-1) generate
            SE_I : systolic_fir
                    generic map (
                        N => KERNEL_SIZE,
                        MODE => "CASCADE"
                    )
                    port map (
                         xn => xout(18 * I - 1 downto 18 * (I-1)),
                         yn => dp_scaled(48 * (I+1) - 1 downto 48 * I),
                         bcout => xout(18 * (I+1) - 1 downto 18 * I),
                         W => w_scaled(30 * KERNEL_SIZE * (I+1) - 1 downto 30 * KERNEL_SIZE * I),
                         clk => clk,
                         ce => ce,
                         coef_load => coef_load,
                         rst => rst                                              
                    );
        end generate;
        
        SE_last: if (I = KERNEL_SIZE-1) generate
            SE_last : systolic_fir 
                    generic map (
                        N => KERNEL_SIZE,
                        MODE => "CASCADE"
                    )
                    port map (
                        xn => xout(18 * I - 1 downto 18 * (I-1)),
                        yn => dp_scaled(48 * (I+1) - 1 downto 48 * I),
                        bcout => open,
                        W => w_scaled(30 * KERNEL_SIZE * (I+1) - 1 downto 30 * KERNEL_SIZE * I),
                        clk => clk,
                        ce => ce,
                        coef_load => coef_load,
                        rst => rst                                              
                    );
        end generate;
        
    end generate;
		
end Behavioral;
