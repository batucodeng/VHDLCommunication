library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sync_fifo is
generic (
DATA_WIDTH : integer := 8;
FIFO_DEPTH : integer := 16
);
port (
clk : in std_logic;
rst : in std_logic;
wr_en : in std_logic; -- "1" olunca wr_data'daki veri belleğe kaydedilir
wr_data : in std_logic_vector(7 downto 0); -- içeri alıncak 8 bitlik veri
rd_en : in std_logic; -- "1" olunca en eski veri rd_data hattına aktarılır ve bellekten düşülür
rd_data : out std_logic_vector(7 downto 0); -- dışarı aktarılan 8 bitlik veri
fully : out std_logic; -- 16 çekmecede doluysa 1 olur ve daha veri gönderme der
empty : out std_logic -- okunacak veri kalmayınca 1 olur boşta yani
);
end sync_fifo;

architecture Behavioral of sync_fifo is 
--16 cekmeceli 8bitlik dolap
type fifo_array is array (0 to FIFO_DEPTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
signal memory : fifo_array := (others => (others => '0'));

--yazma ve okuma 0dan 15'e
signal wr_ptr : integer range 0 to FIFO_DEPTH - 1 := 0;
signal rd_ptr : integer range 0 to FIFO_DEPTH - 1 := 0;

-- dolapta kaç byte beklediği yazılsın
signal count : integer range 0 to FIFO_DEPTH := 0;

-- ic koruma sinyalleri (doluyken yazmayi , bosken okumayı engeller)
signal wr_valid : std_logic;
signal rd_valid : std_logic;

begin 
--doluluk bayrakları
fully <= '1' when count = FIFO_DEPTH else '0';
empty <= '1' when count = 0 else '0';

-- güvenli yazma ve okuma
wr_valid <= '1' when (wr_en = '1' and count < FIFO_DEPTH) else '0';
rd_valid <= '1' when (rd_en = '1' and count > 0) else '0';

fifo_proc : process(clk, rst)
begin
if(rst = '1') then
memory <= (others => (others => '0'));
wr_ptr <= 0;
rd_ptr <= 0;
count <= 0;
rd_data <= (others => '0');

elsif rising_edge(clk) then
--1 yazma islemi(dolap dolu degilse)
if(wr_valid = '1') then
memory(wr_ptr) <= wr_data;
if(wr_ptr = FIFO_DEPTH - 1) then
wr_ptr <= 0; --15'ten sonra basa don
else
wr_ptr <= wr_ptr + 1;
end if;
end if;

--2 okuma islemi(dolap bos degilse)
if(rd_valid = '1') then
rd_data <= memory(rd_ptr);
if(rd_ptr = FIFO_DEPTH - 1) then
rd_ptr <= 0; -- 15'ten sonra basa don
else
rd_ptr <= rd_ptr + 1;
end if;
end if;

--3 count guncellemesi
if(wr_valid = '1' and rd_valid = '0') then
count <= count + 1;
elsif(wr_valid = '0' and rd_valid = '1') then
count <= count - 1;
end if;
end if;
end process;

end Behavioral;
