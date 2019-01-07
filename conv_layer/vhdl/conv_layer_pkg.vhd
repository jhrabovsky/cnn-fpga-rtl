library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

package conv_layer_pkg is

    -- PART1 components
    component MADD_FIRST is
        Generic (
            B_MODE : string
        );
        Port (
            b : in std_logic_vector(17 downto 0);
            bcin : in std_logic_vector(17 downto 0);
            a : in std_logic_vector(29 downto 0);
            clk : in std_logic;
            ce : in std_logic;
            coef_load : in std_logic;
            rst : in std_logic;
            bcout : out std_logic_vector(17 downto 0);
            pcout : out std_logic_vector(47 downto 0)
        );
    end component;

    component MADD_IN is
        Port (
            bcin : in std_logic_vector(17 downto 0);
            a : in std_logic_vector(29 downto 0);
            pcin : in std_logic_vector(47 downto 0);
            clk : in std_logic;
            ce : in std_logic;
            coef_load : in std_logic;
            rst : in std_logic;
            bcout : out std_logic_vector(17 downto 0);
            pcout : out std_logic_vector(47 downto 0)
        );
    end component;

    component MADD_LAST is
        Port (
            bcin : in std_logic_vector(17 downto 0);
            bcout : out std_logic_vector(17 downto 0);
            a : in std_logic_vector(29 downto 0);
            pcin : in std_logic_vector(47 downto 0);
            clk : in std_logic;
            ce : in std_logic;
            coef_load : in std_logic;
            rst : in std_logic;
            p : out std_logic_vector(47 downto 0)
        );
    end component;

    component systolic_fir is
        Generic (
            N : integer := 5;
            MODE : string
        );

        Port (
               xn : in std_logic_vector(17 downto 0);
               yn : out std_logic_vector(47 downto 0);
               bcout : out std_logic_vector(17 downto 0);
               W : in std_logic_vector(30 * N - 1 downto 0);
               clk : in std_logic;
               ce : in std_logic;
               coef_load : in std_logic;
               rst : in std_logic
        );
    end component;

    component se_chain is
        Generic (
            -- Number of elements (SE)
            KERNEL_SIZE : integer;
            DATA_WIDTH : natural;
            DATA_FRAC_LEN : natural;
            COEF_WIDTH : natural;
            COEF_FRAC_LEN : natural;
            RESULT_WIDTH : natural;
            RESULT_FRAC_LEN : natural
        );

        Port (
            din : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            w : in std_logic_vector(COEF_WIDTH * (KERNEL_SIZE**2) - 1 downto 0);
            dp : out std_logic_vector(RESULT_WIDTH * KERNEL_SIZE - 1 downto 0);
            clk : in std_logic;
            ce : in std_logic;
            coef_load : in std_logic;
            rst : in std_logic
        );
    end component;

    component conv_2d is
        Generic(
            INPUT_ROW_LENGTH : integer;
            KERNEL_SIZE : integer;
            DATA_WIDTH : natural;
            DATA_FRAC_LEN : natural;
            COEF_WIDTH : natural;
            COEF_FRAC_LEN : natural;
            RESULT_WIDTH : natural;
            RESULT_FRAC_LEN : natural
        );
        Port (
            din : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            w : in std_logic_vector((KERNEL_SIZE**2) * COEF_WIDTH - 1 downto 0);
            dout : out std_logic_vector(RESULT_WIDTH - 1 downto 0);
            clk : in std_logic;
            ce : in std_logic;
            coef_load : in std_logic;
            rst : in std_logic
        );
    end component;


    -- PART2 components
    component switching_block is
        Generic (
            INPUT_ROW_LENGTH : natural;
            KERNEL_SIZE : natural;
            RESULT_WIDTH : natural
        );
        Port (
            dp_in : in std_logic_vector(KERNEL_SIZE * RESULT_WIDTH - 1 downto 0);
            add_out : out std_logic_vector(KERNEL_SIZE * RESULT_WIDTH - 1 downto 0)
        );
    end component;

    component adder is
        Generic (
            DATA_WIDTH : integer
        );

        Port (
            din_a : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            din_b : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            dout : out std_logic_vector(DATA_WIDTH - 1 downto 0)
        );
    end component;

    component delay_buffer is
        Generic (
            LENGTH : natural;
            DATA_WIDTH: natural
        );

        Port (
            din : in std_logic_vector(DATA_WIDTH - 1 downto 0);
            dout : out std_logic_vector(DATA_WIDTH - 1 downto 0);
            clk, ce : in std_logic
        );
    end component;


    component adder_tree is
        Generic (
            NO_INPUTS : natural;
            DATA_WIDTH : natural
        );

        Port (
            din : in std_logic_vector(NO_INPUTS * DATA_WIDTH - 1 downto 0);
            dout : out std_logic_vector(DATA_WIDTH - 1 downto 0);
            clk : in std_logic;
            ce : in std_logic;
            rst : in std_logic
        );
    end component;


    component counter_down_dynamic is
        Generic (
            THRESHOLD_WIDTH : natural
        );

        Port (
            clk : in std_logic;
            ce : in std_logic;
            clear : in std_logic;
            set : in std_logic;
            threshold : in std_logic_vector(THRESHOLD_WIDTH - 1 downto 0);
            -- terminal count
            tc : out std_logic
        );
    end component;

    component fsm is
        Generic (
            INPUT_ROW_LENGTH : integer;
            KERNEL_SIZE : integer
        );

        Port (
            clk : in std_logic;
            rst : in std_logic;
            run : in std_logic;
            valid : out std_logic
        );
    end component;

    function log2c (N : integer) return integer;

end package conv_layer_pkg;

package body conv_layer_pkg is

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

end package body conv_layer_pkg;
