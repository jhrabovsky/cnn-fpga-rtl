library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;

library WORK;
    use WORK.CONV_LAYER_WRAPPER_PKG.ALL;

entity conv_layer_wrapper_2 is
    Port (
        din : in std_logic_vector(L2_NO_INPUT_MAPS * L2_DATA_WIDTH - 1 downto 0);
        dout : out std_logic_vector(L2_NO_OUTPUT_MAPS * L2_RESULT_WIDTH - 1 downto 0);
        clk : in std_logic;
        rst : in std_logic;
        valid_in : in std_logic;
        valid_out : out std_logic
    );
end conv_layer_wrapper_2;

architecture Structural of conv_layer_wrapper_2 is

    constant kernels_filename : string := "/home/hrabovsky/vivado_workspace/cnn/ref_cnn/misc/kernels/l2_conv_kernels.mif";
    signal w : std_logic_vector(L2_NO_INPUT_MAPS * L2_NO_OUTPUT_MAPS * (L2_KERNEL_SIZE**2) * L2_COEF_WIDTH - 1 downto 0);
    signal k : L2_KERNEL_MAP_T;

    signal dout_conv : std_logic_vector(dout'range);
    
begin

    k <= Init_L2_Kernel(kernels_filename);
    gen_kernel_map : for I in 0 to L2_NO_INPUT_MAPS * L2_NO_OUTPUT_MAPS - 1 generate
        w((I+1) * (L2_KERNEL_SIZE**2) * L2_COEF_WIDTH - 1 downto I * (L2_KERNEL_SIZE**2) * L2_COEF_WIDTH) <= k(I);
    end generate gen_kernel_map;

    conv_layer_inst : conv_layer
        generic map (
            NO_INPUT_MAPS => L2_NO_INPUT_MAPS,
            NO_OUTPUT_MAPS => L2_NO_OUTPUT_MAPS,
            INPUT_ROW_SIZE => L2_MAP_ROW_LEN,
            KERNEL_SIZE => L2_KERNEL_SIZE,
            DATA_INTEGER_WIDTH => L2_DATA_INTEGER_LEN,
            DATA_FRACTION_WIDTH => L2_DATA_FRACTION_LEN,
            COEF_INTEGER_WIDTH => L2_COEF_INTEGER_LEN,
            COEF_FRACTION_WIDTH => L2_COEF_FRACTION_LEN,
            RESULT_INTEGER_WIDTH => L2_RESULT_INTEGER_LEN,
            RESULT_FRACTION_WIDTH => L2_RESULT_FRACTION_LEN
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
        
        activation_function_2: for I in 0 to L2_NO_OUTPUT_MAPS - 1 generate
          relu_inst : relu
                generic map (
                    WIDTH => L2_RESULT_WIDTH
                )
                port map (
                    din => dout_conv((I+1) * L2_RESULT_WIDTH - 1 downto I * L2_RESULT_WIDTH),
                    dout => dout((I+1) * L2_RESULT_WIDTH - 1 downto I * L2_RESULT_WIDTH)
                );
        end generate activation_function_2;

end Structural;
