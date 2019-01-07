library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

library WORK;
    use WORK.CONV_LAYER_PKG.ALL;

entity conv_2d is
    Generic(
        INPUT_ROW_LENGTH : integer := 32;
        KERNEL_SIZE : integer := 5;
        DATA_WIDTH : natural := 9;
        DATA_FRAC_LEN : natural := 0;
        COEF_WIDTH : natural := 8;
        COEF_FRAC_LEN : natural := 7;
        RESULT_WIDTH : natural := 9;
        RESULT_FRAC_LEN : natural := 0
    );

    Port (
        din : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        w : in std_logic_vector(COEF_WIDTH * (KERNEL_SIZE**2) - 1 downto 0);
        dout : out std_logic_vector(RESULT_WIDTH - 1 downto 0);
        clk : in std_logic;
        ce : in std_logic;
        coef_load : in std_logic;
        rst : in std_logic
    );
end conv_2d;

architecture rtl of conv_2d is

-- TODO: add bias to the first SE of the chain

signal dp_from_se : std_logic_vector(RESULT_WIDTH * KERNEL_SIZE - 1 downto 0);

constant BASE_DELAY_LENGTH : integer := abs(INPUT_ROW_LENGTH - 2*KERNEL_SIZE + 1);
signal from_buffer : std_logic_vector(RESULT_WIDTH * (KERNEL_SIZE - 1) - 1 downto 0);
signal from_adder : std_logic_vector(RESULT_WIDTH * (KERNEL_SIZE - 1) - 1 downto 0);
signal from_switch : std_logic_vector(RESULT_WIDTH * KERNEL_SIZE - 1 downto 0);

signal dout_reg, dout_next : std_logic_vector(RESULT_WIDTH - 1 downto 0);

begin

---------------------------------------------
--            PART 1                       --
---------------------------------------------

    se_chain_inst : se_chain
        generic map (
            KERNEL_SIZE => KERNEL_SIZE,
            DATA_WIDTH => DATA_WIDTH,
            DATA_FRAC_LEN => DATA_FRAC_LEN,
            COEF_WIDTH => COEF_WIDTH,
            COEF_FRAC_LEN => COEF_FRAC_LEN,
            RESULT_WIDTH => RESULT_WIDTH,
            RESULT_FRAC_LEN => RESULT_FRAC_LEN
        )
        port map (
            din => din,
            w => w,
            dp => dp_from_se,
            clk => clk,
            ce => ce,
            coef_load => coef_load,
            rst => rst
        );

---------------------------------------------
--            PART 2                       --
---------------------------------------------

    switching_block_inst : switching_block
        generic map (
            INPUT_ROW_LENGTH => INPUT_ROW_LENGTH,
            KERNEL_SIZE => KERNEL_SIZE,
            RESULT_WIDTH => RESULT_WIDTH
        )
        port map (
            dp_in => dp_from_se,
            add_out => from_switch
        );

    gen_delay_buffers: for I in (KERNEL_SIZE - 2) downto 0 generate

        last_buffer_without_adder_gen: if (I = KERNEL_SIZE - 2) generate
            delay_buffer_last : delay_buffer
                generic map (
                    LENGTH => BASE_DELAY_LENGTH,
                    DATA_WIDTH => RESULT_WIDTH
                )
                port map (
                    din => from_switch(RESULT_WIDTH * (I+2) - 1 downto RESULT_WIDTH * (I+1)),
                    dout => from_buffer(RESULT_WIDTH * (I+1) - 1 downto RESULT_WIDTH * I),
                    clk => clk,
                    ce => ce
                );
        end generate;

        other_buffers_gen: if (I < KERNEL_SIZE - 2) generate
            delay_buffer_i : delay_buffer
                generic map (
                    LENGTH => BASE_DELAY_LENGTH,
                    DATA_WIDTH => RESULT_WIDTH
                )
                port map (
                    din => from_adder(RESULT_WIDTH * (I+2) - 1 downto RESULT_WIDTH * (I+1)),
                    dout => from_buffer(RESULT_WIDTH * (I+1) - 1 downto RESULT_WIDTH * I),
                    clk => clk,
                    ce => ce
                );
        end generate;

    end generate;

    gen_adders: for I in (KERNEL_SIZE - 2) downto 0 generate
        adder_i : adder
            generic map (
                DATA_WIDTH => RESULT_WIDTH
            )
            port map (
                din_a => from_switch(RESULT_WIDTH * (I+1) - 1 downto RESULT_WIDTH * I),
                din_b => from_buffer(RESULT_WIDTH * (I+1) - 1 downto RESULT_WIDTH * I),
                dout => from_adder(RESULT_WIDTH * (I+1) - 1 downto RESULT_WIDTH * I)
            );
    end generate;

    dout_next <= from_adder(RESULT_WIDTH - 1 downto 0);

---------------------------------------------
--            REGISTERS                    --
---------------------------------------------

	registers: process(clk) is
	begin
		if (rising_edge(clk)) then
			if (ce = '1') then
				dout_reg <= dout_next;
			end if;
		end if;
	end process registers;

    dout <= dout_reg;

end rtl;
