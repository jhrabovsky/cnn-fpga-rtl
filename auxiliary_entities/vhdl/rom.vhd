-- SRC: ug901-vivado-synthesis (p146)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;

entity rom is
    Generic (
        FILENAME : string;
        DATA_LENGTH : integer := 12;
        ADDR_LENGTH  : integer := 11
    );

    Port (
        clk : in std_logic;
        en : in std_logic;
        addr : in std_logic_vector(ADDR_LENGTH - 1 downto 0);
        data : out std_logic_vector(DATA_LENGTH - 1 downto 0)
    );
end rom;

architecture Behavioral of rom is

-- bit_vector => read() does not support std_logic_vector
type ROM_T is array (0 to 2**ADDR_LENGTH - 1) of bit_vector(DATA_LENGTH - 1 downto 0);

-- impure function => has a side-effect, i.e. the result does not depend only on output but also on the values of other signals
impure function InitROM(FileName : in string) return ROM_T is
    FILE romFile : text is in FileName;
    variable romLine : line;
    variable ROM_tmp : ROM_T;
begin
    for I in ROM_T'RANGE loop
		  if (endfile(romFile)) then
			  ROM_tmp(I) := (others => '0');
		  else
			  readline(romFile, romLine);
			  read(romLine, ROM_tmp(I));
		  end if;
    end loop;  
    return ROM_tmp;    
end function;

signal rom_mem : ROM_T := InitROM(FILENAME);

-- usage of BLOCK RAM for declared memory (table signal)
attribute rom_style : string;
attribute rom_style of rom_mem : signal is "block";
 
begin
    process(clk) is
    begin
        if (rising_edge(clk)) then
            if(en = '1') then
                -- TEXTIO allows to load only bit-vector from file => need to re-cast the mem output back to std_logic_vector
                data <= to_stdlogicvector(rom_mem(to_integer(unsigned(addr))));
            end if;
        end if;
    end process;

end Behavioral;
