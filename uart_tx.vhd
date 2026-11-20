library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
generic (
CLK_FREQ : integer := 27_000_000;
BAUD_RATE : integer := 115_200
);
port (
clk : in std_logic;
rst : in std_logic;
tx_start : in std_logic;
tx_data : in std_logic_vector(7 downto 0);
tx_line : out std_logic;
tx_busy : out std_logic
);
end uart_tx;

architecture Behavioral of uart_tx is
constant BIT_LIMIT : integer := CLK_FREQ / BAUD_RATE;
type type_state is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
signal state : type_state := IDLE;

signal baud_counter : integer range 0 to BIT_LIMIT - 1 := 0;
signal bit_index : integer range 0 to 7 := 0;
signal tx_buffer : std_logic_vector(7 downto 0) := (others => '0');

begin

tx_process : process(clk, rst)
begin
if(rst = '1') then
state <= IDLE;
baud_counter <= 0;
bit_index <= 0;
tx_buffer <= (others => '0');
tx_line <= '1'; --uart hattı boşta
tx_busy <= '0';

elsif rising_edge(clk) then
case state is

--boşta bekleme
when IDLE =>
tx_line <= '1';
tx_busy <= '0';
baud_counter <= 0;
bit_index <= 0;

if(tx_start = '1') then
tx_buffer <= tx_data;
tx_busy <= '1';
state <= START_BIT;
end if;

--başlangiç biti
when START_BIT =>
tx_line <= '0';
tx_busy <= '1';

if (baud_counter = BIT_LIMIT - 1) then
baud_counter <= 0;
state <= DATA_BITS;
else
baud_counter <= baud_counter + 1;
end if;

--3 veri bitleri
when DATA_BITS =>
tx_line <= tx_buffer(bit_index);
tx_busy <= '1';

if (baud_counter = BIT_LIMIT - 1) then
baud_counter <= 0;
if (bit_index = 7) then
bit_index <= 0;
state <= STOP_BIT;
else
bit_index <= bit_index + 1;
end if;
else
baud_counter <= baud_counter + 1;
end if;

--4 bitiş biti
when STOP_BIT =>
tx_line <= '1';
tx_busy <= '1';

if (baud_counter = BIT_LIMIT - 1) then
baud_counter <= 0;
tx_busy <= '0';
state <= IDLE;
else
baud_counter <= baud_counter + 1;
end if;

when others =>
state <= IDLE;

end case;
end if;
end process;
end Behavioral;


