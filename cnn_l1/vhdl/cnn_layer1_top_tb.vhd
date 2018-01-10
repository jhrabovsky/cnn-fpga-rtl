
library STD;
    use STD.TEXTIO.ALL;

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;
    use IEEE.STD_LOGIC_TEXTIO.ALL;

entity top_tb is
end top_tb;

architecture rtl of top_tb is

component top is
    Port ( 
        CLK100MHZ: in std_logic;
        RST: in std_logic;
        DOUT_VLD: out std_logic;
        DOUT: out std_logic_vector(16 * 19 - 1 downto 0)  
    );
end component;

constant NO_OUTPUT : natural := 10 * 49; -- NO_IMAGES (10) * FM_SIZE (49=7*7)

constant T : time := 10ns;
signal clk, rst : std_logic;
signal dout : std_logic_vector(16 * 19 - 1 downto 0);
signal dout_vld : std_logic;

begin
    uut : top
        port map (
            CLK100MHZ => clk,
            RST => rst,
            DOUT_VLD => dout_vld,
            DOUT => dout
        );
    
    clk_proc : process is
    begin
        clk <= '0';
        wait for T/2;
        clk <= '1';
        wait for T/2;
    end process clk_proc;
    
    stimuli_proc : process is
    begin
        rst <= '1';
        wait for 2*T;
        
        rst <= '0';
        wait;
    end process stimuli_proc;
    
    ------------------------------
    --  WRITING RESULTS TO FILE --
    ------------------------------
    
    wr_dout_file : process is
    
    file outputFile : text open write_mode is "../l1_sim_reverse.txt";
    variable outputLine : line;
    variable count : natural := 0;
    begin      
        loop
            wait on clk;
            if (rising_edge(clk)) then
                    if (dout_vld = '1') then
                            wr_fsm_on_line : for I in 0 to 15 loop
                                write(outputLine, to_integer(signed(dout((I+1) * 19 - 1 downto I * 19))));
                                write(outputLine, string'(" "));
                            end loop;
                            writeLine(outputFile, outputLine);
                            count := count + 1;
                            assert count < NO_OUTPUT report "End of Simulation" severity failure;
                    end if;
            end if; 
        end loop;
    end process wr_dout_file;
    
end rtl;
