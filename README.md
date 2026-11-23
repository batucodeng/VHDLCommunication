Veri Akışı ve Tasarım Kararları
Verici (uart_tx): 4 durumlu FSM (IDLE, START_BIT, DATA_BITS, STOP_BIT) ile LSB-first (en düşük anlamlı bit önce) formatında 8N1 seri çerçeve üretir.

Alıcı (uart_rx): Asenkron rx_line girişini 2-Flip-Flop (2-FF) senkronizör zincirinden geçirerek metastabilite riskini önler; start bitinin düşen kenarını yakaladıktan sonra her bitin tam orta noktasında (BIT_PERIOD / 2) örnekleme yaparak gürültü bağışıklığı sağlar.

Tampon Bellek (sync_fifo): Okuma ve yazma işaretçileri (wr_ptr, rd_ptr) ile dairesel tampon (circular buffer) mantığında çalışır. Kombinasyonel full / empty bayrakları ve dahili wr_valid / rd_valid korumaları sayesinde taşma (overflow) ve boş okuma (underflow) durumlarını donanım seviyesinde engeller.

Üst Entegrasyon (uart_fifo_top): Alıcıdan gelen rx_valid tetiğini doğrudan FIFO yazma hattına bağlar; bridge_proc senkron kontrol süreci ile FIFO'daki baytları 1 saat çevrimi gecikme hizalaması (rd_pending) yaparak kayıpsız biçimde uart_tx üzerinden dış hatta aktarır.

Paket Çözücü ve Yanıt Üretici (packet_processor): 8 durumlu FSM (WAIT_H1, WAIT_H2, GET_DATA, GET_CS, SEND_H1, SEND_H2, SEND_DATA, SEND_CS) ile [0x55] [0xAA] [DATA] [CHECKSUM] çerçeve yapısını doğrular. Gelen paketin (0x55 + 0xAA + DATA) mod 256 sağlama toplamı eşleştiğinde DATA + 1 yanıt paketini, hatalı çerçevelerde ise 0xEE hata kodlu paket çerçevesini sync_fifo tamponuna aktarır.
