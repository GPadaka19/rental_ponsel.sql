-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jul 15, 2024 at 08:27 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `rental_ponsel`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `Cek_Stok` ()   BEGIN
    DECLARE v_aksi VARCHAR(50) DEFAULT 'CEK STOK';
    DECLARE v_keterangan TEXT;
    DECLARE v_id_ponsel INT;
    DECLARE v_merk VARCHAR(50);
    DECLARE v_tipe VARCHAR(50);
    DECLARE v_stok INT;
    DECLARE done INT DEFAULT 0;

    -- Buat cursor untuk membaca data ponsel
    DECLARE ponsel_cursor CURSOR FOR 
    SELECT id_ponsel, merk, tipe, stok 
    FROM ponsel;

    -- Handler untuk menangani akhir dari cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN ponsel_cursor;

    read_loop: LOOP
        FETCH ponsel_cursor INTO v_id_ponsel, v_merk, v_tipe, v_stok;
        
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Tentukan kategori stok
        IF v_stok = 0 THEN
            SET v_keterangan = CONCAT('Ponsel ', v_merk, ' ', v_tipe, ' stok habis.');
        ELSEIF v_stok <= 5 THEN
            SET v_keterangan = CONCAT('Ponsel ', v_merk, ' ', v_tipe, ' stok tinggal sedikit. Sisa: ', v_stok);
        ELSE
            SET v_keterangan = CONCAT('Ponsel ', v_merk, ' ', v_tipe, ' stok masih aman. Sisa: ', v_stok);
        END IF;

        -- Masukkan log ke tabel log
        INSERT INTO log (aksi, keterangan)
        VALUES (v_aksi, v_keterangan);

    END LOOP;

    CLOSE ponsel_cursor;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `isi_data_transaksi` (IN `id_persewaan_param` INT, IN `id_denda_param` INT)   BEGIN
    DECLARE total_biaya DECIMAL(10, 2);
    DECLARE tanggal_pengembalian DATE;
    DECLARE current_status VARCHAR(20);
    
    SELECT status INTO current_status
    FROM persewaan
    WHERE id_persewaan = id_persewaan_param;
    
    IF current_status = 'Dikembalikan' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Tidak dapat menambahkan transaksi karena status persewaan sudah Dikembalikan.';
    ELSE

        SET total_biaya = hitung_total_biaya(id_persewaan_param, id_denda_param);
        
        SET tanggal_pengembalian = CURDATE();
        
        INSERT INTO transaksi (Id_persewaan, Id_denda, Tanggal_pengembalian, total_biaya)
        VALUES (id_persewaan_param, id_denda_param, tanggal_pengembalian, total_biaya);
        
        IF id_denda_param IS NULL THEN
            UPDATE persewaan
            SET status = 'Dikembalikan'
            WHERE id_persewaan = id_persewaan_param;
            
        END IF;
    END IF;
    
    COMMIT;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `hitung_total_biaya` (`id_persewaan_param` INT, `id_denda_param` INT) RETURNS DECIMAL(10,2)  BEGIN
    DECLARE total_biaya DECIMAL(10, 2);
    
    SELECT 
        SUM(po.harga_per_hari * DATEDIFF(p.tanggal_akhir_sewa, p.tanggal_mulai_sewa)) INTO total_biaya
    FROM 
        persewaan p
    INNER JOIN 
        ponsel po ON p.id_ponsel = po.id_ponsel
    WHERE 
        p.id_persewaan = id_persewaan_param;

    IF id_denda_param IS NOT NULL THEN
        SELECT 
            total_biaya + d.jumlah_denda INTO total_biaya
        FROM 
            denda d
        WHERE 
            d.Id_denda = id_denda_param;
    END IF;
    
    RETURN total_biaya;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `total_pengguna` () RETURNS INT(11)  BEGIN 
DECLARE total INT; 
SELECT COUNT(id_pengguna) INTO total FROM pengguna; 
RETURN total;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `admin`
--

CREATE TABLE `admin` (
  `id_admin` int(11) NOT NULL,
  `nama` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `admin`
--

INSERT INTO `admin` (`id_admin`, `nama`, `email`, `password`) VALUES
(1, 'Budi Santoso', 'budi.santoso@rental.com', 'password123'),
(2, 'Anita Dewi', 'anita.dewi@rental.com', 'securepass'),
(3, 'Ahmad Fauzi', 'ahmad.fauzi@rental.com', 'fauzi123'),
(4, 'Siti Nurhaliza', 'siti.nurhaliza@rental.com', 'nurhaliza321'),
(5, 'Adi Nugroho', 'adi.nugroho@rental.com', 'nugroho456');

--
-- Triggers `admin`
--
DELIMITER $$
CREATE TRIGGER `after_delete_admin` AFTER DELETE ON `admin` FOR EACH ROW BEGIN
    INSERT INTO log (aksi, keterangan)
    VALUES ('HAPUS ADMIN', CONCAT('Admin dengan id : ', OLD.id_admin, ' (', OLD.nama, ') telah dihapus.'));
    
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `denda`
--

CREATE TABLE `denda` (
  `Id_denda` int(11) NOT NULL,
  `jumlah_denda` decimal(10,2) NOT NULL,
  `deskripsi` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `denda`
--

INSERT INTO `denda` (`Id_denda`, `jumlah_denda`, `deskripsi`) VALUES
(1, 50000.00, 'Keterlambatan pengembalian lebih dari 2 hari.'),
(2, 100000.00, 'Kerusakan ringan pada ponsel.'),
(3, 200000.00, 'Kerusakan sedang pada ponsel.'),
(4, 300000.00, 'Kerusakan berat pada ponsel.'),
(5, 150000.00, 'Keterlambatan pengembalian lebih dari 1 minggu.'),
(6, 500000.00, 'Keterlambatan pengembalian lebih dari 1 minggu dan ponsel rusak.');

-- --------------------------------------------------------

--
-- Stand-in structure for view `ketersediaan_ponsel`
-- (See below for the actual view)
--
CREATE TABLE `ketersediaan_ponsel` (
`tipe` varchar(50)
,`stok` int(3)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `ketersediaan_ponsel_check`
-- (See below for the actual view)
--
CREATE TABLE `ketersediaan_ponsel_check` (
`tipe` varchar(50)
,`stok` int(3)
);

-- --------------------------------------------------------

--
-- Table structure for table `log`
--

CREATE TABLE `log` (
  `id_log` int(11) NOT NULL,
  `aksi` varchar(50) DEFAULT NULL,
  `waktu` timestamp NOT NULL DEFAULT current_timestamp(),
  `keterangan` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `log`
--

INSERT INTO `log` (`id_log`, `aksi`, `waktu`, `keterangan`) VALUES
(1, 'CEK STOK', '2024-07-15 06:25:27', 'Ponsel Apple iPhone 12 stok masih aman. Sisa: 50'),
(2, 'CEK STOK', '2024-07-15 06:25:27', 'Ponsel Apple iPhone 12 Pro stok masih aman. Sisa: 30'),
(3, 'CEK STOK', '2024-07-15 06:25:27', 'Ponsel Apple iPhone 11 stok masih aman. Sisa: 20'),
(4, 'CEK STOK', '2024-07-15 06:25:27', 'Ponsel Apple iPhone 11 Pro stok masih aman. Sisa: 40'),
(5, 'CEK STOK', '2024-07-15 06:25:27', 'Ponsel Apple iPhone XS stok masih aman. Sisa: 25'),
(6, 'CEK STOK', '2024-07-15 06:25:27', 'Ponsel Apple iPhone XS Max stok masih aman. Sisa: 15'),
(7, 'CEK STOK', '2024-07-15 06:25:27', 'Ponsel Apple iPhone XR stok masih aman. Sisa: 35'),
(8, 'CEK STOK', '2024-07-15 06:25:27', 'Ponsel Apple iPhone X stok masih aman. Sisa: 45'),
(9, 'CEK STOK', '2024-07-15 06:25:27', 'Ponsel Apple iPhone 8 stok masih aman. Sisa: 10'),
(10, 'CEK STOK', '2024-07-15 06:25:27', 'Ponsel Apple iPhone 8 Plus stok masih aman. Sisa: 20');

-- --------------------------------------------------------

--
-- Table structure for table `pengguna`
--

CREATE TABLE `pengguna` (
  `id_pengguna` int(11) NOT NULL,
  `nama` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `nomor_telepon` varchar(20) DEFAULT NULL,
  `alamat` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `pengguna`
--

INSERT INTO `pengguna` (`id_pengguna`, `nama`, `email`, `nomor_telepon`, `alamat`) VALUES
(1, 'Budi Santoso', 'budi.santoso@gmail.com', '081234567890', 'Jl. Malioboro No.1, Yogyakarta'),
(2, 'Siti Aminah', 'siti.aminah@gmail.com', '086234567891', 'Jl. Kaliurang No.2, Yogyakarta'),
(3, 'Joko Widodo', 'joko.widodo@gmail.com', '081234567892', 'Jl. Prawirotaman No.3, Yogyakarta'),
(4, 'Dewi Sartika', 'dewi.sartika@gmail.com', '081234567893', 'Jl. Gejayan No.4, Yogyakarta'),
(5, 'Agus Supriyadi', 'agus.supriyadi@gmail.com', '081234567894', 'Jl. Monjali No.5, Yogyakarta'),
(6, 'Rina Andriani', 'rina.andriani@gmail.com', '082345678912', 'Jl. Kusumanegara No.6, Yogyakarta'),
(7, 'Hendra Gunawan', 'hendra.gunawan@gmail.com', '089456789123', 'Jl. Timoho No.7, Yogyakarta'),
(8, 'Linda Wahyuni', 'linda.wahyuni@gmail.com', '081567891234', 'Jl. Suryodiningratan No.8, Yogyakarta'),
(9, 'Taufik Hidayat', 'taufik.hidayat@gmail.com', '082678912345', 'Jl. Parangtritis No.9, Yogyakarta'),
(10, 'Ayu Lestari', 'ayu.lestari@gmail.com', '085789123456', 'Jl. Palagan Tentara Pelajar No.10, Yogyakarta');

--
-- Triggers `pengguna`
--
DELIMITER $$
CREATE TRIGGER `before_delete_pengguna` BEFORE DELETE ON `pengguna` FOR EACH ROW BEGIN
    DECLARE old_values TEXT;

    SET old_values = CONCAT('ID: ', OLD.id_pengguna, ', Nama: ', OLD.nama, ', Email: ', OLD.email, ', Nomor Telepon: ', OLD.nomor_telepon, ', Alamat: ', OLD.alamat);

    INSERT INTO log (aksi, keterangan)
    VALUES ('DELETE PENGGUNA', CONCAT('Data yang dihapus: ', old_values));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `before_update_pengguna` BEFORE UPDATE ON `pengguna` FOR EACH ROW BEGIN
    DECLARE old_values TEXT;
    DECLARE new_values TEXT;

    SET old_values = CONCAT('ID: ', OLD.id_pengguna, ', Nama: ', OLD.nama, ', Email: ', OLD.email, ', Nomor Telepon: ', OLD.nomor_telepon, ', Alamat: ', OLD.alamat);
    SET new_values = CONCAT('ID: ', NEW.id_pengguna, ', Nama: ', NEW.nama, ', Email: ', NEW.email, ', Nomor Telepon: ', NEW.nomor_telepon, ', Alamat: ', NEW.alamat);

    INSERT INTO log (aksi, keterangan)
    VALUES ('MENGUBAH DATA PENGGUNA', CONCAT('Sebelum: ', old_values, '; Sesudah: ', new_values));
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `persewaan`
--

CREATE TABLE `persewaan` (
  `id_persewaan` int(11) NOT NULL,
  `id_pengguna` int(11) NOT NULL,
  `id_admin` int(11) NOT NULL,
  `id_ponsel` int(11) NOT NULL,
  `tanggal_mulai_sewa` date NOT NULL,
  `tanggal_akhir_sewa` date NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'Disewakan'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `persewaan`
--

INSERT INTO `persewaan` (`id_persewaan`, `id_pengguna`, `id_admin`, `id_ponsel`, `tanggal_mulai_sewa`, `tanggal_akhir_sewa`, `status`) VALUES
(1, 2, 3, 4, '2024-07-05', '2024-07-10', 'Disewakan'),
(2, 3, 2, 5, '2024-07-04', '2024-07-09', 'Disewakan'),
(3, 4, 1, 6, '2024-07-03', '2024-07-08', 'Disewakan'),
(4, 5, 4, 7, '2024-07-02', '2024-07-07', 'Disewakan'),
(5, 6, 5, 8, '2024-07-01', '2024-07-06', 'Disewakan');

--
-- Triggers `persewaan`
--
DELIMITER $$
CREATE TRIGGER `after_insert_persewaan` AFTER INSERT ON `persewaan` FOR EACH ROW BEGIN
    -- Kurangi stok ponsel
    UPDATE ponsel
    SET Stok = Stok - 1
    WHERE id_ponsel = NEW.id_ponsel;

    -- Masukkan log
    INSERT INTO log (aksi, waktu, keterangan)
    VALUES ('MEMASUKKAN PERSEWAAN', NOW(), CONCAT('Persewaan baru: ', NEW.id_persewaan, ', Ponsel ID: ', NEW.id_ponsel, ', Pengguna ID: ', NEW.id_pengguna, ', Admin ID: ', NEW.id_admin));
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `after_update_tanggal_akhir_sewa` AFTER UPDATE ON `persewaan` FOR EACH ROW BEGIN
    DECLARE nama_admin VARCHAR(100);
    
    SELECT nama INTO nama_admin
    FROM admin
    WHERE id_admin = NEW.id_admin;
    
    INSERT INTO log (aksi, keterangan)
    VALUES ('MENGUBAH TANGGAL AKHIR SEWA', CONCAT('Admin ', nama_admin, ' mengubah tanggal_akhir_sewa pada persewaan dengan id :  ', NEW.id_persewaan, ' dari ', OLD.tanggal_akhir_sewa, ' menjadi ', NEW.tanggal_akhir_sewa, '.'));
        
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `persewaan_detail`
-- (See below for the actual view)
--
CREATE TABLE `persewaan_detail` (
`id_persewaan` int(11)
,`nama_pengguna` varchar(100)
,`tipe_ponsel` varchar(50)
,`nama_admin` varchar(100)
,`tanggal_mulai_sewa` date
,`tanggal_akhir_sewa` date
,`status` varchar(20)
);

-- --------------------------------------------------------

--
-- Table structure for table `ponsel`
--

CREATE TABLE `ponsel` (
  `id_ponsel` int(11) NOT NULL,
  `merk` varchar(50) NOT NULL,
  `tipe` varchar(50) NOT NULL,
  `harga_per_hari` decimal(10,2) NOT NULL,
  `stok` int(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `ponsel`
--

INSERT INTO `ponsel` (`id_ponsel`, `merk`, `tipe`, `harga_per_hari`, `stok`) VALUES
(1, 'Apple', 'iPhone 12', 150000.00, 50),
(2, 'Apple', 'iPhone 12 Pro', 180000.00, 30),
(3, 'Apple', 'iPhone 11', 130000.00, 20),
(4, 'Apple', 'iPhone 11 Pro', 160000.00, 40),
(5, 'Apple', 'iPhone XS', 120000.00, 25),
(6, 'Apple', 'iPhone XS Max', 140000.00, 15),
(7, 'Apple', 'iPhone XR', 110000.00, 35),
(8, 'Apple', 'iPhone X', 100000.00, 45),
(9, 'Apple', 'iPhone 8', 90000.00, 10),
(10, 'Apple', 'iPhone 8 Plus', 110000.00, 20);

-- --------------------------------------------------------

--
-- Table structure for table `transaksi`
--

CREATE TABLE `transaksi` (
  `Id_transaksi` int(11) NOT NULL,
  `Id_persewaan` int(11) NOT NULL,
  `Id_denda` int(11) DEFAULT NULL,
  `Tanggal_pengembalian` date NOT NULL,
  `total_biaya` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `transaksi`
--
DELIMITER $$
CREATE TRIGGER `before_insert_transaksi` BEFORE INSERT ON `transaksi` FOR EACH ROW BEGIN
    DECLARE ponsel_tipe VARCHAR(50);

    SELECT p.tipe INTO ponsel_tipe
    FROM ponsel p
    JOIN persewaan ps ON p.id_ponsel = ps.id_ponsel
    WHERE ps.id_persewaan = NEW.id_persewaan;

    UPDATE ponsel
    SET stok = stok + 1
    WHERE id_ponsel = (SELECT id_ponsel FROM persewaan WHERE id_persewaan = NEW.id_persewaan);

    UPDATE persewaan
    SET status = 'Dikembalikan'
    WHERE id_persewaan = NEW.id_persewaan;

    INSERT INTO log (aksi, waktu, keterangan)
    VALUES ('MEMASUKKAN TRANSAKSI', NOW(), CONCAT('Ponsel dengan tipe ', ponsel_tipe, ' telah dikembalikan'));
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure for view `ketersediaan_ponsel`
--
DROP TABLE IF EXISTS `ketersediaan_ponsel`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `ketersediaan_ponsel`  AS SELECT `ponsel`.`tipe` AS `tipe`, `ponsel`.`stok` AS `stok` FROM `ponsel` ;

-- --------------------------------------------------------

--
-- Structure for view `ketersediaan_ponsel_check`
--
DROP TABLE IF EXISTS `ketersediaan_ponsel_check`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `ketersediaan_ponsel_check`  AS SELECT `ketersediaan_ponsel`.`tipe` AS `tipe`, `ketersediaan_ponsel`.`stok` AS `stok` FROM `ketersediaan_ponsel`WITH CASCADED CHECK OPTION  ;

-- --------------------------------------------------------

--
-- Structure for view `persewaan_detail`
--
DROP TABLE IF EXISTS `persewaan_detail`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `persewaan_detail`  AS SELECT `ps`.`id_persewaan` AS `id_persewaan`, `p`.`nama` AS `nama_pengguna`, `po`.`tipe` AS `tipe_ponsel`, `a`.`nama` AS `nama_admin`, `ps`.`tanggal_mulai_sewa` AS `tanggal_mulai_sewa`, `ps`.`tanggal_akhir_sewa` AS `tanggal_akhir_sewa`, `ps`.`status` AS `status` FROM (((`persewaan` `ps` join `pengguna` `p` on(`ps`.`id_pengguna` = `p`.`id_pengguna`)) join `ponsel` `po` on(`ps`.`id_ponsel` = `po`.`id_ponsel`)) join `admin` `a` on(`ps`.`id_admin` = `a`.`id_admin`)) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`id_admin`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `denda`
--
ALTER TABLE `denda`
  ADD PRIMARY KEY (`Id_denda`);

--
-- Indexes for table `log`
--
ALTER TABLE `log`
  ADD PRIMARY KEY (`id_log`),
  ADD KEY `idx_aksi_waktu` (`aksi`,`waktu`);

--
-- Indexes for table `pengguna`
--
ALTER TABLE `pengguna`
  ADD PRIMARY KEY (`id_pengguna`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `persewaan`
--
ALTER TABLE `persewaan`
  ADD PRIMARY KEY (`id_persewaan`),
  ADD KEY `id_ponsel` (`id_ponsel`),
  ADD KEY `id_admin` (`id_admin`),
  ADD KEY `idx_pengguna_admin_ponsel` (`id_pengguna`,`id_admin`,`id_ponsel`);

--
-- Indexes for table `ponsel`
--
ALTER TABLE `ponsel`
  ADD PRIMARY KEY (`id_ponsel`),
  ADD UNIQUE KEY `idx_tipe_stok` (`tipe`,`stok`);

--
-- Indexes for table `transaksi`
--
ALTER TABLE `transaksi`
  ADD PRIMARY KEY (`Id_transaksi`),
  ADD UNIQUE KEY `Id_persewaan` (`Id_persewaan`),
  ADD KEY `Id_denda` (`Id_denda`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admin`
--
ALTER TABLE `admin`
  MODIFY `id_admin` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `denda`
--
ALTER TABLE `denda`
  MODIFY `Id_denda` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `log`
--
ALTER TABLE `log`
  MODIFY `id_log` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `pengguna`
--
ALTER TABLE `pengguna`
  MODIFY `id_pengguna` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `persewaan`
--
ALTER TABLE `persewaan`
  MODIFY `id_persewaan` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `ponsel`
--
ALTER TABLE `ponsel`
  MODIFY `id_ponsel` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `transaksi`
--
ALTER TABLE `transaksi`
  MODIFY `Id_transaksi` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `persewaan`
--
ALTER TABLE `persewaan`
  ADD CONSTRAINT `persewaan_ibfk_1` FOREIGN KEY (`id_pengguna`) REFERENCES `pengguna` (`id_pengguna`),
  ADD CONSTRAINT `persewaan_ibfk_2` FOREIGN KEY (`id_ponsel`) REFERENCES `ponsel` (`id_ponsel`),
  ADD CONSTRAINT `persewaan_ibfk_3` FOREIGN KEY (`id_admin`) REFERENCES `admin` (`id_admin`);

--
-- Constraints for table `transaksi`
--
ALTER TABLE `transaksi`
  ADD CONSTRAINT `transaksi_ibfk_1` FOREIGN KEY (`Id_persewaan`) REFERENCES `persewaan` (`id_persewaan`),
  ADD CONSTRAINT `transaksi_ibfk_2` FOREIGN KEY (`Id_denda`) REFERENCES `denda` (`Id_denda`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
