library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_uart_fifo_top is
end tb_uart_fifo_top;

architecture Behavioral of tb_uart_fifo_top is

--sabitler
constant CLK_FREQ : integer := 27_000_000;
constant BAUD_RATE : integer := 115_200;
constant CLK_PERIOD : time := 37.037 ns; -- 1 saat vurus bekleme suresi 1/27000000
constant BIT_PERIOD : time := 8680.55 ns; -- 1 uart bitinin havda kalma süresi 1/115.200

-- ust modul bacaklarina baglanacak sanal kablolar
signal clk : std_logic := '0';
signal rst : std_logic := '0';
signal rx_line : std_logic := '1'; -- bilgisayardan fpga'Ya giden hat
signal tx_line : std_logic; -- fpga'dan bilgisayar donen hat
signal fifo_empty : std_logic;
signal fifo_fully : std_logic;

-- test icin 4 harflik BATU mesaj dizim
type msg_array is array (0 to 3) of std_logic_vector(7 downto 0);
constant TEST_MSG : msg_array := (
	x"42",  --0. bayt B harfi asscide 0x42
	x"41",  --1. bayt A harfi 0x41
	x"54",  --2. bayt T 0x54
	x"55"   --3. bayt U 0x55
);
-- bilgisayarmis gibi rx_line hattindan 1 bayt seri veri basan alt yordam
procedure send_uart_byte (
constant data_in : in std_logic_vector(7 downto 0); -- gonderilecek 8 bitlik harf
signal tx_out : out std_logic -- veri basacagimiz seri hat rx_line
) is
begin
tx_out <= '0'; --1. start bit: hatti 1 bit suresi boyunca 0'a cek
wait for BIT_PERIOD;

for i in 0 to 7 loop  --2 data bitleri lsbden baslayip 8 biti sirayla yolluyorum
tx_out <= data_in(i); --i. biti hatta koy
wait for BIT_PERIOD;
end loop;

tx_out <= '1'; --3 stop bit: hatti tekrar 1'e cek
wait for BIT_PERIOD;
end procedure;

--fpga'nin tx_line cikisindan donen seri sinyali yakalayip 8 bite ceviren yardimci alt yordam
procedure receive_uart_byte (
signal rx_in : in std_logic; -- dinlenecek seri hat (tx_line)
variable data_out : out std_logic_vector(7 downto 0) -- yakalanan 8 bitlik harf
) is
begin 
wait until rx_in = '0'; -- start bitinin dusen kenarini 1'den 0'a inisini bekle
wait for BIT_PERIOD / 2;

for i in 0 to 7 loop --8 veri bitinin her birini tam ortasindan ornekle
wait for BIT_PERIOD; -- bir sonraki bitin ortasina atla
data_out(i) := rx_in; -- o andaki hat degerini degiskene kaydet
end loop;

wait for BIT_PERIOD; --stop bitinin ortasina kadar bekle ve islemi bitir
end procedure;

begin

clk_process : process
begin
clk <= '0';
wait for CLK_PERIOD / 2;
clk <= '1';
wait for CLK_PERIOD / 2;
end process;

-- test edilecek tum sistem (uart_fifo_top)
uut : entity work.uart_fifo_top
generic map (
CLK_FREQ => CLK_FREQ,
BAUD_RATE => BAUD_RATE,
DATA_WIDTH => 8,
FIFO_DEPTH => 16
)
port map (
clk => clk,
rst => rst,
rx_line => rx_line,
tx_line => tx_line,
fifo_fully => fifo_fully,
fifo_empty => fifo_empty
);

-- bilgisayar gibi BATU gondermeyi baslatan surec (tx stim)
pc_send_proc : process
begin
rst <= '1';
rx_line <= '1';
wait for 200 ns;
rst <= '0';
wait for 1 us;

--bilgisayardan pes pese 4 bayt "B" "A" "T" "U" gonder
for idx in 0 to 3 loop
send_uart_byte(TEST_MSG(idx), rx_line); -- her harfi seri hatta bas
end loop;
wait;
end process;

--fpga'dan geri donen BATU harflerini yakalayip kontrol eden surec rx monitor
pc_recv_proc : process
variable received_byte : std_logic_vector(7 downto 0); -- yakalanan harfi gecici tutacak degisken
begin
wait until rst = '0';

--fpga'nin tx_line cikisindan 4 harfin de geri donmesini bekle ve tek tek dogrula
for idx in 0 to 3 loop
receive_uart_byte(tx_line, received_byte); --tx_line'dan gelen 1 bayti yakala

assert received_byte = TEST_MSG(idx) -- harfler birebir aynı mı kontrol
report "Hata: geri donen bayt beklenen ile ayni degil"
severity error;
end loop;

report "BATU KAYIPSIZ OLARAK RX-FIFO-TX HATTINDAN GERI DONDU" severity note;
wait;
end process;

end Behavioral;
