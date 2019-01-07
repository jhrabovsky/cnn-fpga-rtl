library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
use STD.TEXTIO.ALL;

library WORK;
    use WORK.REF_CNN_PKG.ALL;

entity cnn_top is
    Port (
        CLK100MHZ: in std_logic;
        RST: in std_logic;
        DOUT_VLD: out std_logic;
        DOUT: out std_logic_vector(16 * 19 - 1 downto 0) -- 19 -> res_width, 16 -> res_count
    );
end cnn_top;

architecture RTL of cnn_top is

--------------------------
--       MEMORY FORMAT  --
--------------------------

constant ROM_ADDR_LEN : natural := log2c(NO_INPUTS);
constant ROM_DATA_LEN : natural := L1_DATA_WIDTH;

signal w1 : std_logic_vector(L1_NO_INPUT_MAPS * L1_NO_OUTPUT_MAPS * (L1_KERNEL_SIZE**2) * L1_COEF_WIDTH - 1 downto 0);
signal k1 : L1_KERNEL_MAP_T;
signal w2 : std_logic_vector(L2_NO_INPUT_MAPS * L2_NO_OUTPUT_MAPS * (L2_KERNEL_SIZE**2) * L2_COEF_WIDTH - 1 downto 0);
signal k2 : L2_KERNEL_MAP_T;

signal coef_load : std_logic;

signal data_v_to_1_next, data_v_to_1_reg : std_logic;
signal data_v_to_2 : std_logic;
signal data_v_to_out : std_logic;

signal res_from_1 : std_logic_vector(L1_NO_OUTPUT_MAPS * L1_RESULT_WIDTH - 1 downto 0);
signal res_from_1_pos : std_logic_vector(L1_NO_OUTPUT_MAPS * L1_RESULT_WIDTH - 1 downto 0);

signal res_from_2 : std_logic_vector(L2_NO_OUTPUT_MAPS * L2_RESULT_WIDTH - 1 downto 0);
signal res_from_2_pos : std_logic_vector(L2_NO_OUTPUT_MAPS * L2_RESULT_WIDTH - 1 downto 0);

type STATE_T is (init, load, compute);

signal state_reg : STATE_T := init;
signal state_next : STATE_T;

---------------------------
--       MEMORY SIGNALS  --
---------------------------

signal mem_ce : std_logic;
signal mem_data : std_logic_vector(ROM_DATA_LEN - 1 downto 0);
signal mem_addr : std_logic_vector(ROM_ADDR_LEN - 1 downto 0);
signal mem_ts : std_logic;

begin

    DOUT <= res_from_2_pos;
    DOUT_VLD <= data_v_to_out;

    k1 <= Init_L1_Kernel("../misc/l1_kernels.mif");
    gen_l1_kernel_map : for I in 0 to L1_NO_INPUT_MAPS * L1_NO_OUTPUT_MAPS - 1 generate
        w1((I+1) * (L1_KERNEL_SIZE**2) * L1_COEF_WIDTH - 1 downto I * (L1_KERNEL_SIZE**2) * L1_COEF_WIDTH) <= k1(I);
    end generate gen_l1_kernel_map;

    k2 <= Init_L2_Kernel("../misc/l2_kernels.mif");
    gen_l2_kernel_map : for I in 0 to L2_NO_INPUT_MAPS * L2_NO_OUTPUT_MAPS - 1 generate
        w2((I+1) * (L2_KERNEL_SIZE**2) * L2_COEF_WIDTH - 1 downto I * (L2_KERNEL_SIZE**2) * L2_COEF_WIDTH) <= k2(I);
    end generate gen_l2_kernel_map;

    --------------------------------
    --      INPUT IMAGE MEMORY    --
    --------------------------------

    image_mem_reader : mem_reader
        generic map (
            FILENAME => "misc/images.mif",
            DATA_LEN => ROM_DATA_LEN,
            ADDR_LEN => ROM_ADDR_LEN,
            NO_ITEMS => NO_INPUTS
        )
        port map (
            clk => CLK100MHZ,
            rst =>RST,
            en => mem_ce,
            data => mem_data,
            ts => mem_ts
        );

    -----------------------------
    --      L1 CONV LAYER      --
    -----------------------------

    l1_inst : conv_layer
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
            din => mem_data,
            w => w1,
            dout => res_from_1,
            clk => CLK100MHZ,
            rst => RST,
            coef_load => coef_load,
            valid_in => data_v_to_1_reg,
            valid_out => data_v_to_2
        );

    -----------------------------
    --      L1 ACTIVATION      --
    -----------------------------

    activation_function_1: for I in 0 to L1_NO_OUTPUT_MAPS - 1 generate
      relu_inst : relu
            generic map (
                WIDTH => L1_RESULT_WIDTH
            )
            port map (
                din => res_from_1_pos((I+1) * L1_RESULT_WIDTH - 1 downto I * L1_RESULT_WIDTH),
                dout => res_from_1_pos((I+1) * L1_RESULT_WIDTH - 1 downto I * L1_RESULT_WIDTH)
            );
    end generate activation_function_1;

    -----------------------------
    --      L2 CONV LAYER      --
    -----------------------------

    l2_inst : conv_layer
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
            din => res_from_1_pos,
            w => w2,
            dout => res_from_2,
            clk => CLK100MHZ,
            rst => RST,
            coef_load => coef_load,
            valid_in => data_v_to_2,
            valid_out => data_v_to_out
        );

    -----------------------------
    --      L2 ACTIVATION      --
    -----------------------------

    activation_function_2: for I in 0 to L2_NO_OUTPUT_MAPS - 1 generate
      relu_inst : relu
            generic map (
                WIDTH => L2_RESULT_WIDTH
            )
            port map (
                din => res_from_2_pos((I+1) * L2_RESULT_WIDTH - 1 downto I * L2_RESULT_WIDTH),
                dout => res_from_2_pos((I+1) * L2_RESULT_WIDTH - 1 downto I * L2_RESULT_WIDTH)
            );
    end generate activation_function_2;

    --------------------------------------
    --      FSM - CONTROL PROCESSING    --
    --------------------------------------

    data_v_to_1_next <= mem_ce;

    regs : process (CLK100MHZ) is
    begin
        if (rising_edge(CLK100MHZ)) then
            if (RST = '1') then
                state_reg <= init;
                data_v_to_1_reg <= '0';
            else
                state_reg <= state_next;
                data_v_to_1_reg <= data_v_to_1_next;
            end if;
        end if;
    end process regs;

    next_state_output : process (state_reg) is
    begin
        state_next <= state_reg;
        coef_load <= '0';
        mem_ce <= '0';

        case state_reg is
            when init =>
                state_next <= load;

            when load =>
                coef_load <= '1';
                state_next <= compute;

            when compute =>
                mem_ce <= '1';

            when others =>
                state_next <= init;
        end case;
    end process next_state_output;

end RTL;
