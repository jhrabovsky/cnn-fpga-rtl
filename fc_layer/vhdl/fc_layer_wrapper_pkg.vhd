library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

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
    
end package fc_layer_wrapper_pkg;
