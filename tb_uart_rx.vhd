library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_uart_rx is
end tb_uart_rx;

architecture Behavioral of tb_uart_rx is
constant CLK_FREQ : integer := 27_000_000;
constant BAUD_RATE : integer := 115_200;
constant CLK_PERIOD : time := 37.037 ns;

signal clk : std_logic := '0';
signal rst : std_logic := '0';

--verici tx sinyalleri
signal tx_start : std_logic := '0';
signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
signal tx_busy : std_logic;

--ortak fiziksel seri hat
signal serial_line : std_logic;

--alıcı rx sinyalleri
signal rx_data : std_logic_vector(7 downto 0);
signal rx_valid : std_logic;

begin

clk_process : process
begin
clk <= '0';
wait for CLK_PERIOD / 2;
clk <= '1';
wait for CLK_PERIOD / 2;
end process;

 
uut_tx : entity work.uart_tx
generic map (
CLK_FREQ => CLK_FREQ,
BAUD_RATE => BAUD_RATE
)
port map (
clk => clk,
rst => rst, 
tx_start => tx_start,
tx_data => tx_data,
tx_line => serial_line,
tx_busy => tx_busy
);


uut_rx : entity work.uart_rx
generic map (
CLK_FREQ => CLK_FREQ,
BAUD_RATE => BAUD_RATE
)
port map (
clk => clk,
rst => rst,
rx_line => serial_line,
rx_data => rx_data,
rx_valid => rx_valid
);

-- test senaryosu
stim_proc : process
begin 
rst <= '1';
wait for 100 ns;
rst <= '0';
wait for 100 ns;

-- veriyi yolla ve al
tx_data <= x"41";
tx_start <= '1';
wait for CLK_PERIOD;
tx_start <= '0';

--rx modülünü alana kadar bekle
wait until rx_valid <= '1';
wait for CLK_PERIOD;

assert rx_data = x"41"
report "Hata: 0x41 beklendi fakat baska veri geldi"
severity error;

report "Basarili 0x41 loopback uzerinden dogrudan alindi" severity note;
wait for 20 us;

-- yeni veriyi yolla ve al
tx_data <= x"55";
tx_start <= '1';
wait for CLK_PERIOD;
tx_start <= '0';

wait until rx_valid <= '1';
wait for CLK_PERIOD;

assert rx_data = x"55"
report "Hata: 0x55 beklendi fakat baska veri aldık"
severity error;

report "Basarili 0x55 loopback uzerinden dogrudan alindi" severity note;
wait for 20 us;

report "Tum rx loopbacklari basariyla geldi" severity note;
wait;
end process;

end Behavioral;