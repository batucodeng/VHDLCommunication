library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity packet_processor is
port (
clk : in std_logic;
rst : in std_logic;

--rx'te gelen girisler
rx_data : in std_logic_vector(7 downto 0); -- uart rx'ten gelen son veri
rx_valid : in std_logic;

--sync fifo'ya giden cikislar
fifo_wr_en : out std_logic;
fifo_wr_data : out std_logic_vector(7 downto 0);
fifo_full : in std_logic
);
end packet_processor;

architecture Behavioral of packet_processor is
type state_type is (
WAIT_H1,
WAIT_H2,
GET_DATA,
GET_CS,
SEND_H1,
SEND_H2,
SEND_DATA,
SEND_CS
);

signal state : state_type := WAIT_H1;
signal rx_payload : std_logic_vector(7 downto 0) := (others => '0');
signal tx_payload : std_logic_vector(7 downto 0) := (others => '0');

--sabit baslik degerleri
constant HEAD_1 : std_logic_vector(7 downto 0) := x"55";
constant HEAD_2 : std_logic_vector(7 downto 0) := x"AA";
constant ERR_CODE : std_logic_vector(7 downto 0) := x"EE";

begin

process(clk, rst)
variable calc_rx_cs : unsigned(7 downto 0);
variable calc_tx_cs : unsigned(7 downto 0);
begin
if(rst = '1') then
state <= WAIT_H1;
rx_payload <= (others => '0');
tx_payload <= (others => '0');
fifo_wr_en <= '0';
fifo_wr_data <= (others => '0');

elsif rising_edge(clk) then
fifo_wr_en <= '0';

case state is

when WAIT_H1 =>
if(rx_valid = '1') then
if(rx_data = HEAD_1) then
state <= WAIT_H2;
end if;
end if;

when WAIT_H2 =>
if(rx_valid = '1') then
if(rx_data = HEAD_2) then
state <= GET_DATA;
elsif(rx_data = HEAD_1) then
state <= WAIT_H2;
else
state <= WAIT_H1;
end if;
end if;

when GET_DATA =>
if(rx_valid = '1') then
rx_payload <= rx_data;
state <= GET_CS;
end if;

when GET_CS =>
if(rx_valid = '1') then
calc_rx_cs := unsigned(HEAD_1) + unsigned(HEAD_2) + unsigned(rx_payload);

if(unsigned(rx_data) = calc_rx_cs) then
tx_payload <= std_logic_vector(unsigned(rx_payload) + 1);
else
tx_payload <= ERR_CODE;
end if;
state <= SEND_H1;
end if;

when SEND_H1 =>
if(fifo_full = '0') then
fifo_wr_data <= HEAD_1;
fifo_wr_en <= '1';
state <= SEND_H2;
end if;

when SEND_H2 =>
if(fifo_full = '0') then
fifo_wr_data <= HEAD_2;
fifo_wr_en <= '1';
state <= SEND_DATA;
end if;

when SEND_DATA =>
if(fifo_full = '0') then
fifo_wr_data <= tx_payload;
fifo_wr_en <= '1';
state <= SEND_CS;
end if;

when SEND_CS =>
if(fifo_full = '0') then
calc_tx_cs := unsigned(HEAD_1) + unsigned(HEAD_2) + unsigned(tx_payload);
fifo_wr_data <= std_logic_vector(calc_tx_cs);
fifo_wr_en <= '1';
state <= WAIT_H1;
end if;
end case;
end if;
end process;
end Behavioral;