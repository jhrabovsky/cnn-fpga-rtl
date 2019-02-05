library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;

library WORK;
    use WORK.CONV_LAYER_WRAPPER_PKG.ALL;

entity conv_layer_wrapper_1 is
    Port (
        din : in std_logic_vector(L1_NO_INPUT_MAPS * L1_DATA_WIDTH - 1 downto 0);
        dout : out std_logic_vector(L1_NO_OUTPUT_MAPS * L1_RESULT_WIDTH - 1 downto 0);
        clk : in std_logic;
        rst : in std_logic;
        valid_in : in std_logic;
        valid_out : out std_logic
    );
end conv_layer_wrapper_1;

architecture Structural of conv_layer_wrapper_1 is

    constant kernels_filename : string := "/home/hrabovsky/vivado_workspace/cnn/ref_cnn/misc/kernels/l1_conv_kernels.mif";

    signal w : std_logic_vector(L1_NO_INPUT_MAPS * L1_NO_OUTPUT_MAPS * (L1_KERNEL_SIZE**2) * L1_COEF_WIDTH - 1 downto 0);
    signal k : L1_KERNEL_MAP_T;

begin

    k <= Init_L1_Kernel(kernels_filename);
    gen_kernel_map : for I in 0 to L1_NO_INPUT_MAPS * L1_NO_OUTPUT_MAPS - 1 generate
        w((I+1) * (L1_KERNEL_SIZE**2) * L1_COEF_WIDTH - 1 downto I * (L1_KERNEL_SIZE**2) * L1_COEF_WIDTH) <= k(I);
    end generate gen_kernel_map;

    conv_layer_inst : conv_layer
        generic map (
            NO_INPUT_MAPS => L1_NO_INPUT_MAPS,
            NO_OUTPUT_MAPS => L1_NO_OUTPUT_MAPS,
            INPUT_ROW_SIZE => L1_MAP_ROW_LEN,
            KERNEL_SIZE => L1_KERNEL_SIZE,
            DATA_INTEGER_WIDTH => L1_DATA_INTEGER_LEN,
            DATA_FRACTION_WIDTH => L1_DATA_FRACTION_LEN,
            COEF_INTEGER_WIDTH => L1_COEF_INTEGER_LEN,
            COEF_FRACTION_WIDTH => L1_COEF_FRACTION_LEN,
            RESULT_INTEGER_WIDTH => L1_RESULT_INTEGER_LEN,
            RESULT_FRACTION_WIDTH => L1_RESULT_FRACTION_LEN
        )
        port map (
            din => din,
            w => w,
            dout => dout,
            clk => clk,
            rst => rst,
            coef_load => '1',
            valid_in => valid_in,
            valid_out => valid_out
        );

end Structural;
