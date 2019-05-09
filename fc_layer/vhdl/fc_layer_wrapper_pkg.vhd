library STD;
    use STD.TEXTIO.ALL;

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;
    use IEEE.STD_LOGIC_TEXTIO.ALL;

package fc_layer_wrapper_pkg is

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

    type L4_KERNEL_MAP_T is array(0 to L4_NO_OUTPUTS - 1) of std_logic_vector(L4_NO_INPUTS * L4_COEF_WIDTH - 1 downto 0);
    impure function Init_L4_Kernel(FileName : in string) return L4_KERNEL_MAP_T;

end package fc_layer_wrapper_pkg;

package body fc_layer_wrapper_pkg is

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

end package body fc_layer_wrapper_pkg;
