# Rencana Implementasi — Siaga Banjir Padang

## Cakupan dan prinsip

Dokumen ini adalah hasil Tahap 1 (audit dan perencanaan). BRD dan berkas desain yang ada di `E:\Flutter project\docs\reference\` menjadi acuan utama. Data banjir, lokasi, tinggi sungai, dan status pada tahap simulasi harus diberi label yang jelas. Integrasi cuaca tidak boleh mengesankan data BMKG resmi bila sumber belum dikonfigurasi dan diverifikasi. SOS merupakan simulasi koordinasi aplikasi; tidak menjanjikan respons layanan darurat sungguhan.

Jangan menimpa proyek Flutter yang ada. Backend Laravel ditempatkan terpisah di `E:\Flutter project\siaga_banjir_api`. Ketiga antarmuka (Android, web warga, dashboard petugas) menggunakan API dan database Laravel yang sama.

## Temuan audit

- Workspace Flutter tersedia di `E:\Flutter project\flutter_firstapp`; struktur platform Flutter standar (Android, iOS, web, Windows, macOS, Linux) telah ada.
- `lib/main.dart` masih aplikasi contoh penghitung Flutter. `pubspec.yaml` hanya berisi Flutter dan `cupertino_icons`; belum ada struktur fitur, API, maupun model domain aplikasi.
- `test/widget_test.dart` ada sebagai bagian scaffold. Tidak dijalankan pada tahap audit.
- Tersedia folder acuan `E:\Flutter project\docs\reference\` dengan `Tugas PBP_BRD_SiagaBanjir.pdf` dan PDF desain untuk Welcome, login, Sign up, Home, StatusSiaga, SOS, SOS terkirim, Evakuasi, Cuaca, Ketinggian sungai, laporan warga, keluarga/chat, profil, menu, notifikasi, pengaturan, edukasi, tas siaga, kontak, riwayat bencana, dan logo.
- Berkas PDF tersedia secara lokal; tahap berikut perlu menelaah isi BRD dan layar secara langsung sebelum keputusan UI/domain dirinci. Nama berkas saja tidak cukup untuk menetapkan perilaku yang ambigu.
- Backend `E:\Flutter project\siaga_banjir_api` belum ada. Folder usulan referensi sudah tersedia di luar workspace Flutter.
- Flutter SDK ditemukan di `E:\SDK\flutter`; Dart yang disertakan melaporkan versi 3.13.2. Android SDK pada brief menunjuk `E:\Android\SDK` dan `adb.exe` terdeteksi. `android/local.properties` menunjuk Flutter SDK tersebut. Versi Flutter sendiri belum terkonfirmasi karena perintah `flutter --version` tidak mengembalikan versinya pada pemeriksaan ini.
- PHP dan Composer tidak terdeteksi di `PATH`. Laragon terpasang di `E:\laragon`; PHP CLI `8.3.33` dan Composer `2.10.2` tersedia di direktori Laragon dan berhasil diperiksa dengan menjalankan Composer PHAR melalui PHP eksplisit. `composer.bat` gagal karena `php` tidak dikenali di `PATH`, sehingga shell umum belum siap memakai Composer langsung. MySQL tersedia sebagai `mysql-8.4.3-winx64`; direktori Apache, Nginx, dan Composer ada. Versi klien/server MySQL, konfigurasi koneksi, database, dan status layanan belum dikonfirmasi. Tidak ada layanan atau konfigurasi Laragon yang diubah.
- Tidak ada konfigurasi jaringan perangkat, port layanan, IP laptop, atau konfigurasi kredensial database yang diasumsikan.

## Arsitektur yang direncanakan

### Android Flutter

Pisahkan fitur, lapisan data, model, dan komponen UI. Kelompok awal yang disarankan: `core` (konfigurasi API, klien HTTP, error, tema), `features/auth`, `home`, `map_evacuation`, `weather_river`, `sos`, `reports`, `family`, `education`, dan `profile_settings`. Gunakan satu base URL yang dapat dikonfigurasi untuk emulator/perangkat fisik; lokasi hanya diminta saat SOS/laporan memerlukannya. Status offline/error harus membedakan data demo dari data server.

### Laravel API dan web

Satu aplikasi Laravel di folder backend terpisah menyediakan REST API untuk Flutter serta Blade untuk web warga dan dashboard. Sanctum layak dievaluasi untuk token aplikasi Flutter; autentikasi sesi untuk web; otorisasi petugas ditegakkan di middleware/policy. Versi Laravel harus dipilih berdasarkan PHP/Composer yang terpasang dan dukungan paket.

Kelompok domain awal (akan disesuaikan setelah telaah BRD): pengguna/profil dan peran petugas; status siaga/peringatan; titik bahaya, posko, rute, dan pembacaan sungai; SOS beserta riwayat status/audit tindakan; laporan beserta foto/status verifikasi; grup/keanggotaan/invitasi/pesan keluarga; konten edukasi/checklist; kontak darurat, riwayat bencana, serta preferensi/notifikasi jika dibutuhkan. Publik hanya menerima laporan terverifikasi. Operasi SOS dan transisi status penting menggunakan transaksi dan riwayat perubahan.

### Web warga dan dashboard petugas

Web warga Blade responsif menampilkan informasi, peta, peringatan, edukasi, dan pelaporan sesuai BRD tanpa fitur SOS/keluarga Android. Dashboard petugas memakai identitas/peran petugas yang sama di seluruh panel, dengan ringkasan dan alur kerja SOS, verifikasi laporan, serta pengelolaan data simulasi. Semua aksi petugas diautentikasi dan tercatat.

## Struktur folder sasaran

```text
flutter_firstapp/
  lib/core/...
  lib/features/<feature>/{data,domain,presentation}/...
  docs/implementation_plan.md
  README.md
siaga_banjir_api/
  app/{Http,Models,Policies}/...
  database/{migrations,seeders}/
  resources/views/{citizen,staff}/
  routes/{api,web}.php
  tests/{Feature,Unit}/
  README.md
```

Struktur ini sasaran, bukan instruksi untuk membuat seluruh file sekaligus. Ikuti pola yang paling sederhana yang cocok dengan versi Laravel dan kebutuhan BRD.

## Urutan pengerjaan

1. **Persetujuan dan penajaman acuan:** telaah BRD serta PDF layar, petakan alur/komponen/teks, catat konflik dan keputusan terbuka. Konfirmasi konfigurasi PHP/Composer/Laragon/MySQL yang aktif serta ketersediaan database lokal; jangan mengubah konfigurasi Laragon otomatis.
2. **Fondasi:** setelah rencana disetujui, buat proyek Laravel hanya di folder backend terpisah; tetapkan versi dan konfigurasi `.env` lokal dari nilai yang diberikan pengguna; buat skema dan seed awal; rapikan struktur Flutter tanpa menghilangkan file scaffold; siapkan base URL API dan dokumentasi menjalankan sistem.
3. **Akun:** implementasikan registrasi, login, profil, validasi, logout, autentikasi API, dan autentikasi petugas sesuai metode BRD.
4. **Informasi siaga:** bangun beranda, status dan peringatan, data lokasi bahaya/posko/rute, peta, cuaca (adapter backend terpisah; unavailable/demo saat integrasi belum terverifikasi), dan tinggi sungai simulasi.
5. **SOS dan operasi petugas:** tahan 3 detik penuh, batal saat dilepas lebih awal, pilihan berbagi keluarga, snapshot lokasi dengan izin, penyimpanan server, konfirmasi dan transisi status oleh petugas, pembatalan sesuai status, serta riwayat/audit.
6. **Laporan:** kirim laporan dan foto tervalidasi, simpan status, verifikasi petugas, dan batasi peta publik ke laporan terverifikasi.
7. **Keluarga:** grup, undangan, akses berbasis keanggotaan, status anggota, chat dan preferensi berbagi SOS sesuai desain.
8. **Kesiapsiagaan:** edukasi (minimal tiga artikel), checklist tas (minimal satu seed), riwayat bencana, kontak darurat, notifikasi dan preferensi.
9. **Web:** implementasikan web warga dan lengkapi dashboard petugas berdasarkan BRD; responsif dan memakai data/backend yang sama.
10. **Integrasi dan verifikasi:** dokumentasikan endpoint; jalankan unit/API/widget test yang relevan dan uji alur login, SOS hingga selesai, serta laporan hingga terverifikasi. Uji koneksi perangkat vivo hanya setelah URL jaringan/port yang benar diketahui; catat hasil aktual dan pekerjaan manual.

## Risiko dan hal yang perlu dipastikan

- **Detail BRD/desain:** telaah isi PDF belum diselesaikan dalam audit awal. Sebelum implementasi UI dan skema final, cocokkan alur dan istilah di BRD dengan tiap layar; catat konflik yang nyata agar dapat diputuskan.
- **Lingkungan PHP:** PHP 8.3.33 dan Composer 2.10.2 tersedia secara lokal, tetapi `composer.bat` belum bekerja dari shell umum karena PHP tidak ada di `PATH`. Jalankan melalui terminal Laragon atau siapkan pemanggilan executable yang tepat sebelum membuat proyek. Pastikan persyaratan versi Laravel terpilih cocok.
- **MySQL:** keberadaan binary tidak membuktikan server berjalan. Pengguna perlu memastikan status MySQL dan memberikan host, port, username, serta password yang benar untuk `.env` lokal (jangan masukkan rahasia ke source control).
- **Jaringan Android fisik:** perlu alamat laptop yang dapat dicapai perangkat atau port forwarding USB yang dipilih; jangan isi localhost/IP tebakan. Buka firewall hanya secara terarah jika diperlukan.
- **Sumber resmi:** endpoint cuaca BMKG dan sumber data resmi Padang untuk sungai, titik bahaya, posko, dan status perlu diverifikasi. Tanpa itu, gunakan data simulasi berlabel.
- **Privasi dan cakupan:** batasi data lokasi dan keluarga berdasarkan kebutuhan dan izin; jangan membuat OTP, Apple login, SMS darurat, atau pelacakan kontinu tanpa kebutuhan BRD.

## Status tahap

- Tahap 1: audit awal dan rencana ditulis.
- Tahap 1B: telaah kebutuhan BRD dan pemetaan layar didokumentasikan pada `docs/requirements_analysis.md` dan `docs/screen_inventory.md`; inspeksi visual PDF tetap belum terverifikasi karena kendala render.
- Keputusan pengguna 23 Oktober 2026: warga login email/password (Google opsional); permintaan keluarga via nomor HP memerlukan persetujuan penerima; SOS dapat dibatalkan pada Menunggu konfirmasi, Terkonfirmasi, atau Ditangani dan seluruh riwayat tetap disimpan; chat keluarga tetap prioritas rendah; peta awal sederhana dan notifikasi in-app; tidak ada klaim push tanpa implementasi/uji; akun petugas dibuat manual; ambang sungai/status demo berlabel DEMO/DATA SIMULASI dan tidak memakai Katulampa.
- Usulan retensi bertingkat dicatat untuk persetujuan pada `docs/requirements_analysis.md`; jangan aktifkan purge otomatis sebelum disetujui.
- Fondasi backend terpisah telah dibuat di `E:\Flutter project\siaga_banjir_api`: Laravel Framework 13.38.0, Sanctum 4.3.3, route `GET /api/user` terlindungi `auth:sanctum`, trait token pada User, dan migration template token Sanctum. Belum ada endpoint login/token, role petugas, tabel domain, controller fitur, atau halaman web.
- `.env` backend menarget `DB_CONNECTION=mysql` dan `DB_DATABASE=siaga_banjir`, tetapi host/port/username memakai placeholder dan password kosong sampai pemilik mengisinya langsung dari Laragon. Koneksi MySQL belum diuji; database MySQL pengguna tidak disentuh.
- **Catatan tindakan otomatis scaffold:** `composer create-project` menjalankan `post-create-project-cmd` bawaan skeleton Laravel, yang membuat `database/database.sqlite` dan menjalankan tiga migration awal framework pada SQLite lokal scaffold. `php artisan migrate:status` menunjukkan ketiganya berstatus Ran. Ini tidak menyambung ke MySQL `siaga_banjir`. Tidak ada migration domain atau migration Sanctum yang dijalankan; migration Sanctum hanya dipublikasikan dan masih pending.
- Status read-only terakhir dengan koneksi SQLite scaffold yang ditentukan eksplisit: tiga migration default berstatus Ran; `2026_10_23_070947_create_personal_access_tokens_table` berstatus Pending. Tidak ada migration yang dijalankan setelah publish Sanctum.
- Pemeriksaan route `php artisan route:list --path=api` berhasil dan menampilkan satu route terlindungi. Unit/feature test belum dijalankan. Tidak ada konfigurasi global Laragon/Windows atau layanan Windows yang diubah.
- Pemeriksaan build/test belum dijalankan; tidak ada klaim fitur berjalan.
- Langkah berikut yang disarankan: isi `.env` lokal sendiri dengan detail Laragon yang benar; verifikasi koneksi MySQL secara eksplisit sebelum meninjau dan menjalankan migration. Jangan menjalankan migration domain atau retensi otomatis sebelum skema/kebijakan disetujui.

## Keputusan kerja setelah pembaruan pengguna (23 Oktober 2026)

### Fondasi yang diizinkan

1. Pastikan target backend belum ada sebelum membuat apa pun; jangan menimpa folder.
2. Gunakan PHP 8.3.33 dan Composer 2.10.2 dari Laragon dengan pemanggilan yang eksplisit bila `PATH` terminal umum belum siap.
3. Pilih Laravel yang didukung PHP runtime. Fondasi boleh mencakup scaffold resmi, konfigurasi dasar, Sanctum/API routing, autentikasi sesi web, dokumentasi, dan konfigurasi `.env.example` tanpa rahasia.
4. Akun petugas dibuat manual; jangan sediakan registrasi petugas publik. Warga menggunakan email/password; Google hanya jika konfigurasi tersedia.
5. Gunakan database `siaga_banjir` yang telah dibuat pengguna. Jangan membuat/menghapus database, menebak password, atau menjalankan migration sebelum memeriksa status/isi migrasi dan persetujuan skema.
6. Catat lokasi/credentials lokal di `.env` hanya setelah nilainya diketahui; jangan menuliskannya di docs/source control. Jika tidak diketahui, biarkan nilai rahasia kosong/placeholder dan minta nilainya sebelum tes koneksi.
7. Gunakan `/api/v1` sebagai usulan namespace; API Flutter memakai token Sanctum, Blade memakai session middleware. Lindungi route petugas server-side. Implementasi fitur dan skema domain menunggu review desain skema.

### Urutan pengerjaan yang disepakati

1. Sinkronkan dokumen keputusan dan aturan SOS/keluarga/retensi.
2. Audit target backend dan cara menjalankan PHP/Composer Laragon; pilih versi Laravel berdasarkan dokumentasi resmi serta runtime.
3. Buat scaffold Laravel hanya di target terpisah jika target belum ada; pertahankan semua file yang mungkin sudah ada.
4. Siapkan `.env.example`, dokumentasi backend, API routing, Sanctum, dan sesi web. Siapkan `.env` lokal hanya dari konfigurasi yang diberikan/terverifikasi; jangan tampilkan rahasia.
5. Periksa versi Laravel dan daftar/status migration. Jangan jalankan migration yang belum direview; jangan membuat tabel domain pada fondasi.
6. Catat hasil uji yang benar-benar dilakukan. Uji koneksi hanya setelah kredensial diverifikasi; tidak ada migration otomatis.
7. Berhenti dan laporkan sebelum fitur warga, tabel domain, CRUD, dashboard, API BMKG, push, peta pihak ketiga, atau SOS dibangun.

### Pertanyaan terbuka yang masih mengubah implementasi

- Persetujuan usulan retensi data (90 hari lokasi/foto, 12 bulan kasus/audit, 90 hari chat) masih diperlukan sebelum purge otomatis.
- Kredensial/host/port MySQL untuk `.env` lokal perlu diambil dari konfigurasi Laragon, bukan ditebak.
- Versi minimum Android/browser, vendor/engine peta sederhana, ambang TMA dummy, detail laporan, expiry/ruang lingkup permintaan join via HP, serta alasan dan notifikasi pembatalan SOS masih perlu ditetapkan.
- Google Sign-In hanya opsional jika konfigurasi tersedia; push notification belum menjadi fitur terverifikasi.
- Ekspor raster desain diperlukan untuk memvalidasi tampilan sebelum implementasi UI.
