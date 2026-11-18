-- =====================================================================
-- MODUL 1 - UNIT 1.1
-- SQL: Persiapan Source Layer dan Initial Data Profiling
-- Studi Kasus : Database Akademik Perguruan Tinggi (UADW v1.0)
-- DBMS        : PostgreSQL
-- Schema      : src
-- Catatan     : Raw data tidak dibersihkan/diubah. Tidak ada UPDATE atau DELETE.
--               CSV diimpor melalui fitur Import Data DBeaver (bukan perintah psql).
-- =====================================================================

-- A. Verifikasi Environment PostgreSQL
-- Soal 1. Versi PostgreSQL
SELECT version();

-- Soal 2. Database dan user aktif
SELECT
    current_database() AS database_aktif,
    current_user      AS user_aktif;

-- Soal 3. Keberadaan schema src
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'src';

-- B. Membuat Source Layer
-- Soal 4. Membuat schema dan sepuluh tabel sumber
-- Struktur kolom dan urutan mengikuti header file CSV UADW v1.0.
-- Atribut mentah (*_raw) dan atribut kategori disimpan sebagai TEXT agar nilai asli tidak berubah.
CREATE SCHEMA IF NOT EXISTS src;

CREATE TABLE IF NOT EXISTS src.program_studi (
    kode_prodi      TEXT,
    nama_prodi      TEXT,
    fakultas        TEXT,
    departemen      TEXT,
    status          TEXT
);

CREATE TABLE IF NOT EXISTS src.semester (
    semester_id     TEXT,
    tahun_akademik  TEXT,
    term            TEXT,
    urutan_tahun    INTEGER,
    tanggal_mulai   DATE,
    tanggal_selesai DATE
);

CREATE TABLE IF NOT EXISTS src.mahasiswa (
    nim                 TEXT,
    nama                TEXT,
    jk_raw              TEXT,
    tanggal_lahir_raw   TEXT,
    kota_asal_raw       TEXT,
    kode_prodi_raw      TEXT,
    prodi_raw           TEXT,
    angkatan            TEXT,
    tanggal_masuk_raw   TEXT,
    status_raw          TEXT,
    email_kampus        TEXT
);

CREATE TABLE IF NOT EXISTS src.dosen (
    nidn                TEXT,
    nama_dosen          TEXT,
    jk_raw              TEXT,
    unit_prodi_raw      TEXT,
    jabatan_akademik    TEXT,
    tanggal_masuk_raw   TEXT,
    status              TEXT
);

CREATE TABLE IF NOT EXISTS src.mata_kuliah (
    kode_mk              TEXT,
    nama_mk              TEXT,
    kode_prodi           TEXT,
    sks                  INTEGER,
    semester_rekomendasi INTEGER,
    kategori             TEXT,
    aktif                TEXT
);

CREATE TABLE IF NOT EXISTS src.krs (
    krs_id              TEXT,
    nim                 TEXT,
    kode_mk             TEXT,
    semester_id         TEXT,
    kelas               TEXT,
    status_krs          TEXT,
    tanggal_ambil_raw   TEXT,
    sumber_sistem       TEXT
);

CREATE TABLE IF NOT EXISTS src.nilai (
    nilai_id            TEXT,
    nim                 TEXT,
    kode_mk             TEXT,
    semester_id         TEXT,
    nilai_angka         NUMERIC,
    nilai_huruf         TEXT,
    status_lulus        TEXT,
    tanggal_input_raw   TEXT
);

CREATE TABLE IF NOT EXISTS src.aktivitas_lms (
    lms_event_id    TEXT,
    nim             TEXT,
    kode_mk         TEXT,
    semester_id     TEXT,
    waktu_event     TIMESTAMP,
    tipe_event      TEXT,
    durasi_menit    INTEGER,
    skor_kuis       NUMERIC,
    platform        TEXT
);

CREATE TABLE IF NOT EXISTS src.pembayaran (
    pembayaran_id       TEXT,
    nim                 TEXT,
    semester_id         TEXT,
    tanggal_bayar_raw   TEXT,
    nominal_tagihan     NUMERIC,
    nominal_bayar       NUMERIC,
    status_pembayaran   TEXT,
    kanal               TEXT
);

CREATE TABLE IF NOT EXISTS src.kelulusan (
    kelulusan_id        TEXT,
    nim                 TEXT,
    tanggal_lulus_raw   TEXT,
    ipk_final           NUMERIC,
    masa_studi_bulan    INTEGER,
    predikat            TEXT,
    status_tepat_waktu  TEXT
);

-- Bukti seluruh tabel berhasil dibuat (lihat juga Soal 6)
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'src' AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- C. Mengimpor Dataset Raw melalui DBeaver
-- Soal 5. Impor sepuluh file CSV menggunakan fitur Import Data.
-- PENTING:
-- 1. Klik kanan tabel src tujuan > Import Data > CSV > pilih file.
-- 2. Periksa encoding UTF-8, delimiter koma, header, preview, dan pemetaan kolom.
-- 3. Klik Proceed dan tunggu sampai proses selesai.
-- 4. Pasangan file dan tabel:
--    program_studi.csv -> src.program_studi
--    semester.csv      -> src.semester
--    mahasiswa.csv     -> src.mahasiswa
--    dosen.csv         -> src.dosen
--    mata_kuliah.csv   -> src.mata_kuliah
--    krs.csv            -> src.krs
--    nilai.csv          -> src.nilai
--    aktivitas_lms.csv  -> src.aktivitas_lms
--    pembayaran.csv     -> src.pembayaran
--    kelulusan.csv      -> src.kelulusan
-- Jangan mengimpor ulang tabel yang sudah berisi data karena proses ini
-- menambahkan baris dan dapat menyebabkan duplikasi.
-- Tidak ada perintah COPY/psql pada file ini; impor dilakukan di antarmuka DBeaver.

-- D. Inventarisasi dan Verifikasi Source
-- Soal 6. Daftar base table pada schema src
SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'src'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Soal 7. Jumlah baris lima tabel master/reference awal
SELECT 'program_studi' AS tabel, COUNT(*) AS jumlah_baris FROM src.program_studi
UNION ALL SELECT 'semester',    COUNT(*) FROM src.semester
UNION ALL SELECT 'mahasiswa',   COUNT(*) FROM src.mahasiswa
UNION ALL SELECT 'dosen',       COUNT(*) FROM src.dosen
UNION ALL SELECT 'mata_kuliah', COUNT(*) FROM src.mata_kuliah
ORDER BY tabel;

-- Soal 8. Jumlah baris seluruh sepuluh tabel
SELECT 'program_studi' AS tabel, COUNT(*) AS jumlah_baris FROM src.program_studi
UNION ALL
SELECT 'semester', COUNT(*) FROM src.semester
UNION ALL
SELECT 'mahasiswa', COUNT(*) FROM src.mahasiswa
UNION ALL
SELECT 'dosen', COUNT(*) FROM src.dosen
UNION ALL
SELECT 'mata_kuliah', COUNT(*) FROM src.mata_kuliah
UNION ALL
SELECT 'krs', COUNT(*) FROM src.krs
UNION ALL
SELECT 'nilai', COUNT(*) FROM src.nilai
UNION ALL
SELECT 'aktivitas_lms', COUNT(*) FROM src.aktivitas_lms
UNION ALL
SELECT 'pembayaran', COUNT(*) FROM src.pembayaran
UNION ALL
SELECT 'kelulusan', COUNT(*) FROM src.kelulusan
ORDER BY tabel;

-- Soal 9. Jumlah kolom setiap tabel
SELECT
    table_name   AS nama_tabel,
    COUNT(*)     AS jumlah_kolom
FROM information_schema.columns
WHERE table_schema = 'src'
GROUP BY table_name
ORDER BY table_name;

-- Soal 10. Struktur kolom tabel mahasiswa
SELECT
    ordinal_position AS posisi_kolom,
    column_name      AS nama_kolom,
    data_type        AS tipe_data
FROM information_schema.columns
WHERE table_schema = 'src'
  AND table_name = 'mahasiswa'
ORDER BY ordinal_position;

-- E. Initial Profiling Data Mahasiswa
-- Soal 11. Candidate key (NIM)
SELECT
    COUNT(*)                        AS raw_rows,
    COUNT(DISTINCT nim)             AS distinct_nim,
    COUNT(*) - COUNT(DISTINCT nim)  AS excess_duplicate_rows
FROM src.mahasiswa;

-- Soal 12. Rentang tahun angkatan
SELECT
    MIN(CAST(angkatan AS INTEGER)) AS angkatan_min,
    MAX(CAST(angkatan AS INTEGER)) AS angkatan_max
FROM src.mahasiswa;

-- Soal 13. Kota asal kosong
SELECT COUNT(*) AS missing_kota
FROM src.mahasiswa
WHERE kota_asal_raw IS NULL
   OR TRIM(kota_asal_raw) = '';

-- Soal 14. Variasi label program studi (jumlah distinct)
SELECT COUNT(DISTINCT prodi_raw) AS distinct_prodi_raw
FROM src.mahasiswa;

-- Soal 15. Jumlah program studi pada tabel referensi
SELECT COUNT(*) AS canonical_programs
FROM src.program_studi;

-- Soal 16. Distribusi label program studi mentah
SELECT
    prodi_raw,
    COUNT(*) AS jumlah
FROM src.mahasiswa
GROUP BY prodi_raw
ORDER BY prodi_raw;

-- Soal 17. Variasi jenis kelamin
SELECT
    jk_raw,
    COUNT(*) AS jumlah
FROM src.mahasiswa
GROUP BY jk_raw
ORDER BY jk_raw;

-- Soal 18. Sampel lima record mahasiswa
SELECT *
FROM src.mahasiswa
LIMIT 5;

-- F. Profiling Ukuran Source dan Relasi Awal Antar-Tabel
-- Soal 19. Source dengan jumlah baris terbesar
SELECT 'program_studi' AS source, COUNT(*) AS jumlah_baris FROM src.program_studi
UNION ALL
SELECT 'semester', COUNT(*) FROM src.semester
UNION ALL
SELECT 'mahasiswa', COUNT(*) FROM src.mahasiswa
UNION ALL
SELECT 'dosen', COUNT(*) FROM src.dosen
UNION ALL
SELECT 'mata_kuliah', COUNT(*) FROM src.mata_kuliah
UNION ALL
SELECT 'krs', COUNT(*) FROM src.krs
UNION ALL
SELECT 'nilai', COUNT(*) FROM src.nilai
UNION ALL
SELECT 'aktivitas_lms', COUNT(*) FROM src.aktivitas_lms
UNION ALL
SELECT 'pembayaran', COUNT(*) FROM src.pembayaran
UNION ALL
SELECT 'kelulusan', COUNT(*) FROM src.kelulusan
ORDER BY jumlah_baris DESC;

-- Soal 20. Jumlah NIM berbeda pada tabel transaksi/aktivitas
SELECT 'krs' AS tabel, COUNT(DISTINCT nim) AS jumlah_nim_unik FROM src.krs
UNION ALL SELECT 'nilai',         COUNT(DISTINCT nim) FROM src.nilai
UNION ALL SELECT 'aktivitas_lms', COUNT(DISTINCT nim) FROM src.aktivitas_lms
UNION ALL SELECT 'pembayaran',    COUNT(DISTINCT nim) FROM src.pembayaran
UNION ALL SELECT 'kelulusan',     COUNT(DISTINCT nim) FROM src.kelulusan;
