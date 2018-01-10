library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use STD.TEXTIO.ALL;

entity top is
    Port ( 
        CLK100MHZ: in std_logic;
        RST: in std_logic;
        DOUT_VLD: out std_logic;
        DOUT: out std_logic_vector(16 * 19 - 1 downto 0)  
    );
end top;

architecture RTL of top is

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
	
--------------------------
--      COMPONENTS      --
--------------------------

component mem_reader is
    generic (
        FILENAME : string;
        DATA_LEN : natural;
        ADDR_LEN : natural;
        NO_ITEMS : natural
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        en : in std_logic;
        data : out std_logic_vector(DATA_LEN - 1 downto 0);
        ts : out std_logic
    );
end component;

component conv_layer is
	Generic (
		NO_INPUT_MAPS : natural;
		NO_OUTPUT_MAPS : natural;		
		INPUT_ROW_SIZE : natural;
		KERNEL_SIZE : natural;
		DATA_INTEGER_WIDTH : natural; -- including sign bit
		DATA_FRACTION_WIDTH : natural;
		COEF_INTEGER_WIDTH : natural; -- including sign bit
		COEF_FRACTION_WIDTH : natural;
		RESULT_INTEGER_WIDTH : natural; -- including sign bit
		RESULT_FRACTION_WIDTH : natural
	);

	Port (
		din : in std_logic_vector(NO_INPUT_MAPS * (DATA_INTEGER_WIDTH + DATA_FRACTION_WIDTH) - 1 downto 0);
        w : in std_logic_vector(NO_OUTPUT_MAPS * NO_INPUT_MAPS * (KERNEL_SIZE**2) * (COEF_INTEGER_WIDTH + COEF_FRACTION_WIDTH) - 1 downto 0);
        dout : out std_logic_vector(NO_OUTPUT_MAPS * (RESULT_INTEGER_WIDTH + RESULT_FRACTION_WIDTH) - 1 downto 0);
        clk : in std_logic;
        rst : in std_logic;
        coef_load : in std_logic;
        valid_in : in std_logic;
        valid_out : out std_logic
	);
end component;

-------------------------------
--      CONSTANTS - LAYER 1  --
-------------------------------

constant NO_INPUT_MAPS : natural := 1;
constant NO_OUTPUT_MAPS : natural := 16;
constant IMAGE_ROW_LEN : natural := 9;
constant KERNEL_SIZE : natural := 3;

--------------------------
--      DATA FORMAT     --
--------------------------

constant DATA_INTEGER_LEN : natural := 1; 
constant DATA_FRACTION_LEN : natural := 8;
constant DATA_WIDTH : natural := DATA_INTEGER_LEN + DATA_FRACTION_LEN;

--------------------------
--      COEF FORMAT     --
--------------------------

constant COEF_INTEGER_LEN : natural := 1; 
constant COEF_FRACTION_LEN : natural := 4;
constant COEF_WIDTH : natural := COEF_INTEGER_LEN + COEF_FRACTION_LEN;

--------------------------
--      RESULT FORMAT   --
--------------------------

constant RESULT_INTEGER_LEN : natural := 7; 
constant RESULT_FRACTION_LEN : natural := 12;
constant RESULT_WIDTH : natural := RESULT_INTEGER_LEN + RESULT_FRACTION_LEN;

--------------------------
--      MEMORY FORMAT   --
--------------------------

constant NO_IMAGES : natural := 10;
constant NO_INPUTS : natural := NO_IMAGES * (IMAGE_ROW_LEN ** 2);
constant ROM_ADDR_LEN : natural := log2c(NO_INPUTS);
constant ROM_DATA_LEN : natural := DATA_WIDTH;

type STATE_T is (init, load, compute);

type KERNEL_MAP_T is array(0 to NO_OUTPUT_MAPS - 1) of std_logic_vector((KERNEL_SIZE**2) * COEF_WIDTH - 1 downto 0);

impure function InitKERNEL(FileName : in string) return KERNEL_MAP_T is
    FILE kernelFile : text is in FileName;
    variable kernelLine : line;
    variable kernelMap : KERNEL_MAP_T;
    variable bitvector : bit_vector((KERNEL_SIZE**2) * COEF_WIDTH - 1 downto 0);
begin
    for I in kernelMap'RANGE loop
        if (endfile(kernelFile)) then
            kernelMap(I) := (others => '0');
        else
            readline(kernelFile, kernelLine);
            read(kernelLine, bitvector);
            kernelMap(I) := to_stdlogicvector(bitvector);
        end if;
    end loop;  
    return kernelMap;    
end function;

signal w : std_logic_vector(NO_OUTPUT_MAPS * (KERNEL_SIZE**2) * COEF_WIDTH - 1 downto 0);
signal kernel_map : KERNEL_MAP_T;

signal mem_ce : std_logic;
signal mem_data : std_logic_vector(ROM_DATA_LEN - 1 downto 0);
signal mem_addr : std_logic_vector(ROM_ADDR_LEN - 1 downto 0);
signal mem_ts : std_logic;

signal valid_in_next, valid_in_reg : std_logic;
signal coef_load : std_logic;
signal valid_out : std_logic;
signal result : std_logic_vector(NO_OUTPUT_MAPS * RESULT_WIDTH - 1 downto 0); 

signal state_reg : STATE_T := init;
signal state_next : STATE_T;

begin

    DOUT <= result;
    DOUT_VLD <= valid_out;

    kernel_map <= InitKERNEL("misc/kernels.mif");
    gen_kernel_map : for I in 0 to NO_OUTPUT_MAPS - 1 generate
            w((I+1) * (KERNEL_SIZE**2) * COEF_WIDTH - 1 downto I * (KERNEL_SIZE**2) * COEF_WIDTH) <= kernel_map(I);
    end generate gen_kernel_map;
    
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
  
    --------------------------
    --      CONV LAYER      --
    --------------------------

    conv_layer_inst : conv_layer
        generic map (
            NO_INPUT_MAPS => NO_INPUT_MAPS,
            NO_OUTPUT_MAPS => NO_OUTPUT_MAPS,        
            INPUT_ROW_SIZE => IMAGE_ROW_LEN,
            KERNEL_SIZE => KERNEL_SIZE,
            DATA_INTEGER_WIDTH => DATA_INTEGER_LEN, 
            DATA_FRACTION_WIDTH => DATA_FRACTION_LEN,
            COEF_INTEGER_WIDTH => COEF_INTEGER_LEN, 
            COEF_FRACTION_WIDTH => COEF_FRACTION_LEN,
            RESULT_INTEGER_WIDTH => RESULT_INTEGER_LEN, 
            RESULT_FRACTION_WIDTH => RESULT_FRACTION_LEN
        )
        port map (
            din => mem_data,
            w => w,
            dout => result,
            clk => CLK100MHZ,
            rst => RST,
            coef_load => coef_load,
            valid_in => valid_in_reg,
            valid_out => valid_out
        );
    
    --------------------------------------
    --      FSM - CONTROL PROCESSING    --
    --------------------------------------
    
    valid_in_next <= mem_ce;
    
    regs : process (CLK100MHZ) is
    begin
        if (rising_edge(CLK100MHZ)) then
            if (RST = '1') then
                state_reg <= init;
                valid_in_reg <= '0';
            else
                state_reg <= state_next;
                valid_in_reg <= valid_in_next;
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
