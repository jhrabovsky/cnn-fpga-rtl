library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

package ref_cnn_pkg is

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

    component conv_layer is
        Generic (
            NO_INPUT_MAPS : natural;
            NO_OUTPUT_MAPS : natural;
            INPUT_ROW_SIZE : natural;
            KERNEL_SIZE : natural;
            DATA_INTEGER_WIDTH : natural;
            DATA_FRACTION_WIDTH : natural;
            COEF_INTEGER_WIDTH : natural;
            COEF_FRACTION_WIDTH : natural;
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

    component relu is
        Generic (
            WIDTH: natural
        );

        Port (
            din: in std_logic_vector(WIDTH - 1 downto 0);
            dout: out std_logic_vector(WIDTH - 1 downto 0)
        );
    end component;

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

    -------------------------------
    --      CONSTANTS - CONV 1   --
    -------------------------------
    constant L1_NO_INPUT_MAPS : natural := 1;
    constant L1_NO_OUTPUT_MAPS : natural := 16;
    constant L1_MAP_ROW_LEN : natural := 9;
    constant L1_KERNEL_SIZE : natural := 3;

    constant L1_DATA_INTEGER_LEN : natural := 1;
    constant L1_DATA_FRACTION_LEN : natural := 8;
    constant L1_DATA_WIDTH : natural := L1_DATA_INTEGER_LEN + L1_DATA_FRACTION_LEN;

    constant L1_COEF_INTEGER_LEN : natural := 1;
    constant L1_COEF_FRACTION_LEN : natural := 4;
    constant L1_COEF_WIDTH : natural := L1_COEF_INTEGER_LEN + L1_COEF_FRACTION_LEN;

    constant L1_RESULT_INTEGER_LEN : natural := 3;
    constant L1_RESULT_FRACTION_LEN : natural := 7;
    constant L1_RESULT_WIDTH : natural := L1_RESULT_INTEGER_LEN + L1_RESULT_FRACTION_LEN;

    -------------------------------
    --      CONSTANTS - CONV 2   --
    -------------------------------
    constant L2_NO_INPUT_MAPS : natural := 16;
    constant L2_NO_OUTPUT_MAPS : natural := 16;
    constant L2_MAP_ROW_LEN : natural := 7;
    constant L2_KERNEL_SIZE : natural := 3;

    constant L2_DATA_INTEGER_LEN : natural := 3;
    constant L2_DATA_FRACTION_LEN : natural := 7;
    constant L2_DATA_WIDTH : natural := L2_DATA_INTEGER_LEN + L2_DATA_FRACTION_LEN;

    constant L2_COEF_INTEGER_LEN : natural := 1;
    constant L2_COEF_FRACTION_LEN : natural := 4;
    constant L2_COEF_WIDTH : natural := L2_COEF_INTEGER_LEN + L2_COEF_FRACTION_LEN;

    constant L2_RESULT_INTEGER_LEN : natural := 4;
    constant L2_RESULT_FRACTION_LEN : natural := 6;
    constant L2_RESULT_WIDTH : natural := L2_RESULT_INTEGER_LEN + L2_RESULT_FRACTION_LEN;

    -------------------------------
    --      CONSTANTS - CONV 3   --
    -------------------------------
    constant L3_NO_INPUT_MAPS : natural := 16;
    constant L3_NO_OUTPUT_MAPS : natural := 16;
    constant L3_MAP_ROW_LEN : natural := 5;
    constant L3_KERNEL_SIZE : natural := 5;

    constant L3_DATA_INTEGER_LEN : natural := 4;
    constant L3_DATA_FRACTION_LEN : natural := 6;
    constant L3_DATA_WIDTH : natural := L2_DATA_INTEGER_LEN + L2_DATA_FRACTION_LEN;

    constant L3_COEF_INTEGER_LEN : natural := 1;
    constant L3_COEF_FRACTION_LEN : natural := 4;
    constant L3_COEF_WIDTH : natural := L2_COEF_INTEGER_LEN + L2_COEF_FRACTION_LEN;

    constant L3_RESULT_INTEGER_LEN : natural := 6;
    constant L3_RESULT_FRACTION_LEN : natural := 4;
    constant L3_RESULT_WIDTH : natural := L2_RESULT_INTEGER_LEN + L2_RESULT_FRACTION_LEN;

    -------------------------------
    --      CONSTANTS - FC       --
    -------------------------------
    constant L4_NO_INPUTS : natural := 16;
    constant L4_NO_OUTPUTS : natural := 10;

    constant L4_DATA_INTEGER_WIDTH : natural := 6;
    constant L4_DATA_FRACTION_WIDTH : natural := 4;
    constant L4_DATA_WIDTH : natural := L4_DATA_INTEGER_WIDTH + L4_DATA_FRACTION_WIDTH;

    constant L4_COEF_INTEGER_WIDTH : natural := 1;
    constant L4_COEF_FRACTION_WIDTH : natural := 4;
    constant L4_COEF_WIDTH : natural := L4_COEF_INTEGER_WIDTH + L4_COEF_FRACTION_WIDTH;

    constant L4_RESULT_INTEGER_WIDTH : natural := 6;
    constant L4_RESULT_FRACTION_WIDTH : natural := 4;
    constant L4_RESULT_WIDTH : natural := L4_RESULT_INTEGER_WIDTH + L4_RESULT_FRACTION_WIDTH;

    -------------------------------
    --      CONSTANTS - IMAGES   --
    -------------------------------
    constant NO_INPUT_IMAGES : natural := 100;
    constant NO_INPUTS : natural := NO_INPUT_IMAGES * (L1_MAP_ROW_LEN ** 2);

    -----------------------------------
    -- COEFFICIENTS LOADING INTO MEM --
    -----------------------------------

    function log2c (N : integer) return integer;

    type L1_KERNEL_MAP_T is array(0 to L1_NO_INPUT_MAPS * L1_NO_OUTPUT_MAPS - 1) of std_logic_vector((L1_KERNEL_SIZE**2) * L1_COEF_WIDTH - 1 downto 0);
    type L2_KERNEL_MAP_T is array(0 to L2_NO_INPUT_MAPS * L2_NO_OUTPUT_MAPS - 1) of std_logic_vector((L2_KERNEL_SIZE**2) * L2_COEF_WIDTH - 1 downto 0);
    type L3_KERNEL_MAP_T is array(0 to L3_NO_INPUT_MAPS * L3_NO_OUTPUT_MAPS - 1) of std_logic_vector((L3_KERNEL_SIZE**2) * L3_COEF_WIDTH - 1 downto 0);

    impure function Init_L1_Kernel(FileName : in string) return L1_KERNEL_MAP_T;
    impure function Init_L2_Kernel(FileName : in string) return L2_KERNEL_MAP_T;
    impure function Init_L3_Kernel(FileName : in string) return L3_KERNEL_MAP_T;

    type L4_KERNEL_MAP_T is array(0 to L4_NO_OUTPUTS - 1) of std_logic_vector(L4_NO_INPUTS * L4_COEF_WIDTH - 1 downto 0);
    impure function Init_L4_Kernel(FileName : in string) return L4_KERNEL_MAP_T;

end package ref_cnn_pkg;


package body ref_cnn_pkg is

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

    impure function Init_L1_Kernel(FileName : in string) return L1_KERNEL_MAP_T is
        FILE kernelFile : text is in FileName;
        variable kernelLine : line;
        variable kernelMap : L1_KERNEL_MAP_T;
        variable bitvector : bit_vector((L1_KERNEL_SIZE**2) * L1_COEF_WIDTH - 1 downto 0);
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

    impure function Init_L2_Kernel(FileName : in string) return L2_KERNEL_MAP_T is
        FILE kernelFile : text is in FileName;
        variable kernelLine : line;
        variable kernelMap : L2_KERNEL_MAP_T;
        variable bitvector : bit_vector((L2_KERNEL_SIZE**2) * L2_COEF_WIDTH - 1 downto 0);
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

    impure function Init_L3_Kernel(FileName : in string) return L3_KERNEL_MAP_T is
        FILE kernelFile : text is in FileName;
        variable kernelLine : line;
        variable kernelMap : L3_KERNEL_MAP_T;
        variable bitvector : bit_vector((L3_KERNEL_SIZE**2) * L3_COEF_WIDTH - 1 downto 0);
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

    impure function Init_L4_Kernel(FileName : in string) return L4_KERNEL_MAP_T is
        FILE kernelFile : text is in FileName;
        variable kernelLine : line;
        variable kernelMap : L4_KERNEL_MAP_T;
        variable bitvector : bit_vector(L4_NO_INPUTS * L4_COEF_WIDTH - 1 downto 0);
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

end package body ref_cnn_pkg;
