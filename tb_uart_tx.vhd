library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_uart_tx is
end tb_uart_tx;

architecture Behavioral of tb_uart_tx is
constant CLK_FREQ : integer := 27_000_000;
constant BAUD_RATE : integer := 115_200;
constant CLK_PERIOD : time := 37.037 ns;

signal clk : std_logic;
signal rst : std_logic;
signal tx_start : std_logic;
signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
signal tx_line : std_logic;
signal tx_busy : std_logic;

begin

uut : entity work.uart_tx
generic map (
CLK_FREQ => CLK_FREQ,
BAUD_RATE => BAUD_RATE
)
port map (
clk => clk,
rst => rst,
tx_start => tx_start,
tx_data => tx_data,
tx_line => tx_line,
tx_busy => tx_busy
);

-- saat üreteci tang nano için
clk_process : process
begin
clk <= '0';
wait for CLK_PERIOD / 2;
clk <= '1';
wait for CLK_PERIOD / 2;
end process;

-- test senaryosu
stim_process : process
begin
--1 başlangıç reset 
rst <= '1';
wait for 100 ns;
rst <= '0';
wait for 100 ns;

--2 ilk bayt gönderim 0x55 (01010101 - LSB ilk çıkacağı için 1-0-1-0-1-0-1-0)
wait until rising_edge(clk);
tx_data <= x"55";
tx_start <= '1';
wait until rising_edge(clk);
tx_start <= '0';

-- gönderim bitene kadar bekle
wait until tx_busy = '0';
wait for 20 us;

--3. ikinci bayt gönderim 0x41 (ASCII 'A' -> 01000001 -> LSB ilk: 1-0-0-0-0-0-1-0)
wait until rising_edge(clk);
tx_data <= x"41";
tx_start <= '1';
wait until rising_edge(clk);
tx_start <= '0';

wait until tx_busy = '0';
wait for 20 us;

-- simülasyonu durdur
assert false report "simülasyon tamamlandı" severity failure;
end process;

end Behavioral;
