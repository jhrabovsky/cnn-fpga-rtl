
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity memory_part is
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
end memory_part;

architecture Behavioral of memory_part is

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

component counter_mod_n is
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
end component;

signal data_1_tmp : std_logic_vector(DATA_LENGTH * 3 - 1 downto 0);
signal data_2_tmp : std_logic_vector(DATA_LENGTH * 3 - 1 downto 0);

alias data_1_in : std_logic_vector(DATA_LENGTH - 1 downto 0) is data_1_tmp(DATA_LENGTH - 1 downto 0);
alias data_1_a : std_logic_vector(DATA_LENGTH - 1 downto 0) is data_1_tmp(2 * DATA_LENGTH - 1 downto DATA_LENGTH);
alias data_1_b : std_logic_vector(DATA_LENGTH - 1 downto 0) is data_1_tmp(3 * DATA_LENGTH - 1 downto 2 * DATA_LENGTH);

alias data_2_in : std_logic_vector(DATA_LENGTH - 1 downto 0) is data_2_tmp(DATA_LENGTH - 1 downto 0);
alias data_2_a : std_logic_vector(DATA_LENGTH - 1 downto 0) is data_2_tmp(2 * DATA_LENGTH - 1 downto DATA_LENGTH);
alias data_2_b : std_logic_vector(DATA_LENGTH - 1 downto 0) is data_2_tmp(3 * DATA_LENGTH - 1 downto 2 * DATA_LENGTH);

-- TIMERS => meranie casu do zmeny stavu fifo => FULL a EMPTY
signal full, full_reg, wr_en, clr_full : std_logic;
signal empty, rd_en, clr_empty : std_logic;

-- sel: 0 -> FIFO1, 1 -> FIFO2
signal sel : std_logic;
signal ce_1, ce_2 : std_logic;

-- FSM
type STATE_T is (s1, s2, s3, s4);
signal state_reg, state_next : STATE_T;

signal full_tick : std_logic;

begin

----------------------------------------------
--                FIFOS                     --
----------------------------------------------

    fifo_gen : for I in 1 downto 0 generate
        fifo_inst1 : shift_reg
            generic map (
                LENGTH => ROW_LENGTH,
                DATA_WIDTH => DATA_LENGTH
            )
            port map (
                din => data_1_tmp(DATA_LENGTH * (I+1) - 1 downto DATA_LENGTH * I),
                dout => data_1_tmp(DATA_LENGTH * (I+2) - 1 downto DATA_LENGTH * (I+1)),
                load_data => (others => '0'),
                load => rst,
                clk => clk,
                ce => ce_1
            );
            
        fifo_inst2 : shift_reg
            generic map (
                LENGTH => ROW_LENGTH,
                DATA_WIDTH => DATA_LENGTH
            )
            port map (
                din => data_2_tmp(DATA_LENGTH * (I+1) - 1 downto DATA_LENGTH * I),
                dout => data_2_tmp(DATA_LENGTH * (I+2) - 1 downto DATA_LENGTH * (I+1)),
                load_data => (others => '0'),
                load => rst,
                clk => clk,
                ce => ce_2
            );
    end generate;
    
----------------------------------------------
--              ROUTE LOGIC                 --
----------------------------------------------

    data_1_in <= din; 
    data_2_in <= din;
    
    dout_a <= data_1_a when (sel = '0') else
              data_2_a;
              
    dout_b <= data_1_b when (sel = '0') else
              data_2_b;
    
    clr_full <= full_tick;
    clr_empty <= '0';
    wr_en <= din_valid;    
    compute_en <= rd_en;
    
----------------------------------------------
--                TIMERS                    --
----------------------------------------------

    timer_full : counter_mod_n
        generic map (
            N => 2 * ROW_LENGTH
        )
        port map (
            clk => clk,
            rst => rst,
            ce => wr_en,
            clear => clr_full, 
            tc => full
        );
    
     timer_empty : counter_mod_n
        generic map (
            N => ROW_LENGTH
        )
        port map (
            clk => clk,
            rst => rst,
            ce => rd_en,
            clear => clr_empty, 
            tc => empty
        ); 
        
----------------------------------------------
--            FSM - CONTROL LOGIC           --
----------------------------------------------

    regs : process (clk, rst) is
    begin
        if (rst = '1') then
            state_reg <= s1;
			full_reg <= '0';
        elsif (rising_edge(clk)) then
            state_reg <= state_next;
			full_reg <= full;
        end if;
    end process regs;
    
    next_state_output : process (state_reg, empty, full_tick, din_valid) is
    begin
        state_next <= state_reg;
        sel <= '0';
        rd_en <= '0';
        
        case state_reg is
            when s1 =>
                ce_1 <= din_valid;
                ce_2 <= '0';
                if (full_tick = '1') then                    
                    state_next <= s2;
                end if;
                
            when s2 =>
                ce_1 <= '1';
                ce_2 <= din_valid;
                rd_en <= '1';
                if (empty = '1') then
                    state_next <= s3;
                end if;            
                
            when s3 =>
                ce_1 <= '0';
                ce_2 <= din_valid;
                rd_en <= '0';
                if (full_tick = '1') then
                    state_next <= s4;
                end if;
                
            when s4 =>
                ce_1 <= din_valid;
                ce_2 <= '1';
                rd_en <= '1';
                sel <= '1';
                if (empty = '1') then
                    state_next <= s1;
                end if;
                
            when others =>
                state_next <= s1;
                
        end case;         
    end process next_state_output;                 
    
----------------------------------------------
--    FULL_IMPULSE - RISING EDGE DETECTION  --
----------------------------------------------

    full_tick <= full and (not full_reg);

end Behavioral;
