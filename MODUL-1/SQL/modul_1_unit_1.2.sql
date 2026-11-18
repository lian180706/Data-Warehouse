-- =====================================================================
-- MODUL 1 - UNIT 1.2
-- SQL: Data Profiling dan Data Quality Assessment
-- Studi Kasus : Database Akademik Perguruan Tinggi (UADW v1.0)
-- DBMS        : PostgreSQL
-- Schema      : src
-- Catatan     : Seluruh query hanya SELECT (read-only). Tidak ada UPDATE,
--               DELETE, deduplikasi, atau standardisasi pada raw source.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Verifikasi environment
-- ---------------------------------------------------------------------

-- 1.1 Versi PostgreSQL
SELECT version();

-- 1.2 Database dan user aktif
SELECT
    current_database() AS database_aktif,
    current_user      AS user_aktif;

-- 1.3 Schema src tersedia?
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'src';


-- =====================================================================
-- A. Profiling Struktur dan Ukuran Dataset
-- =====================================================================

-- Soal 1. Menghitung jumlah record setiap tabel
SELECT 'program_studi' AS nama_dataset, COUNT(*) AS jumlah_record FROM src.program_studi
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
SELECT 'kelulusan', COUNT(*) FROM src.kelulusan;

-- Soal 2. Menghitung jumlah kolom setiap tabel
SELECT
    table_name   AS nama_tabel,
    COUNT(*)     AS jumlah_kolom
FROM information_schema.columns
WHERE table_schema = 'src'
GROUP BY table_name
ORDER BY table_name;


-- =====================================================================
-- B. Mahasiswa - Uniqueness
-- =====================================================================

-- Soal 3. Mengukur keunikan NIM
SELECT
    COUNT(*)                         AS raw_rows,
    COUNT(DISTINCT nim)              AS distinct_nim,
    COUNT(*) - COUNT(DISTINCT nim)   AS excess_duplicate_rows
FROM src.mahasiswa;

-- Soal 4. Mengidentifikasi NIM duplikat
SELECT
    nim,
    COUNT(*) AS jumlah_kemunculan
FROM src.mahasiswa
GROUP BY nim
HAVING COUNT(*) > 1
ORDER BY jumlah_kemunculan DESC, nim;


-- =====================================================================
-- C. Mahasiswa - Completeness
-- =====================================================================

-- Soal 5. Memeriksa kelengkapan kota asal mahasiswa
SELECT COUNT(*) AS missing_kota
FROM src.mahasiswa
WHERE kota_asal_raw IS NULL
   OR TRIM(kota_asal_raw) = '';


-- =====================================================================
-- D. Mahasiswa - Distribution dan Standardisasi
-- =====================================================================

-- Soal 6. Distribusi mahasiswa berdasarkan program studi (prodi_raw)
SELECT
    prodi_raw,
    COUNT(*) AS frekuensi
FROM src.mahasiswa
GROUP BY prodi_raw
ORDER BY frekuensi DESC, prodi_raw;

-- Soal 7. Menghitung variasi penulisan program studi
SELECT COUNT(DISTINCT prodi_raw) AS distinct_raw_prodi
FROM src.mahasiswa;

-- Soal 8. Distribusi jenis kelamin (jk_raw)
SELECT
    jk_raw,
    COUNT(*) AS frekuensi
FROM src.mahasiswa
GROUP BY jk_raw
ORDER BY frekuensi DESC, jk_raw;

-- Soal 9. Distribusi status mahasiswa (status_raw)
SELECT
    status_raw,
    COUNT(*) AS frekuensi
FROM src.mahasiswa
GROUP BY status_raw
ORDER BY frekuensi DESC, status_raw;

-- Soal 10. Distribusi kode program studi (kode_prodi_raw)
SELECT
    kode_prodi_raw,
    COUNT(*) AS frekuensi
FROM src.mahasiswa
GROUP BY kode_prodi_raw
ORDER BY frekuensi DESC, kode_prodi_raw;

-- Soal 11. Nama program studi tidak sesuai standar
SELECT COUNT(*) AS non_standard_prodi_rows
FROM src.mahasiswa m
LEFT JOIN src.program_studi p
       ON m.prodi_raw = p.nama_prodi
WHERE p.nama_prodi IS NULL;


-- =====================================================================
-- E. Mahasiswa - Konsistensi Format Tanggal
-- =====================================================================

-- Soal 12. Variasi format tanggal masuk
WITH klasifikasi AS (
    SELECT
        CASE
            WHEN tanggal_masuk_raw ~ '^\d{4}-\d{2}-\d{2}$'        THEN 'YYYY-MM-DD'
            WHEN tanggal_masuk_raw ~ '^\d{2}/\d{2}/\d{4}$'        THEN 'DD/MM/YYYY'
            WHEN tanggal_masuk_raw ~ '^\d{2}-[A-Za-z]{3}-\d{4}$'   THEN 'DD-Mon-YYYY'
            ELSE 'OTHER'
        END AS format_tanggal
    FROM src.mahasiswa
)
SELECT
    f.format_tanggal,
    COUNT(k.format_tanggal) AS jumlah_record
FROM (VALUES ('YYYY-MM-DD'), ('DD/MM/YYYY'), ('DD-Mon-YYYY'), ('OTHER')) AS f(format_tanggal)
LEFT JOIN klasifikasi k ON k.format_tanggal = f.format_tanggal
GROUP BY f.format_tanggal
ORDER BY jumlah_record DESC;


-- =====================================================================
-- F. KRS - Duplikasi Data
-- =====================================================================

-- Soal 13. Jumlah record KRS vs krs_id unik
SELECT
    COUNT(*)                AS raw_rows,
    COUNT(DISTINCT krs_id)  AS distinct_krs_id
FROM src.krs;

-- Soal 14. Duplikasi pengambilan mata kuliah (nim, kode_mk, semester_id)
SELECT
    nim,
    kode_mk,
    semester_id,
    COUNT(*) AS jumlah
FROM src.krs
GROUP BY nim, kode_mk, semester_id
HAVING COUNT(*) > 1
ORDER BY jumlah DESC, nim, kode_mk, semester_id;

-- Soal 15. Kelebihan record KRS akibat duplikasi
SELECT COALESCE(SUM(jumlah - 1), 0) AS excess_duplicate_krs
FROM (
    SELECT COUNT(*) AS jumlah
    FROM src.krs
    GROUP BY nim, kode_mk, semester_id
    HAVING COUNT(*) > 1
) AS t;


-- =====================================================================
-- G. Nilai - Completeness dan Validity
-- =====================================================================

-- Soal 16. Nilai angka kosong
SELECT COUNT(*) AS missing_nilai_angka
FROM src.nilai
WHERE nilai_angka IS NULL
   OR TRIM(nilai_angka::text) = '';

-- Soal 17. Nilai angka di luar rentang 0-100
SELECT COUNT(*) AS invalid_nilai_angka
FROM src.nilai
WHERE NULLIF(TRIM(nilai_angka::text), '') IS NOT NULL
  AND (NULLIF(TRIM(nilai_angka::text), '')::numeric < 0
    OR NULLIF(TRIM(nilai_angka::text), '')::numeric > 100);

-- Soal 18. Statistik deskriptif nilai valid
WITH nilai_valid AS (
    SELECT NULLIF(TRIM(nilai_angka::text), '')::numeric AS angka
    FROM src.nilai
)
SELECT
    COUNT(*)                AS valid_rows,
    MIN(angka)              AS nilai_minimum,
    MAX(angka)              AS nilai_maksimum,
    ROUND(AVG(angka), 2)    AS nilai_rata_rata
FROM nilai_valid
WHERE angka BETWEEN 0 AND 100;


-- =====================================================================
-- H. Nilai - Konsistensi Nilai Angka, Nilai Huruf, dan Status Kelulusan
-- =====================================================================

-- Soal 19. Konsistensi nilai angka dan nilai huruf
-- Aturan konversi di bawah adalah aturan pemeriksaan yang dipakai laporan.
-- Konfirmasikan kembali dengan data dictionary/dosen sebelum menjadikannya aturan resmi.
WITH nilai_valid AS (
    SELECT
        nilai_id,
        NULLIF(TRIM(nilai_angka::text), '')::numeric AS angka,
        TRIM(nilai_huruf) AS huruf
    FROM src.nilai
)
SELECT COUNT(*) AS letter_mismatch
FROM nilai_valid
WHERE angka BETWEEN 0 AND 100
  AND huruf IS DISTINCT FROM CASE
        WHEN angka >= 85 THEN 'A'
        WHEN angka >= 80 THEN 'AB'
        WHEN angka >= 75 THEN 'B'
        WHEN angka >= 70 THEN 'BC'
        WHEN angka >= 60 THEN 'C'
        WHEN angka >= 50 THEN 'D'
        ELSE 'E'
      END;

-- Soal 20. Konsistensi nilai angka dan status kelulusan
-- Pemeriksaan menggunakan ambang sementara: nilai >= 60 = Lulus, nilai < 60 = Tidak Lulus.
-- Konfirmasikan ambang ini dengan aturan akademik resmi.
WITH nilai_valid AS (
    SELECT
        NULLIF(TRIM(nilai_angka::text), '')::numeric AS angka,
        TRIM(status_lulus) AS status_lulus
    FROM src.nilai
)
SELECT COUNT(*) AS status_mismatch
FROM nilai_valid
WHERE angka BETWEEN 0 AND 100
  AND ( (angka >= 60 AND status_lulus IS DISTINCT FROM 'Lulus')
     OR (angka <  60 AND status_lulus IS DISTINCT FROM 'Tidak Lulus') );


-- =====================================================================
-- I. Nilai - Duplikasi Data
-- =====================================================================

-- Soal 21. Duplikasi record nilai
SELECT
    nim,
    kode_mk,
    semester_id,
    COUNT(*) AS jumlah
FROM src.nilai
GROUP BY nim, kode_mk, semester_id
HAVING COUNT(*) > 1
ORDER BY jumlah DESC, nim, kode_mk, semester_id;


-- =====================================================================
-- J. Referential Integrity - KRS, Nilai, Mahasiswa, Mata Kuliah, Semester
-- =====================================================================

-- Soal 22. NIM KRS tidak terdaftar di mahasiswa
SELECT COUNT(*) AS krs_nim_tidak_terdaftar
FROM src.krs k
LEFT JOIN src.mahasiswa m ON k.nim = m.nim
WHERE m.nim IS NULL;

-- Soal 23. NIM nilai tidak terdaftar di mahasiswa
SELECT COUNT(*) AS nim_tidak_terdaftar
FROM src.nilai n
LEFT JOIN src.mahasiswa m ON n.nim = m.nim
WHERE m.nim IS NULL;

-- Soal 24. Kode MK nilai tidak ada di mata_kuliah
SELECT COUNT(*) AS orphan_nilai_mk
FROM src.nilai n
LEFT JOIN src.mata_kuliah mk ON n.kode_mk = mk.kode_mk
WHERE mk.kode_mk IS NULL;

-- Soal 25. Semester nilai tidak ada di semester
SELECT COUNT(*) AS orphan_nilai_semester
FROM src.nilai n
LEFT JOIN src.semester s ON n.semester_id = s.semester_id
WHERE s.semester_id IS NULL;


-- =====================================================================
-- K. Aktivitas LMS - Uniqueness dan Distribution
-- =====================================================================

-- Soal 26. Duplikasi aktivitas LMS (lms_event_id)
SELECT
    COUNT(*)                          AS raw_rows,
    COUNT(DISTINCT lms_event_id)      AS distinct_event_id,
    COUNT(*) - COUNT(DISTINCT lms_event_id) AS duplicate_excess
FROM src.aktivitas_lms;

-- Soal 27. Distribusi tipe aktivitas LMS
SELECT
    tipe_event,
    COUNT(*) AS jumlah
FROM src.aktivitas_lms
GROUP BY tipe_event
ORDER BY jumlah DESC, tipe_event;

-- Soal 28. Skor kuis kosong pada quiz_attempt
SELECT COUNT(*) AS quiz_missing_score
FROM src.aktivitas_lms
WHERE tipe_event = 'quiz_attempt'
  AND (skor_kuis IS NULL OR TRIM(skor_kuis::text) = '');

-- Soal 29. Skor pada aktivitas selain kuis
SELECT COUNT(*) AS nonquiz_with_score
FROM src.aktivitas_lms
WHERE tipe_event <> 'quiz_attempt'
  AND skor_kuis IS NOT NULL
  AND TRIM(skor_kuis::text) <> '';


-- =====================================================================
-- L. Pembayaran - Validity dan Completeness
-- =====================================================================

-- Soal 30. Nominal pembayaran negatif
SELECT COUNT(*) AS negative_payment
FROM src.pembayaran
WHERE nominal_bayar < 0;

-- Soal 31. Pembayaran positif tanpa tanggal bayar
SELECT COUNT(*) AS positive_payment_missing_date
FROM src.pembayaran
WHERE nominal_bayar > 0
  AND (tanggal_bayar_raw IS NULL OR TRIM(tanggal_bayar_raw) = '');

-- Soal 32. Distribusi status pembayaran
SELECT
    status_pembayaran,
    COUNT(*) AS jumlah
FROM src.pembayaran
GROUP BY status_pembayaran
ORDER BY jumlah DESC, status_pembayaran;


-- =====================================================================
-- M. Kelulusan - Uniqueness dan Distribution
-- =====================================================================

-- Soal 33. Duplikasi data kelulusan
SELECT
    COUNT(*)                         AS raw_rows,
    COUNT(DISTINCT nim)              AS distinct_graduate_nim,
    COUNT(*) - COUNT(DISTINCT nim)   AS duplicate_excess
FROM src.kelulusan;

-- Soal 34. Status kelulusan tepat waktu
SELECT
    status_tepat_waktu,
    COUNT(*) AS jumlah
FROM src.kelulusan
GROUP BY status_tepat_waktu
ORDER BY jumlah DESC, status_tepat_waktu;


-- =====================================================================
-- N. Relasi Antar-Tabel - Referential Integrity
-- =====================================================================

-- Soal 35. Aktivitas LMS dengan NIM tidak terdaftar
SELECT COUNT(*) AS orphan_lms_student
FROM src.aktivitas_lms a
LEFT JOIN src.mahasiswa m ON a.nim = m.nim
WHERE m.nim IS NULL;

-- Soal 36. Aktivitas LMS dengan kode MK tidak terdaftar
SELECT COUNT(*) AS orphan_lms_course
FROM src.aktivitas_lms a
LEFT JOIN src.mata_kuliah mk ON a.kode_mk = mk.kode_mk
WHERE mk.kode_mk IS NULL;

-- Soal 37. Pembayaran dengan NIM tidak terdaftar
SELECT COUNT(*) AS orphan_payment_student
FROM src.pembayaran p
LEFT JOIN src.mahasiswa m ON p.nim = m.nim
WHERE m.nim IS NULL;

-- Soal 38. Kelulusan dengan NIM tidak terdaftar
SELECT COUNT(*) AS orphan_graduation_student
FROM src.kelulusan k
LEFT JOIN src.mahasiswa m ON k.nim = m.nim
WHERE m.nim IS NULL;
