library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;

library WORK;
    use WORK.CONV_LAYER_WRAPPER_PKG.ALL;

entity conv_layer_wrapper_3 is
    Port (
        din : in std_logic_vector(L3_NO_INPUT_MAPS * L3_DATA_WIDTH - 1 downto 0);
        dout : out std_logic_vector(L3_NO_OUTPUT_MAPS * L3_RESULT_WIDTH - 1 downto 0);
        clk : in std_logic;
        rst : in std_logic;
        valid_in : in std_logic;
        valid_out : out std_logic
    );
end conv_layer_wrapper_3;

architecture Structural of conv_layer_wrapper_3 is

    constant kernels_filename : string := "/home/hrabovsky/vivado_workspace/cnn/ref_cnn/misc/kernels/l3_conv_kernels.mif";

    signal w : std_logic_vector(L3_NO_INPUT_MAPS * L3_NO_OUTPUT_MAPS * (L3_KERNEL_SIZE**2) * L3_COEF_WIDTH - 1 downto 0);
    signal k : L3_KERNEL_MAP_T;

    signal dout_conv : std_logic_vector(dout'range);
    
begin

    k <= Init_L3_Kernel(kernels_filename);
    gen_l3_kernel_map : for I in 0 to L3_NO_INPUT_MAPS * L3_NO_OUTPUT_MAPS - 1 generate
        w((I+1) * (L3_KERNEL_SIZE**2) * L3_COEF_WIDTH - 1 downto I * (L3_KERNEL_SIZE**2) * L3_COEF_WIDTH) <= k(I);
    end generate gen_l3_kernel_map;

    conv_layer_inst : conv_layer
        generic map (
            NO_INPUT_MAPS => L3_NO_INPUT_MAPS,
            NO_OUTPUT_MAPS => L3_NO_OUTPUT_MAPS,
            INPUT_ROW_SIZE => L3_MAP_ROW_LEN,
            KERNEL_SIZE => L3_KERNEL_SIZE,
            DATA_INTEGER_WIDTH => L3_DATA_INTEGER_LEN,
            DATA_FRACTION_WIDTH => L3_DATA_FRACTION_LEN,
            COEF_INTEGER_WIDTH => L3_COEF_INTEGER_LEN,
            COEF_FRACTION_WIDTH => L3_COEF_FRACTION_LEN,
            RESULT_INTEGER_WIDTH => L3_RESULT_INTEGER_LEN,
            RESULT_FRACTION_WIDTH => L3_RESULT_FRACTION_LEN
        )
        port map (
            din => din,
            w => w,
            dout => dout_conv,
            clk => clk,
            rst => rst,
            coef_load => '1',
            valid_in => valid_in,
            valid_out => valid_out
        );

        activation_function_3: for I in 0 to L3_NO_OUTPUT_MAPS - 1 generate
          relu_inst : relu
                generic map (
                    WIDTH => L3_RESULT_WIDTH
                )
                port map (
                    din => dout_conv((I+1) * L3_RESULT_WIDTH - 1 downto I * L3_RESULT_WIDTH),
                    dout => dout((I+1) * L3_RESULT_WIDTH - 1 downto I * L3_RESULT_WIDTH)
                );
        end generate activation_function_3;

end Structural;
