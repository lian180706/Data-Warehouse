-- UADW v1.0 - Modul Praktikum 01
CREATE SCHEMA IF NOT EXISTS src;
DROP TABLE IF EXISTS src.program_studi;
CREATE TABLE src.program_studi (kode_prodi TEXT,nama_prodi TEXT,fakultas TEXT,departemen TEXT,status TEXT);
DROP TABLE IF EXISTS src.semester;
CREATE TABLE src.semester (semester_id TEXT,tahun_akademik TEXT,term TEXT,urutan_tahun TEXT,tanggal_mulai TEXT,tanggal_selesai TEXT);
DROP TABLE IF EXISTS src.mahasiswa;
CREATE TABLE src.mahasiswa (nim TEXT,nama TEXT,jk_raw TEXT,tanggal_lahir_raw TEXT,kota_asal_raw TEXT,kode_prodi_raw TEXT,prodi_raw TEXT,angkatan TEXT,tanggal_masuk_raw TEXT,status_raw TEXT,email_kampus TEXT);
DROP TABLE IF EXISTS src.dosen;
CREATE TABLE src.dosen (nidn TEXT,nama_dosen TEXT,jk_raw TEXT,unit_prodi_raw TEXT,jabatan_akademik TEXT,tanggal_masuk_raw TEXT,status TEXT);
DROP TABLE IF EXISTS src.mata_kuliah;
CREATE TABLE src.mata_kuliah (kode_mk TEXT,nama_mk TEXT,kode_prodi TEXT,sks TEXT,semester_rekomendasi TEXT,kategori TEXT,aktif TEXT);

--7. Guided Excercise A - Membuat Database dan Schema
CREATE DATABASE uadw_lab;
-- reconect ke uadw_lab
CREATE SCHEMA IF NOT EXISTS src;

SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'src';

--9. Guided Excercise C - Membuat Data Inventory
SELECT 
    'program_studi' AS tabel,
    (SELECT COUNT(*) FROM src.program_studi) AS jumlah_baris,
    (SELECT COUNT(*)
     FROM information_schema.columns
     WHERE table_schema = 'src'
       AND table_name = 'program_studi') AS jumlah_kolom,
    'kode_prodi' AS natural_key_candidate,
    'Menyimpan data program studi' AS peran_bisnis

UNION ALL

SELECT 
    'semester' AS tabel,
    (SELECT COUNT(*) FROM src.semester) AS jumlah_baris,
    (SELECT COUNT(*)
     FROM information_schema.columns
     WHERE table_schema = 'src'
       AND table_name = 'semester') AS jumlah_kolom,
    'semester_id' AS natural_key_candidate,
    'Menyimpan data periode atau semester akademik' AS peran_bisnis

UNION ALL

SELECT 
    'mahasiswa' AS tabel,
    (SELECT COUNT(*) FROM src.mahasiswa) AS jumlah_baris,
    (SELECT COUNT(*)
     FROM information_schema.columns
     WHERE table_schema = 'src'
       AND table_name = 'mahasiswa') AS jumlah_kolom,
    'nim' AS natural_key_candidate,
    'Menyimpan data identitas mahasiswa' AS peran_bisnis

UNION ALL

SELECT 
    'dosen' AS tabel,
    (SELECT COUNT(*) FROM src.dosen) AS jumlah_baris,
    (SELECT COUNT(*)
     FROM information_schema.columns
     WHERE table_schema = 'src'
       AND table_name = 'dosen') AS jumlah_kolom,
    'nidn' AS natural_key_candidate,
    'Menyimpan data identitas dosen' AS peran_bisnis

UNION ALL

SELECT 
    'mata_kuliah' AS tabel,
    (SELECT COUNT(*) FROM src.mata_kuliah) AS jumlah_baris,
    (SELECT COUNT(*)
     FROM information_schema.columns
     WHERE table_schema = 'src'
       AND table_name = 'mata_kuliah') AS jumlah_kolom,
    'kode_mk' AS natural_key_candidate,
    'Menyimpan data mata kuliah' AS peran_bisnis;


--10. Guide Exercise D - Eksplorasi Awal
--mencari jumlah mahasiswa dan duplikat
SELECT COUNT(*) AS raw_rows,
       COUNT(DISTINCT nim) AS distinct_nim,
       COUNT(*) - COUNT(DISTINCT nim) as selisih
FROM src.mahasiswa;

--cari missing data kolom kota_raw
SELECT COUNT(*) AS missing_kota
FROM src.mahasiswa
WHERE TRIM(COALESCE(kota_asal_raw,'')) = '';

-- variasi label program studi
SELECT prodi_raw, COUNT(*) AS jumlah
FROM src.mahasiswa
GROUP BY prodi_raw
ORDER BY prodi_raw;



--11. Problem challenge
--1. Berapa jumlah baris pada masing-masing dari lima tabel sumber?
SELECT 'program_studi' AS nama_tabel, COUNT(*) AS jumlah_baris
FROM src.program_studi
UNION ALL
SELECT 'semester', COUNT(*)
FROM src.semester
UNION ALL
SELECT 'mahasiswa', COUNT(*)
FROM src.mahasiswa
UNION ALL
SELECT 'dosen', COUNT(*)
FROM src.dosen
UNION ALL
SELECT 'mata_kuliah', COUNT(*)
FROM src.mata_kuliah;

--2. Berapa jumlah NIM unik pada mahasiswa.csv? Apakah jumlahnya sama dengan jumlah baris?
SELECT
    COUNT(*) AS jumlah_baris,
    COUNT(DISTINCT nim) AS jumlah_nim_unik
FROM src.mahasiswa;

--3. Berapa baris mahasiswa yang merupakan excess duplicate jika NIM dianggap natural key?
SELECT
    COUNT(*) - COUNT(DISTINCT nim) AS excess_duplicate
FROM src.mahasiswa;

--4. Apa rentang angkatan pada base load?
SELECT
    MIN(CAST(angkatan AS INTEGER)) AS angkatan_min,
    MAX(CAST(angkatan AS INTEGER)) AS angkatan_max
FROM src.mahasiswa;

--5. Berapa mahasiswa yang kota_asal_raw-nya kosong?
SELECT
    COUNT(*) AS jumlah_kota_asal_kosong
FROM src.mahasiswa
WHERE TRIM(COALESCE(kota_asal_raw, '')) = '';

SELECT
    nim,
    nama,
    kota_asal_raw
FROM src.mahasiswa
WHERE TRIM(COALESCE(kota_asal_raw, '')) = '';

--6. Berapa banyak label prodi_raw yang berbeda? Bandingkan dengan jumlah program studi canonical.
SELECT
    (SELECT COUNT(DISTINCT prodi_raw)
     FROM src.mahasiswa) AS jumlah_label_prodi_raw,

    (SELECT COUNT(*)
     FROM src.program_studi) AS jumlah_prodi_canonical;
    
--7. Temukan minimal tiga pola lain yang menunjukkan source data belum siap langsung dimasukkan ke Dimension Table.

-- Pola 1: duplicate natural key
SELECT
    nim,
    COUNT(*) AS jumlah
FROM src.mahasiswa
GROUP BY nim
HAVING COUNT(*) > 1
ORDER BY jumlah DESC, nim;

-- Pola 2: missing value
SELECT
    COUNT(*) AS jumlah_kota_kosong
FROM src.mahasiswa
WHERE TRIM(COALESCE(kota_asal_raw, '')) = '';

-- Pola 3: inkonsistensi label jenis kelamin
SELECT
    jk_raw,
    COUNT(*) AS jumlah
FROM src.mahasiswa
GROUP BY jk_raw
ORDER BY jk_raw;

-- Pola 4: inkonsistensi status
SELECT
    status_raw,
    COUNT(*) AS jumlah
FROM src.mahasiswa
GROUP BY status_raw
ORDER BY status_raw;

