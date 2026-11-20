library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_top is
generic (
CLK_FREQ : integer := 27_000_000;
BAUD_RATE : integer := 115_200
);
port (
clk : in std_logic;
rst : in std_logic;

-- uart hatlari
rx_line : in std_logic;
tx_line : out std_logic;

-- tx
tx_data : in std_logic_vector(7 downto 0);
tx_busy : out std_logic;
tx_start : in std_logic;

--rx
rx_data : out std_logic_vector(7 downto 0);
rx_valid : out std_logic
);
end uart_top;

architecture structural of uart_top is
begin 

--tx modülü
uut_uart_tx : entity work.uart_tx
generic map (
CLK_FREQ => CLK_FREQ,
BAUD_RATE => BAUD_RATE
)
port map (
clk => clk,
rst => rst,
tx_start => tx_start,
tx_line => tx_line,
tx_data => tx_data,
tx_busy => tx_busy
);

uut_uart_rx : entity work.uart_rx
generic map (
CLK_FREQ => CLK_FREQ, 
BAUD_RATE => BAUD_RATE
)
port map (
clk => clk,
rst => rst,
rx_line => rx_line,
rx_data => rx_data,
rx_valid => rx_valid
);
end structural;
