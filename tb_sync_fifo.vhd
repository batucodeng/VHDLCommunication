library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_sync_fifo is
end tb_sync_fifo;

architecture Behavioral of tb_sync_fifo is
constant DATA_WIDTH : integer := 8;
constant FIFO_DEPTH : integer := 16;
constant CLK_PERIOD : time := 37.037 ns;

signal clk : std_logic := '0';
signal rst : std_logic := '0';
signal wr_en : std_logic := '0';
signal wr_data : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
signal rd_en : std_logic := '0';
signal rd_data : std_logic_vector(DATA_WIDTH - 1 downto 0);
signal fully : std_logic;
signal empty : std_logic;

begin

clk_process : process
begin
clk <= '0';
wait for CLK_PERIOD / 2;
clk <= '1';
wait for CLK_PERIOD / 2;
end process;

uut : entity work.sync_fifo 
generic map (
DATA_WIDTH => DATA_WIDTH,
FIFO_DEPTH => FIFO_DEPTH
)
port map (
clk => clk,
rst => rst,
wr_en => wr_en,
wr_data => wr_data,
rd_en => rd_en,
rd_data => rd_data,
fully => fully,
empty => empty 
);

-- test
stim_proc : process
begin
--1 baslangic reset
rst <= '1';
wait for 100 ns;
rst <= '0';
wait until rising_edge(clk);

assert (empty = '1' and fully = '0')
report "Hata: reset sonrasi fifo bos degil"
severity error;

-- bosken sahte okuma
rd_en <= '1';
wait until rising_edge(clk);
rd_en <= '0';
wait until rising_edge(clk);

assert empty = '1'
report "hata: bos fifo okumaya calisildiginda durum bozuldu"
severity error;

--2 dolabi agzina kadar doldur
for i in 0 to FIFO_DEPTH - 1 loop
wr_en <= '1';
wr_data <= std_logic_vector(to_unsigned(16 + i, DATA_WIDTH));
wait until rising_edge(clk);
end loop;
wr_en <= '0';
wait for 1 ns;

assert (fully = '1' and empty = '0')
report "HATA: 16 bayt yazildiktan sonra full bayragi 1 olmadi!"
severity error;

-- Dolu iken 17. bayti (0xFF) zorla yazma denemesi 
wr_en   <= '1';
wr_data <= x"FF";
wait until rising_edge(clk);
wr_en   <= '0';

report "BASARILI: 16 bayt dolduruldu ve tasma korumasi dogrulandi." severity note;

-- Dolaptaki 16 Bayti Sirayla Oku ve Kontrol Et
for i in 0 to FIFO_DEPTH - 1 loop
rd_en <= '1';
wait until rising_edge(clk);
rd_en <= '0';
wait for 1 ns; 

assert rd_data = std_logic_vector(to_unsigned(16 + i, DATA_WIDTH))
report "HATA: Okunan veri yazilan sira ile uyusmuyor!"
severity error;
end loop;

assert (empty = '1' and fully = '0')
report "HATA: Tum veriler okunduktan sonra empty bayragi 1 olmadi!"
severity error;

report "BASARILI: 16 bayt ilk giren ilk cikar (FIFO) sirasiyla dogru okundu." severity note;

-- 4. Dairesel Donus 
for i in 1 to 5 loop
wr_en   <= '1';
wr_data <= std_logic_vector(to_unsigned(160 + i, DATA_WIDTH)); 
wait until rising_edge(clk);
end loop;
wr_en <= '0';

for i in 1 to 5 loop
rd_en <= '1';
wait until rising_edge(clk);
rd_en <= '0';
wait for 1 ns;

assert rd_data = std_logic_vector(to_unsigned(160 + i, DATA_WIDTH))
report "HATA: Dairesel donus (wrap-around) okumasinda veri hatasi!"
severity error;
end loop;

assert empty = '1'
report "HATA: Dairesel test sonrasi FIFO bosalmadi!"
severity error;

report "TUM TESTLER BASARILI: sync_fifo tam kapasite, koruma ve dairesel donus testlerinden gecti!" severity note;
wait;
end process;

end Behavioral;
