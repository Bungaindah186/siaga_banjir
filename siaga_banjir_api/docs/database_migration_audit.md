# Audit Skema Database dan Migration Siaga Banjir

## Cakupan dan metode

Audit dilakukan pada database `siaga_banjir` yang dipilih oleh konfigurasi koneksi Laravel saat pemeriksaan. Inventarisasi objek dan penghitungan jumlah baris menggunakan query baca saja ke `information_schema` dan `SELECT COUNT(*)` untuk setiap tabel. File migration dibaca sebagai teks; tidak ada migration atau operasi tulis database yang dijalankan.

## Hasil terverifikasi

- Koneksi Laravel ke database `siaga_banjir` berhasil.
- Ditemukan **0 objek tabel/view** pada saat audit.
- Karena tidak ada tabel, tidak ada tabel aplikasi atau baris data yang ditemukan pada database ini saat audit. Tidak ada benturan nama tabel yang terlihat pada saat tersebut.
- Tabel pencatat migration `migrations` juga belum ada. Dengan demikian belum ada catatan migration yang dapat dibaca.
- Audit ini tidak memeriksa database lain, backup, atau sumber data di luar database `siaga_banjir`.
- Keempat file migration yang tersedia menggunakan `Schema::create`; tidak ada yang menggunakan `Schema::table` untuk mengubah tabel yang sudah ada.

## Rincian file migration

### Migration bawaan Laravel

1. `database/migrations/0001_01_01_000000_create_users_table.php`
   - `up()` membuat `users` (id, nama, email unik, status verifikasi email, password, remember token, timestamps), `password_reset_tokens`, dan `sessions`.
   - `down()` menghapus `users`, `password_reset_tokens`, dan `sessions` jika ada.
   - `sessions` diperlukan oleh `SESSION_DRIVER=database`.

2. `database/migrations/0001_01_01_000001_create_cache_table.php`
   - `up()` membuat `cache` dan `cache_locks`.
   - `down()` menghapus kedua tabel tersebut jika ada.
   - Keduanya merupakan tabel penyimpanan untuk cache/lock database.

3. `database/migrations/0001_01_01_000002_create_jobs_table.php`
   - `up()` membuat `jobs`, `job_batches`, dan `failed_jobs`.
   - `down()` menghapus ketiga tabel tersebut jika ada.
   - `jobs` diperlukan oleh koneksi antrean database; dua tabel lainnya mendukung batch dan catatan kegagalan.

### Migration Laravel Sanctum

4. `database/migrations/2026_10_23_070947_create_personal_access_tokens_table.php`
   - `up()` membuat `personal_access_tokens` untuk token API Sanctum, dengan kolom morph `tokenable`, nama, token unik, abilities, tanggal penggunaan/kedaluwarsa, dan timestamps.
   - `down()` menghapus `personal_access_tokens` jika ada.

File-file di atas **membuat** tabel dan tidak menambahkan kolom ke tabel aplikasi yang telah ada. Tidak satu pun dijalankan dalam audit ini.

## Usulan urutan dan dampak — belum dijalankan

1. **Usulan:** cadangkan database dan tinjau kembali inventaris tepat sebelum perubahan.
2. **Usulan:** jalankan migration bawaan Laravel sesuai urutan timestamp: migration pengguna/sesi, cache, lalu antrean.
3. **Usulan:** jalankan migration Sanctum setelah migration bawaan agar tabel token tersedia untuk tahap autentikasi berikutnya.
4. **Usulan:** setelahnya, baca kembali tabel dan status migration untuk memastikan hasilnya.

Pada database yang terverifikasi kosong, menjalankan seluruh migration tersebut akan membuat tabel berikut: `users`, `password_reset_tokens`, `sessions`, `cache`, `cache_locks`, `jobs`, `job_batches`, `failed_jobs`, dan `personal_access_tokens`. Laravel juga mengelola tabel metadata `migrations` saat migrator dijalankan; tabel ini tidak dideklarasikan oleh empat file di atas. Migration `down()` menghapus tabel yang dibuat oleh file terkait dan karena itu dapat menghapus data di dalam tabel tersebut jika kelak sudah terisi. Jangan gunakan rollback/fresh/wipe sebagai langkah persiapan database yang berisi data.

## Batas audit

Hasil inventarisasi mencerminkan database pada saat query dijalankan. Audit ini tidak membuktikan bahwa database akan tetap kosong saat migration kelak dijalankan. Sebelum eksekusi, ulangi pemeriksaan tabel dan pastikan target koneksi tetap `siaga_banjir`.
