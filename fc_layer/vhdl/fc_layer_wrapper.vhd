library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library WORK;
    use WORK.fc_layer_wrapper_pkg.ALL;
    
entity fc_layer_wrapper is
    Port (
        din : in std_logic_vector(L4_NO_INPUTS * L4_DATA_WIDTH - 1 downto 0);
		w : in std_logic_vector(L4_NO_OUTPUTS * L4_NO_INPUTS * L4_COEF_WIDTH - 1 downto 0);
		dout : out std_logic_vector(L4_NO_OUTPUTS * L4_RESULT_WIDTH - 1 downto 0);
		clk : in std_logic;
		rst : in std_logic;
		ce : in std_logic
    );
end fc_layer_wrapper;

architecture Structural of fc_layer_wrapper is

begin

    fc_layer_inst : entity WORK.fc_layer
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
