library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_uart_top is
end tb_uart_top;

architecture Behavioral of tb_uart_top is

constant CLK_FREQ   : integer := 27_000_000;
constant BAUD_RATE  : integer := 115_200;
constant CLK_PERIOD : time    := 37.037 ns;

signal clk         : std_logic := '0';
signal rst         : std_logic := '0';
signal serial_loop : std_logic; -- tx_line ile rx_line arasindaki dis kopru

signal tx_start    : std_logic := '0';
signal tx_data     : std_logic_vector(7 downto 0) := (others => '0');
signal tx_busy     : std_logic;

signal rx_data     : std_logic_vector(7 downto 0);
signal rx_valid    : std_logic;

begin

clk_process : process
begin
clk <= '0';
wait for CLK_PERIOD / 2;
clk <= '1';
wait for CLK_PERIOD / 2;
end process;

-- tx rx toplu modülü
uut : entity work.uart_top
generic map (
CLK_FREQ  => CLK_FREQ,
BAUD_RATE => BAUD_RATE
)
port map (
clk      => clk,
rst      => rst,
rx_line  => serial_loop,
tx_line  => serial_loop,
tx_start => tx_start,
tx_data  => tx_data,
tx_busy  => tx_busy,
rx_data  => rx_data,
rx_valid => rx_valid
);

-- Test
stim_proc : process
begin
rst <= '1';
wait for 100 ns;
rst <= '0';
wait for 100 ns;

-- 0x42 gonder ve Geri Oku
tx_data  <= x"42";
tx_start <= '1';
wait for CLK_PERIOD;
tx_start <= '0';

wait until rx_valid = '1';
wait for CLK_PERIOD;

assert rx_data = x"42"
report "HATA: uart_top uzerinden 0x42 okunamadi!"
severity error;

report "BASARILI: uart_top tam cift yonlu (full-duplex) testten gecti!" severity note;
wait;
end process;

end Behavioral;