library STD;
    use STD.TEXTIO.ALL;

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;
    use IEEE.STD_LOGIC_TEXTIO.ALL;

library WORK;
    use WORK.REF_CNN_PKG.ALL;

entity cnn_top_tb is
end cnn_top_tb;

architecture rtl of cnn_top_tb is

component cnn_top is
    Port (
        CLK: in std_logic;
        RST: in std_logic;
        DOUT_VLD: out std_logic;
        --DOUT: out std_logic_vector(L4_NO_OUTPUTS * L4_RESULT_WIDTH - 1 downto 0)
        --DOUT: out std_logic_vector(L2_NO_OUTPUT_MAPS * L2_RESULT_WIDTH - 1 downto 0)
        DOUT: out std_logic_vector(L1_NO_OUTPUT_MAPS * L1_RESULT_WIDTH - 1 downto 0)
    );
end component;

constant NO_OUTPUTS : natural := NO_INPUT_IMAGES * L4_NO_OUTPUTS;

constant T : time := 10ns;
signal clk, rst : std_logic;
--signal dout : std_logic_vector(L4_NO_OUTPUTS * L4_RESULT_WIDTH - 1 downto 0);
--signal dout : std_logic_vector(L2_NO_OUTPUT_MAPS * L2_RESULT_WIDTH - 1 downto 0);
signal dout : std_logic_vector(L1_NO_OUTPUT_MAPS * L1_RESULT_WIDTH - 1 downto 0);
signal dout_v : std_logic;

begin
    uut : cnn_top
        port map (
            CLK => clk,
            RST => rst,
            DOUT_VLD => dout_v,
            DOUT => dout
        );

    clk_proc : process is
    begin
        clk <= '0';
        wait for T/2;
        clk <= '1';
        wait for T/2;
    end process clk_proc;

    rst <= '1', '0' after 2*T;

    ------------------------------
    --  WRITING RESULTS TO FILE --
    ------------------------------

    wr_dout_file : process is
    --file outputFile : text open write_mode is "l4_sim_vivado.txt";
    --file outputFile : text open write_mode is "l2_sim_vivado.txt";
    file outputFile : text open write_mode is "l1_sim_vivado.txt";
    variable outputLine : line;
    variable count : natural := 0;
    begin
        loop
            wait on clk;
            if (rising_edge(clk)) then
                    --if (dout_v = '1') then
                            write(outputLine, time'IMAGE(now));
                            write(outputLine, string'(" "));

                            --wr_fms_on_line : for I in 1 to L4_NO_OUTPUTS loop
                            --wr_fms_on_line : for I in 1 to L2_NO_OUTPUT_MAPS loop
                            wr_fms_on_line : for I in 1 to L1_NO_OUTPUT_MAPS loop
                                --write(outputLine, to_integer(signed(dout((I) * L4_RESULT_WIDTH - 1 downto (I-1) * L4_RESULT_WIDTH))));
                                --write(outputLine, to_integer(signed(dout((I) * L2_RESULT_WIDTH - 1 downto (I-1) * L2_RESULT_WIDTH))));
                                write(outputLine, to_integer(signed(dout((I) * L1_RESULT_WIDTH - 1 downto (I-1) * L1_RESULT_WIDTH))));
                                write(outputLine, string'(" "));
                            end loop;

                            write(outputLine, dout_v);
                            writeLine(outputFile, outputLine);
                            --count := count + 1;
                            --assert count < NO_OUTPUTS report "End of Simulation" severity failure;
                    --end if;
            end if;
        end loop;
    end process wr_dout_file;

end rtl;
