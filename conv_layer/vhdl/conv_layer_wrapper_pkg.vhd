library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package conv_layer_wrapper_pkg is
    
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



end package conv_layer_wrapper_pkg;
