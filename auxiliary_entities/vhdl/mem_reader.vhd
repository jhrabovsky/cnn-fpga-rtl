library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;
	use STD.TEXTIO.ALL;

entity mem_reader is
	generic (
		FILENAME : string;
		DATA_LEN : natural := 8;
		ADDR_LEN : natural := 4;
		NO_ITEMS : natural := 1 
	);
	port (
		clk : in std_logic;
		rst : in std_logic;
		en : in std_logic;
		data : out std_logic_vector(DATA_LEN - 1 downto 0);
		ts : out std_logic
	);
end mem_reader;

architecture rtl of mem_reader is

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

component rom is
    Generic (
        FILENAME : string;
        DATA_LENGTH : integer;
        ADDR_LENGTH  : integer
    );

    Port (
        clk : in std_logic;
        en : in std_logic;
        addr : in std_logic_vector(ADDR_LENGTH - 1 downto 0);
        data : out std_logic_vector(DATA_LENGTH - 1 downto 0)
    );
end component;

component counter_down is
    Generic (
        THRESHOLD : natural;
        THRESHOLD_WIDTH : natural
    );
    Port ( CLK_IN : in STD_LOGIC;
           RST: in STD_LOGIC;
           EN : in STD_LOGIC;
           COUNT : out STD_LOGIC_VECTOR(THRESHOLD_WIDTH - 1 downto 0);
           TS : out STD_LOGIC
    );
end component;

constant THRESHOLD_WIDTH : natural := log2c(NO_ITEMS - 1);

signal mem_data : std_logic_vector(DATA_LEN - 1 downto 0);
signal mem_addr : std_logic_vector(ADDR_LEN - 1 downto 0);
signal count_tmp : std_logic_vector(THRESHOLD_WIDTH - 1 downto 0);

signal data_reg : std_logic_vector(DATA_LEN - 1 downto 0);
signal data_next : std_logic_vector(DATA_LEN - 1 downto 0); 

begin

	rom_inst : rom
        generic map (
            FILENAME => FILENAME,
            DATA_LENGTH => DATA_LEN,
            ADDR_LENGTH => ADDR_LEN
        )
        port map (
            clk => clk,
            en => en,
            addr => mem_addr,
            data => mem_data
        );

    addr_gen_inst : counter_down
        generic map (
            THRESHOLD => NO_ITEMS - 1,
            THRESHOLD_WIDTH => THRESHOLD_WIDTH
        )
        port map (
            CLK_IN => clk,
            RST => rst,
            EN => en,
            COUNT => count_tmp,
            TS => ts
        );  

--    regs : process (clk) is
--    begin
--        if (rising_edge(clk)) then
--            if (rst = '1') then
--                data_reg <= (others => '0');
--            else
--                data_reg <= data_next;
--            end if;
--        end if;
--    end process regs;

--    data_next <= mem_data;
--    data <= data_reg;

    data <= mem_data;
    
    mem_addr <= count_tmp(ADDR_LEN - 1 downto 0);
  
end rtl;
