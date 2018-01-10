library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
use STD.TEXTIO.ALL;
use work.misc_pkg.all;

entity cnn_layer2 is
    Port ( 
        CLK100MHZ: in std_logic;
        RST: in std_logic;
        DOUT_VLD: out std_logic;
        DOUT: out std_logic_vector(3 * 19 - 1 downto 0) -- 19 -> res_width, 16 -> res_count  
    );
end cnn_layer2;

architecture RTL of cnn_layer2 is

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
        DATA_INTEGER_WIDTH : natural; -- zahrna aj znamienkovy bit
        DATA_FRACTION_WIDTH : natural;
        COEF_INTEGER_WIDTH : natural; -- zahrna aj znamienkovy bit
        COEF_FRACTION_WIDTH : natural;
        RESULT_INTEGER_WIDTH : natural; -- zahrna aj znamienkovy bit
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
--      CONSTANTS - LAYER 2  --
-------------------------------

constant L2_NO_INPUT_MAPS : natural := 2;
constant L2_NO_OUTPUT_MAPS : natural := 3;
constant L2_MAP_ROW_LEN : natural := 7;
constant L2_KERNEL_SIZE : natural := 3;

constant L2_DATA_INTEGER_LEN : natural := 3; 
constant L2_DATA_FRACTION_LEN : natural := 8;
constant L2_DATA_WIDTH : natural := L2_DATA_INTEGER_LEN + L2_DATA_FRACTION_LEN;

constant L2_COEF_INTEGER_LEN : natural := 1; 
constant L2_COEF_FRACTION_LEN : natural := 4;
constant L2_COEF_WIDTH : natural := L2_COEF_INTEGER_LEN + L2_COEF_FRACTION_LEN;

constant L2_RESULT_INTEGER_LEN : natural := 7; 
constant L2_RESULT_FRACTION_LEN : natural := 12;
constant L2_RESULT_WIDTH : natural := L2_RESULT_INTEGER_LEN + L2_RESULT_FRACTION_LEN;

--------------------------
--       MEMORY FORMAT  --
--------------------------

constant NO_INPUT_IMAGES : natural := 1;
constant NO_INPUTS : natural := NO_INPUT_IMAGES * (L2_MAP_ROW_LEN ** 2);
constant ROM_ADDR_LEN : natural := log2c(NO_INPUTS);
constant ROM_DATA_LEN : natural := L2_DATA_WIDTH;

type STATE_T is (init, load, compute);

type L2_KERNEL_MAP_T is array(0 to L2_NO_INPUT_MAPS * L2_NO_OUTPUT_MAPS - 1) of std_logic_vector((L2_KERNEL_SIZE**2) * L2_COEF_WIDTH - 1 downto 0);
 
impure function Init_L2_Kernel(FileName : in string) return L2_KERNEL_MAP_T is
    FILE kernelFile : text is in FileName;
    variable kernelLine : line;
    variable kernelMap : L2_KERNEL_MAP_T;
    variable bitvector : bit_vector((L2_KERNEL_SIZE**2) * L2_COEF_WIDTH - 1 downto 0);
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

signal w2 : std_logic_vector(L2_NO_INPUT_MAPS * L2_NO_OUTPUT_MAPS * (L2_KERNEL_SIZE**2) * L2_COEF_WIDTH - 1 downto 0);
signal k2 : L2_KERNEL_MAP_T;

signal coef_load : std_logic;

signal data_v_to_2_next, data_v_to_2_reg : std_logic;
signal data_v_to_out : std_logic;

signal data_in : std_logic_vector(L2_NO_INPUT_MAPS * L2_DATA_WIDTH - 1 downto 0); 

signal res_from_2 : std_logic_vector(L2_NO_OUTPUT_MAPS * L2_RESULT_WIDTH - 1 downto 0); 
signal res_from_2_pos : std_logic_vector(L2_NO_OUTPUT_MAPS * L2_RESULT_WIDTH - 1 downto 0);

signal state_reg : STATE_T := init;
signal state_next : STATE_T;

---------------------------
--       MEMORY SIGNALS  --
---------------------------

signal mem_ce : std_logic;
signal mem_data : std_logic_vector(ROM_DATA_LEN - 1 downto 0);
signal mem_addr : std_logic_vector(ROM_ADDR_LEN - 1 downto 0);
signal mem_ts : std_logic;

signal mem2_ce : std_logic;
signal mem2_data : std_logic_vector(ROM_DATA_LEN - 1 downto 0);
signal mem2_addr : std_logic_vector(ROM_ADDR_LEN - 1 downto 0);
signal mem2_ts : std_logic;

begin

    DOUT <= res_from_2_pos;
    DOUT_VLD <= data_v_to_out;
      
    k2 <= Init_L2_Kernel("misc/l2_kernels.mif");
    gen_l2_kernel_map : for I in 0 to L2_NO_INPUT_MAPS * L2_NO_OUTPUT_MAPS - 1 generate
        w2((I+1) * (L2_KERNEL_SIZE**2) * L2_COEF_WIDTH - 1 downto I * (L2_KERNEL_SIZE**2) * L2_COEF_WIDTH) <= k2(I);
    end generate gen_l2_kernel_map;    
        
    data_in <= mem2_data & mem_data;
    --data_in <= mem_data;
        
    --------------------------------
    --      INPUT IMAGE MEMORY    --
    --------------------------------

    image_mem_reader : mem_reader
        generic map (
            FILENAME => "misc/fm1_in.mif",
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
  
    image_mem2_reader : mem_reader
        generic map (
            FILENAME => "misc/fm2_in.mif",
            DATA_LEN => ROM_DATA_LEN,
            ADDR_LEN => ROM_ADDR_LEN,
            NO_ITEMS => NO_INPUTS
        )  
        port map (
            clk => CLK100MHZ,
            rst =>RST,
            en => mem2_ce,
            data => mem2_data,
            ts => mem2_ts
        );
    
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
            din => data_in,
            w => w2,
            dout => res_from_2,
            clk => CLK100MHZ,
            rst => RST,
            coef_load => coef_load,
            valid_in => data_v_to_2_reg,
            valid_out => data_v_to_out
        );
        
    -----------------------------
    --      L2 ACTIVATION      -- 
    -----------------------------
    
    activation_function_2: for I in 0 to L2_NO_OUTPUT_MAPS - 1 generate
        res_from_2_pos((I+1) * L2_RESULT_WIDTH - 1 downto I * L2_RESULT_WIDTH) <= (others => '0') when (res_from_2((I+1) * L2_RESULT_WIDTH - 1) = '1') else
                          res_from_2((I+1) * L2_RESULT_WIDTH - 1 downto I * L2_RESULT_WIDTH);
    end generate activation_function_2;
        
    --------------------------------------
    --      FSM - CONTROL PROCESSING    --
    --------------------------------------
    
    data_v_to_2_next <= mem_ce;
    
    regs : process (CLK100MHZ) is
    begin
        if (rising_edge(CLK100MHZ)) then
            if (RST = '1') then
                state_reg <= init;
                data_v_to_2_reg <= '0';
            else
                state_reg <= state_next;
                data_v_to_2_reg <= data_v_to_2_next;
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

    mem2_ce <= mem_ce;

end RTL;
