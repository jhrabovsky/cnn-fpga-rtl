library STD;
    use STD.TEXTIO.ALL;

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;
    use IEEE.STD_LOGIC_TEXTIO.ALL;

entity conv_layer_tb is
end conv_layer_tb;

architecture Behavioral of conv_layer_tb is

    component conv_layer is
        Generic (
            NO_INPUT_MAPS : natural;
            NO_OUTPUT_MAPS : natural;
            INPUT_ROW_SIZE : natural;
            KERNEL_SIZE : natural;
            -- sign bit is included
            DATA_INTEGER_WIDTH : natural;
            DATA_FRACTION_WIDTH : natural;
            -- sign bit is included
            COEF_INTEGER_WIDTH : natural;
            COEF_FRACTION_WIDTH : natural;
            -- sign bit is included
            RESULT_INTEGER_WIDTH : natural;
            RESULT_FRACTION_WIDTH : natural
        );

        Port (
            din : in std_logic_vector(NO_INPUT_MAPS * (DATA_INTEGER_WIDTH + DATA_FRACTION_WIDTH) - 1 downto 0);
            w : in std_logic_vector(NO_OUTPUT_MAPS * NO_INPUT_MAPS * (KERNEL_SIZE**2) * (COEF_INTEGER_WIDTH + COEF_FRACTION_WIDTH) - 1 downto 0);
            dout : out std_logic_vector(NO_OUTPUT_MAPS * (RESULT_INTEGER_WIDTH + RESULT_FRACTION_WIDTH) - 1 downto 0);
            clk : in std_logic;
            rst : in std_logic;
            coef_load : in std_logic;
            valid_in : in std_logic;
            valid_out : out std_logic
        );
    end component;

    component mem_reader is
        generic (
            FILENAME : string;
            DATA_LEN : natural;
            ADDR_LEN : natural;
            NO_ITEMS : natural
        );
        port (
            clk : in std_logic;
            rst : in std_logic;
            en : in std_logic;
            data : out std_logic_vector(DATA_LEN - 1 downto 0);
            ts : out std_logic
        );
    end component;

    function log2c (N : integer) return integer is
        variable m, p : integer;
        begin
            m := 0;
            p := 1;

            while p < N loop
                m := m + 1;
                p := p * 2;
            end loop;

            return m;
        end log2c;


    constant NO_INPUT_MAPS : natural := 1;
    constant NO_OUTPUT_MAPS : natural := 16;
    constant KERNEL_SIZE : natural := 3;

    constant DIN_I_WIDTH : natural := 1;
    constant DIN_F_WIDTH : natural := 8;
    constant DIN_WIDTH : natural := DIN_I_WIDTH + DIN_F_WIDTH;

    constant COEF_I_WIDTH : natural := 1;
    constant COEF_F_WIDTH : natural := 4;
    constant COEF_WIDTH : natural := COEF_I_WIDTH + COEF_F_WIDTH;

    constant DOUT_I_WIDTH : natural := 3;
    constant DOUT_F_WIDTH : natural := 7;
    constant DOUT_WIDTH : natural := DOUT_I_WIDTH + DOUT_F_WIDTH;


    type KERNEL_MAP_T is array(0 to NO_INPUT_MAPS * NO_OUTPUT_MAPS - 1) of std_logic_vector((KERNEL_SIZE**2) * COEF_WIDTH - 1 downto 0);

    impure function Init_Kernel(FileName : in string) return KERNEL_MAP_T is
        FILE kernelFile : text is in FileName;
        variable kernelLine : line;
        variable kernelMap : KERNEL_MAP_T;
        variable bitvector : bit_vector((KERNEL_SIZE**2) * COEF_WIDTH - 1 downto 0);
    begin
        for I in kernelMap'RANGE loop
            if (endfile(kernelFile)) then
                kernelMap(I) := (others => '0');
            else
                readline(kernelFile, kernelLine);
                read(kernelLine, bitvector);
                kernelMap(I) := to_stdlogicvector(bitvector);
            end if;
        end loop;
        return kernelMap;
    end function;


    constant NO_INPUT_IMAGES : natural := 100;
    constant IMAGE_WIDTH : natural := 9;
    constant OUTPUT_MAP_WIDTH : natural := IMAGE_WIDTH - KERNEL_SIZE + 1;
    constant NO_INPUTS : natural := NO_INPUT_IMAGES * (IMAGE_WIDTH ** 2);
    constant NO_OUTPUTS : natural := NO_INPUT_IMAGES * OUTPUT_MAP_WIDTH;
    constant ROM_ADDR_LEN : natural := log2c(NO_INPUTS);
    constant ROM_DATA_LEN : natural := DIN_WIDTH;

    signal mem_ce : std_logic;
    signal mem_data : std_logic_vector(ROM_DATA_LEN - 1 downto 0);
    signal mem_ts : std_logic;

    signal w : std_logic_vector(NO_INPUT_MAPS * NO_OUTPUT_MAPS * (KERNEL_SIZE**2) * COEF_WIDTH - 1 downto 0);
    signal k : KERNEL_MAP_T;


    type STATE_T is (init, load, compute);
    signal state_reg : STATE_T := init;
    signal state_next : STATE_T;

    signal coef_load : std_logic;
    signal din_valid_next, din_valid_reg : std_logic;
    signal dout : std_logic_vector(NO_OUTPUT_MAPS * DOUT_WIDTH - 1 downto 0);
    signal dout_valid : std_logic;


    constant T : time := 10ns;
    signal clk, rst : std_logic;

begin

    uut : conv_layer
        generic map (
            NO_INPUT_MAPS => NO_INPUT_MAPS,
            NO_OUTPUT_MAPS => NO_OUTPUT_MAPS,
            INPUT_ROW_SIZE => DIN_WIDTH,
            KERNEL_SIZE => KERNEL_SIZE,
            DATA_INTEGER_WIDTH => DIN_I_WIDTH,
            DATA_FRACTION_WIDTH => DIN_F_WIDTH,
            COEF_INTEGER_WIDTH => COEF_I_WIDTH,
            COEF_FRACTION_WIDTH => COEF_F_WIDTH,
            RESULT_INTEGER_WIDTH => DOUT_I_WIDTH,
            RESULT_FRACTION_WIDTH => DOUT_F_WIDTH
        )
        port map (
            din => mem_data,
            w => w,
            dout => dout,
            clk => clk,
            rst => rst,
            coef_load => coef_load,
            valid_in => din_valid_reg,
            valid_out => dout_valid
        );

    -- Generovanie vstupnych riadiacich a datovych signalov
    clk_proc : process is
    begin
        clk <= '0';
        wait for T/2;
        clk <= '1';
        wait for T/2;
    end process clk_proc;

    rst <= '1', '0' after 2*T;

    k <= Init_Kernel("/home/hrabovsky/vivado_workspace/cnn/conv_layer/misc/kernels.mif");
    gen_kernel_map : for I in 0 to NO_INPUT_MAPS * NO_OUTPUT_MAPS - 1 generate
        w((I+1) * (KERNEL_SIZE**2) * COEF_WIDTH - 1 downto I * (KERNEL_SIZE**2) * COEF_WIDTH) <= k(I);
    end generate gen_kernel_map;

    image_mem_reader : mem_reader
        generic map (
            FILENAME => "/home/hrabovsky/vivado_workspace/cnn/conv_layer/misc/images.mif",
            DATA_LEN => ROM_DATA_LEN,
            ADDR_LEN => ROM_ADDR_LEN,
            NO_ITEMS => NO_INPUTS
        )
        port map (
            clk => clk,
            rst => rst,
            en => mem_ce,
            data => mem_data,
            ts => mem_ts
        );


    din_valid_next <= mem_ce;

    -- Riadenie simulacie
    regs : process (clk) is
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                state_reg <= init;
                din_valid_reg <= '0';
            else
                state_reg <= state_next;
                din_valid_reg <= din_valid_next;
            end if;
        end if;
    end process regs;

    next_state_output : process (state_reg) is
    begin
        state_next <= state_reg;
        coef_load <= '0';
        mem_ce <= '0';

        case state_reg is
            when init =>
                state_next <= load;

            when load =>
                coef_load <= '1';
                state_next <= compute;

            when compute =>
                mem_ce <= '1';

            when others =>
                state_next <= init;
        end case;
    end process next_state_output;


    -- Zapis vystupnych dat do suboru
    wr_dout_file : process is
    file outputFile : text open write_mode is "/home/hrabovsky/matlab_workspace/cnn/sim_conv_layer_dout.txt";
    variable outputLine : line;
    variable count : natural := 0;
    begin
        loop
            wait on clk;
            if (rising_edge(clk)) then
                    --if (dout_valid = '1') then
                            write(outputLine, time'IMAGE(now));
                            write(outputLine, string'(" "));

                            wr_fms_on_line : for I in 1 to NO_OUTPUT_MAPS loop
                                write(outputLine, to_integer(signed(dout((I) * DOUT_WIDTH - 1 downto (I-1) * DOUT_WIDTH))));
                                write(outputLine, string'(" "));
                            end loop;

                            write(outputLine, dout_valid);
                            writeLine(outputFile, outputLine);
                            --count := count + 1;
                            --assert count < NO_OUTPUTS report "End of Simulation" severity failure;
                    --end if;
            end if;
        end loop;
    end process wr_dout_file;

end Behavioral;
