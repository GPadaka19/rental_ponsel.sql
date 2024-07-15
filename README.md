### Rental Ponsel Database

Database Rental Ponsel merupakan sistem yang dirancang untuk mengelola proses persewaan ponsel. Database ini menggunakan SQL untuk memfasilitasi berbagai operasi seperti pencatatan transaksi, pemantauan stok, dan pengelolaan denda. Berikut adalah beberapa komponen utama dari database ini:

- **Tabel Admin**: Menyimpan informasi administrator yang mengelola sistem persewaan.
- **Tabel Denda**: Berisi data tentang jenis dan nilai denda yang dikenakan jika terjadi keterlambatan pengembalian ponsel.
- **Tabel Log**: Mencatat semua aktivitas yang terjadi di dalam sistem, termasuk perubahan status persewaan dan aksi pengguna.
- **Tabel Pengguna**: Menyimpan informasi tentang pelanggan yang melakukan persewaan ponsel.
- **Tabel Persewaan**: Berfungsi untuk mencatat detail transaksi persewaan, termasuk informasi tentang ponsel yang disewa dan tanggal pengembalian.
- **Tabel Ponsel**: Berisi informasi lengkap tentang ponsel yang tersedia untuk disewa, termasuk ketersediaan dan kondisi.
- **Tabel Transaksi**: Digunakan untuk mencatat setiap transaksi yang terjadi, termasuk biaya total persewaan dan status pembayaran.

Database ini juga memanfaatkan prosedur, fungsi, dan trigger untuk mengotomatisasi beberapa proses penting, seperti pengecekan stok sebelum melakukan transaksi baru dan perhitungan biaya total persewaan. Proses-proses ini membantu memastikan bahwa sistem beroperasi dengan efisien dan akurat.

Dengan menggunakan SQL, Rental Ponsel Database memberikan kerangka kerja yang kokoh untuk mengelola bisnis persewaan ponsel, memungkinkan pemilik bisnis untuk melacak dengan detail setiap transaksi dan mengoptimalkan pengelolaan stok ponsel mereka.
