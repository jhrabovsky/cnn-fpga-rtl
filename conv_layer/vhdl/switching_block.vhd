-- SWITCHING BLOCK provides binding of partial products (DPi) as outputs
-- from SE blocks to Adders regarding the size of Kernel and Input Map.

library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;

entity switching_block is
	Generic (
		INPUT_ROW_LENGTH : natural;
		KERNEL_SIZE : natural;
		RESULT_WIDTH : natural
	);
	Port (
		dp_in : in std_logic_vector(KERNEL_SIZE * RESULT_WIDTH - 1 downto 0);
		add_out : out std_logic_vector(KERNEL_SIZE * RESULT_WIDTH - 1 downto 0)
	);
end switching_block;

architecture rtl of switching_block is

constant THRESHOLD : natural := INPUT_ROW_LENGTH - 2*KERNEL_SIZE + 1;

begin

	mux_gen: for I in 0 to KERNEL_SIZE - 1 generate
		add_out((I+1) * RESULT_WIDTH - 1 downto I * RESULT_WIDTH) <=
			dp_in((I+1) * RESULT_WIDTH - 1 downto I * RESULT_WIDTH) when THRESHOLD >= 0 else
			dp_in((KERNEL_SIZE - I) * RESULT_WIDTH - 1 downto (KERNEL_SIZE - I - 1) * RESULT_WIDTH);
	end generate;

end rtl;
