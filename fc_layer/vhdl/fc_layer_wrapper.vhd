library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library WORK;
    use WORK.fc_layer_wrapper_pkg.ALL;

entity fc_layer_wrapper is
    Port (
        din : in std_logic_vector(L4_NO_INPUTS * L4_DATA_WIDTH - 1 downto 0);
		dout : out std_logic_vector(L4_NO_OUTPUTS * L4_RESULT_WIDTH - 1 downto 0);
		clk : in std_logic;
		rst : in std_logic;
		ce : in std_logic
    );
end fc_layer_wrapper;

architecture Structural of fc_layer_wrapper is

    constant kernels_filename : string := "/home/hrabovsky/vivado_workspace/cnn/ref_cnn/misc/kernels/l4_fc_kernels.mif";

    signal w : std_logic_vector(L4_NO_OUTPUTS * L4_NO_INPUTS * L4_COEF_WIDTH - 1 downto 0);
    signal k : L4_KERNEL_MAP_T;

begin

    k <= Init_L4_Kernel(kernels_filename);
    gen_l4_kernel_map : for I in 0 to L4_NO_OUTPUTS - 1 generate
        w((I+1) * L4_NO_INPUTS * L4_COEF_WIDTH - 1 downto I * L4_NO_INPUTS * L4_COEF_WIDTH) <= k(I);
    end generate gen_l4_kernel_map;

    fc_layer_inst : fc_layer
        generic map (
            NO_INPUTS => L4_NO_INPUTS,
            NO_OUTPUTS => L4_NO_OUTPUTS,
            DATA_INTEGER_WIDTH => L4_DATA_INTEGER_WIDTH,
            DATA_FRACTION_WIDTH => L4_DATA_FRACTION_WIDTH,
            COEF_INTEGER_WIDTH => L4_COEF_INTEGER_WIDTH,
            COEF_FRACTION_WIDTH => L4_COEF_FRACTION_WIDTH,
            RESULT_INTEGER_WIDTH => L4_RESULT_INTEGER_WIDTH,
            RESULT_FRACTION_WIDTH => L4_RESULT_FRACTION_WIDTH
        )
        port map (
            din => din,
            w => w,
            dout => dout,
            clk => clk,
            rst => rst,
            ce => ce
        );

end Structural;
