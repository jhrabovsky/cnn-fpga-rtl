library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;

entity adder_tree is
	Generic (
  		NO_INPUTS : natural := 6;
  		DATA_WIDTH : natural := 8
	);

	Port (
		  din : in std_logic_vector(DATA_WIDTH * NO_INPUTS - 1 downto 0);
      dout : out std_logic_vector(DATA_WIDTH - 1 downto 0);
      clk : in std_logic;
      ce : in std_logic;
      rst : in std_logic
	);
end adder_tree;

architecture rtl of adder_tree is

function log2c (N : integer) return integer is
    variable m, p : integer;
    begin
        m := 0;
        p := 1;

        while p < N loop
            m := m + 1;
            p := p * 2;
        end loop;

        return m;
    end log2c;

constant NO_STAGES : natural := log2c(NO_INPUTS);

type matrix is array(NO_STAGES downto 0) of std_logic_vector(DATA_WIDTH * (2**NO_STAGES) - 1 downto 0);
signal p_next, p_reg : matrix;

begin

	input_gen : for I in 0 to NO_INPUTS generate
		p_next(NO_STAGES)(DATA_WIDTH * NO_INPUTS - 1 downto 0) <= din;
	end generate;

	-- VYPLN vstupov, ak pocet vstupov nie je mocninou 2
	pading_gen : if NO_INPUTS < 2**NO_STAGES generate
		p_next(NO_STAGES)(DATA_WIDTH * (2**NO_STAGES) - 1 downto DATA_WIDTH * NO_INPUTS) <= (others => '0');
	end generate;

	stage_gen : for I in (NO_STAGES - 1) downto 0 generate
		row_gen : for J in 0 to (2**I - 1) generate
			p_next(I)(DATA_WIDTH * J + (DATA_WIDTH - 1) downto DATA_WIDTH * J) <= std_logic_vector(signed(p_reg(I+1)(DATA_WIDTH * (2*J) + (DATA_WIDTH - 1) downto DATA_WIDTH * (2*J))) + signed(p_reg(I+1)(DATA_WIDTH * (2*J + 1) + (DATA_WIDTH - 1) downto DATA_WIDTH * (2*J + 1))));
			-- p(i)(j) ==> p(i)(DATA_WIDTH * (j) + DATA_WIDTH - 1 downto DATA_WIDTH * (j))
		end generate;
	end generate;

	dout <= p_reg(0)(DATA_WIDTH - 1 downto 0);

	regs : process (clk) is
	begin
	   if (rising_edge(clk)) then
	       if (rst = '1') then
	           p_reg <= (others => (others => '0'));
	       elsif (ce = '1') then
	           p_reg <= p_next;
	       end if;
	   end if;
	end process regs;

end rtl;
