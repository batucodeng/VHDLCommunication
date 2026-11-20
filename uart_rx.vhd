library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
generic (
CLK_FREQ : integer := 27_000_000;
BAUD_RATE : integer := 115_200
);
port (
clk : in std_logic;
rst : in std_logic;
rx_line : in std_logic;
rx_data : out std_logic_vector(7 downto 0);
rx_valid : out std_logic
);
end uart_rx;

architecture Behavioral of uart_rx is
constant BIT_LIMIT : integer := CLK_FREQ / BAUD_RATE;
constant HALF_BIT_LIMIT  : integer := BIT_LIMIT / 2;

type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
signal state : state_type := IDLE;

-- 2--ff senkronizasyon sinyali(hat boşta 1 olduğu için başlangıçta da 1)
signal rx_sync_1 : std_logic := '1';
signal rx_sync_2 : std_logic := '1';

-- sayaçlar 
signal baud_counter : integer range 0 to BIT_LIMIT - 1 := 0;
signal bit_index : integer range 0 to 7 := 0;
signal rx_buffer : std_logic_vector(7 downto 0) := (others => '0');

begin

rx_process : process(clk, rst)
begin
if(rst = '1') then
state <= IDLE;
baud_counter <= 0;
bit_index <= 0;
rx_buffer <= (others => '0');
rx_data <= (others => '0');
rx_valid <= '0';
rx_sync_1 <= '1';
rx_sync_2 <= '1';

elsif rising_edge(clk) then
rx_sync_1 <= rx_line;
rx_sync_2 <= rx_sync_1;

case state is
when IDLE =>
rx_valid <= '0';
baud_counter <= 0;
bit_index <= 0;
if(rx_sync_2 = '0') then
state <= START_BIT;
end if;

when START_BIT =>
if(baud_counter = HALF_BIT_LIMIT - 1) then
if(rx_sync_2 = '0') then
baud_counter <= 0;
state <= DATA_BITS;
else
state <= IDLE;
end if;
else 
baud_counter <= baud_counter + 1;
end if;

when DATA_BITS =>
if(baud_counter = BIT_LIMIT - 1) then
baud_counter <= 0;
rx_buffer(bit_index) <= rx_sync_2;
if(bit_index = 7) then 
bit_index <= 0;
state <= STOP_BIT;
else 
bit_index <= bit_index + 1;
end if;
else
baud_counter <= baud_counter + 1;
end if;
when STOP_BIT =>
if(baud_counter = BIT_LIMIT - 1) then
baud_counter <= 0;
rx_data <= rx_buffer;
rx_valid <= '1';
state <= IDLE;
else 
baud_counter <= baud_counter + 1;
end if;
when others =>
state <= IDLE;
baud_counter <= 0;
bit_index <= 0;
rx_valid <= '0';
end case;
end if;
end process;
end Behavioral;
