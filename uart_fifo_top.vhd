library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_fifo_top is
generic (
CLK_FREQ : integer := 27_000_000;
BAUD_RATE : integer := 115_200;
DATA_WIDTH : integer := 8;
FIFO_DEPTH : integer := 16
);
port (
clk : in std_logic;
rst : in std_logic;
rx_line : in std_logic;
tx_line : out std_logic;
fifo_fully : out std_logic; 
fifo_empty : out std_logic
);
end uart_fifo_top;

architecture Behavioral of uart_fifo_top is

--rx - fifo arasi ic kablolar
signal rx_data_int : std_logic_vector(DATA_WIDTH - 1 downto 0);
signal rx_valid_int : std_logic;

-- fifo - tx arasi ic kablolar
signal fifo_rd_en : std_logic := '0';
signal fifo_rd_data : std_logic_vector(DATA_WIDTH - 1 downto 0);
signal fifo_fully_i : std_logic;
signal fifo_empty_i : std_logic;

-- tx kontrol kablolari
signal tx_start_int : std_logic := '0';
signal tx_busy_int : std_logic;
signal rd_pending : std_logic := '0'; -- fifo okuma gecikmesini hizalamak icin

begin

--durum bayraklarını dış portlara aktar
fifo_fully <= fifo_fully_i;
fifo_empty <= fifo_empty_i;

-- alici modul
inst_uart_rx : entity work.uart_rx
generic map (
CLK_FREQ  => CLK_FREQ,
BAUD_RATE => BAUD_RATE
)
port map (
clk      => clk,
rst      => rst,
rx_line  => rx_line,
rx_data  => rx_data_int,
rx_valid => rx_valid_int
);

-- tAMPON BELLEK (SYNC FIFO)
inst_sync_fifo : entity work.sync_fifo
generic map (
DATA_WIDTH => DATA_WIDTH,
FIFO_DEPTH => FIFO_DEPTH
)
port map (
clk     => clk,
rst     => rst,
wr_en   => rx_valid_int, -- RX bayti yakaladigi an FIFO'ya yaz
wr_data => rx_data_int,
rd_en   => fifo_rd_en,
rd_data => fifo_rd_data,
fully    => fifo_fully_i,
empty   => fifo_empty_i
);

-- 3. VERICI MODUL (UART TX)
inst_uart_tx : entity work.uart_tx
generic map (
CLK_FREQ  => CLK_FREQ,
BAUD_RATE => BAUD_RATE
)
port map (
clk      => clk,
rst      => rst,
tx_start => tx_start_int,
tx_data  => fifo_rd_data,
tx_line  => tx_line,
tx_busy  => tx_busy_int
);

-- 4. FIFO -> TX AKTARIM KONTROL SURECI
bridge_proc : process(clk, rst)
begin
if(rst = '1') then
fifo_rd_en   <= '0';
tx_start_int <= '0';
rd_pending   <= '0';

elsif rising_edge(clk) then
-- Varsayilan pasif degerler (1 cevrimlik tetikler icin)
fifo_rd_en   <= '0';
tx_start_int <= '0';

if(rd_pending = '1') then
-- Onceki cevrimde rd_en verildi, veri su an fifo_rd_data hattinda hazir
tx_start_int <= '1';
rd_pending   <= '0';

elsif(fifo_empty_i = '0' and tx_busy_int = '0') then
-- FIFO'da bekleyen veri var ve verici bosta: 1 bayt cek
fifo_rd_en <= '1';
rd_pending <= '1';
end if;
end if;
end process;

end Behavioral;