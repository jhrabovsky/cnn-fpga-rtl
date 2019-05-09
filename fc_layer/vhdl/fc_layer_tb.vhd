library STD;
    use STD.TEXTIO.ALL;

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;
    use IEEE.STD_LOGIC_TEXTIO.ALL;


entity fc_layer_tb is
end fc_layer_tb;

architecture Behavioral of fc_layer_tb is

    component fc_layer is
        generic (
            NO_INPUTS : natural;
            NO_OUTPUTS : natural;
            DATA_INTEGER_WIDTH : natural;
            DATA_FRACTION_WIDTH : natural;
            COEF_INTEGER_WIDTH : natural;
            COEF_FRACTION_WIDTH : natural;
            RESULT_INTEGER_WIDTH : natural;
            RESULT_FRACTION_WIDTH : natural
        );

        port (
            din : in std_logic_vector(NO_INPUTS * (DATA_INTEGER_WIDTH + DATA_FRACTION_WIDTH) - 1 downto 0);
            w : in std_logic_vector(NO_OUTPUTS * NO_INPUTS * (COEF_INTEGER_WIDTH + COEF_FRACTION_WIDTH) - 1 downto 0);
            dout : out std_logic_vector(NO_OUTPUTS * (RESULT_INTEGER_WIDTH + RESULT_FRACTION_WIDTH) - 1 downto 0);
            clk : in std_logic;
            rst : in std_logic;
            ce : in std_logic
        );
    end component;

    constant NO_INPUTS : natural := 16;
    constant NO_OUTPUTS : natural := 10;

    constant DATA_INTEGER_WIDTH : natural := 6;
    constant DATA_FRACTION_WIDTH : natural := 4;
    constant DATA_WIDTH : natural := DATA_INTEGER_WIDTH + DATA_FRACTION_WIDTH;

    constant COEF_INTEGER_WIDTH : natural := 1;
    constant COEF_FRACTION_WIDTH : natural := 4;
    constant COEF_WIDTH : natural := COEF_INTEGER_WIDTH + COEF_FRACTION_WIDTH;

    signal T : time := 10ns;
    signal clk, rst, ce : std_logic;
    signal din : std_logic_vector(NO_INPUTS * DATA_WIDTH - 1 downto 0);
    signal dout : std_logic_vector(NO_OUTPUTS * DATA_WIDTH - 1 downto 0);
    signal w : std_logic_vector(NO_OUTPUTS * NO_INPUTS * COEF_WIDTH - 1 downto 0);

    type KERNEL_MAP_T is array(0 to NO_OUTPUTS - 1) of std_logic_vector(NO_INPUTS * COEF_WIDTH - 1 downto 0);

    impure function Init_Kernel(FileName : in string) return KERNEL_MAP_T is
        FILE kernelFile : text is in FileName;
        variable kernelLine : line;
        variable kernelMap : KERNEL_MAP_T;
        variable bitvector : bit_vector(NO_INPUTS * COEF_WIDTH - 1 downto 0);
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

    signal k : KERNEL_MAP_T;

    type ARRAY_T is array(0 to NO_INPUTS-1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    constant data : ARRAY_T := (
        "0001100001",
        "0000000000",
        "0010100011",
        "0000000000",
        "0000000000",
        "0000011000",
        "0000000000",
        "0100010001",
        "0010001011",
        "0010001110",
        "0100001110",
        "0000000000",
        "0011100110",
        "0010100101",
        "0000000000",
        "0000010011");

begin

    k <= Init_Kernel("../misc/fc_kernels.mif");
    gen_kernel_map : for I in 0 to NO_OUTPUTS - 1 generate
        w((I+1) * NO_INPUTS * COEF_WIDTH - 1 downto I * NO_INPUTS * COEF_WIDTH) <= k(I);
    end generate gen_kernel_map;

    din <= data(15) & data(14) & data(13) & data(12) & data(11) & data(10) & data(9) & data(8)
           & data(7) & data(6) & data(5) & data(4) & data(3) & data(2) & data(1) & data(0);

    uut : fc_layer
        generic map (
            NO_INPUTS => NO_INPUTS,
            NO_OUTPUTS => NO_OUTPUTS,
            DATA_INTEGER_WIDTH => DATA_INTEGER_WIDTH,
            DATA_FRACTION_WIDTH => DATA_FRACTION_WIDTH,
            COEF_INTEGER_WIDTH => COEF_INTEGER_WIDTH,
            COEF_FRACTION_WIDTH => COEF_FRACTION_WIDTH,
            RESULT_INTEGER_WIDTH => DATA_INTEGER_WIDTH,
            RESULT_FRACTION_WIDTH => DATA_FRACTION_WIDTH
        )
        port map (
            din => din,
            w => w,
            dout => dout,
            clk => clk,
            rst => rst,
            ce => ce
        );


    clk_gen : process is
    begin
        clk <= '0';
        wait for T/2;
        clk <= '1';
        wait for T/2;
    end process clk_gen;

    rst <= '1', '0' after 2*T;
    ce <= not rst;

end Behavioral;
