# Inventaris Layar — Siaga Banjir Padang

## Status pemeriksaan visual

Folder `E:\Flutter project\docs\reference\` berisi 25 PDF bernama `Mobile-*.pdf` dan satu PDF BRD. Semua file desain lokal dapat dibuka sebagai berkas, tetapi pemeriksaan visual halaman **belum dapat dilakukan** di lingkungan ini: tidak tersedia `pdftoppm`, `pdftocairo`, `mutool`, ImageMagick, atau library Python PDF; percobaan Edge headless untuk merender halaman gagal sebelum membuat screenshot. PDF desain memakai glif/encoding khusus sehingga ekstraksi teks mentah tidak memberikan label UI yang dapat dipercaya. Karena itu saya tidak akan mengklaim telah memeriksa warna, tipografi, ikon, jarak, susunan komponen, ataupun affordance tombol.

Inventaris di bawah memetakan file desain ke kebutuhan/aksi yang tertulis di BRD. Kolom elemen UI menyebut elemen fungsional yang **diharapkan menurut BRD**, bukan hasil pengamatan visual. Nama layar berasal dari nama file. Detail visual masih memerlukan render PNG/JPG atau akses ke PDF viewer yang dapat digunakan.

## Inventaris desain Android

| ID / berkas desain | Layar dan elemen fungsional yang tertulis di BRD | Aksi/navigasi yang tertulis atau diturunkan langsung dari alur BRD | Data yang diperlukan | Status bukti visual |
|---|---|---|---|---|
| S-01 `Mobile-Welcome.pdf` | Onboarding; BRD meminta onboarding serta penafian SOS simulasi dan permintaan izin yang bisa ditunda | Lanjut ke autentikasi; izin dapat ditunda “Nanti saja” | status onboarding, izin lokasi/notifikasi, teks penafian | Susunan/ilustrasi/CTA belum terverifikasi |
| S-02 `Mobile-login.pdf` | Form email dan kata sandi; BRD FR-002 juga menyebut Google Sign-In warga | Masuk; menuju beranda saat sukses; error untuk kredensial salah | email, password, hasil auth, opsi Google (keputusan Q-04) | Field/penempatan tombol belum terverifikasi |
| S-03 `Mobile-Sign up.pdf` | Pendaftaran email, kata sandi, persetujuan kebijakan privasi | Daftar; validasi email unik dan persetujuan; lanjut login/beranda | nama/email/password, consent; nomor HP/alamat menurut profil BRD | Field wajib dan urutannya belum terverifikasi |
| S-04 `Mobile-Home.pdf` | Status dan keterangan, waktu pembaruan, cuaca singkat, peta mini, navigasi utama; status warna + label | Buka Status Siaga, peta/evakuasi, cuaca, sungai, SOS, notifikasi, edukasi, menu | alert terbaru, cuaca/cache, ringkasan lokasi bahaya, notifikasi | Tata letak, warna, navigasi aktual belum terverifikasi |
| S-05 `Mobile-StatusSiaga.pdf` | Empat level Aman/Waspada/Siaga/Awas dan keterangannya; Awas berarti evakuasi | Buka detail status/imbauan terkait | level, deskripsi, waktu update, peringatan | Ambang tiap level di Padang belum ditetapkan; visual tak terbaca |
| S-06 `Mobile-Kirim SOS.pdf` | Pilihan Terjebak/Terluka/Butuh Evakuasi; pilihan berbagi keluarga; tombol tahan 3 detik | Pilih jenis; pilih berbagi; tahan kontinu; lepas dini membatalkan; sukses ke status SOS | jenis, share-to-family, lokasi sekali dengan izin, waktu, jaringan | Posisi kontrol dan indikator countdown belum terverifikasi |
| S-07 `Mobile- SOS terkirim.pdf` | Konfirmasi setelah submit dan status awal Menunggu konfirmasi petugas menurut BRD | Lihat detail/status; akses pembatalan jika status masih memenuhi aturan (aturan belum ditentukan) | ID SOS, jenis, waktu, status, lokasi sesuai hak akses | Copy/layout/status tindakan belum terverifikasi |
| S-08 `Mobile-Evakuasi.pdf` | Posko/titik pengungsian, kondisi jalan terbuka/tertutup, rute; jarak terdekat | Pilih titik/rute untuk detail; sumber lokasi perangkat atau rumah fallback | posko, rute, segmen jalan, koordinat, jarak, waktu update | Peta/daftar/legenda belum terverifikasi |
| S-09 `Mobile-Cuaca.pdf` | Prakiraan BMKG per kelurahan, prakiraan 3 hari menurut BRD; atribusi BMKG; error/cache saat gagal | Pilih/lihat prakiraan lokasi | kode wilayah BMKG, prakiraan, waktu/sumber, cache/status unavailable | Elemen prakiraan dan atribusi aktual belum terlihat |
| S-10 `Mobile-Ketinggian sungai.pdf` | TMA cm, level dan tren per titik, waktu input petugas | Pilih titik pantau (navigasi diasumsikan dari kebutuhan multi-titik; visual belum dicek) | stasiun, bacaan, tren, level manual, waktu, flag simulasi | Grafik/format indikator belum terverifikasi |
| S-11 `Mobile-Lapor warga.pdf` | Lokasi dan jenis wajib, deskripsi, foto opsional berbatas ukuran | Kirim laporan; tampil Diproses; lokasi hanya saat laporan dan izin | jenis, deskripsi, koordinat, waktu, foto, status | Form/validasi dan tombol belum terverifikasi |
| S-12 `Mobile-Gabung keluarga dgn kode.pdf` | Masuk kelompok dengan kode; kode salah/kedaluwarsa ditolak | Masukkan kode, kirim, tampilkan hasil gabung/error | kode undangan, expiry, anggota/grup | Input/CTA belum terverifikasi |
| S-13 `Mobile-Tambah Anggota dgn kode.pdf` | Buat/bagikan kode unik berlaku 24 jam; salin/WhatsApp menurut FR-018 | Buat kode; salin/bagikan; refresh bila kedaluwarsa (aksi terakhir perlu konfirmasi) | kode, expiry, pemilik grup, anggota | Tampilan kode/aksi share belum terverifikasi |
| S-14 `Mobile-Tambah Anggota dgn no hp.pdf` | BRD FR-017 menyebut gabung lewat nomor HP; mekanisme undangan belum dijelaskan | Aksi nomor HP belum bisa ditetapkan; tidak mengirim SMS (out of scope) | nomor HP dan pencarian/undangan yang perlu diputuskan | Tujuan dan flow visual belum diverifikasi |
| S-15 `Mobile-status Keluarga.pdf` | Status Aman/Waspada/Darurat/Butuh Bantuan beserta waktu anggota | Ubah status sendiri; lihat status anggota yang sama grup | member, status, timestamp, otorisasi keanggotaan | Kartu/status/warna belum terverifikasi |
| S-16 `Mobile-ChatKeluarga.pdf` | Chat anggota keluarga; pesan terbatas pada anggota grup sama | Buka percakapan, kirim pesan; Could menurut BRD | pesan, pengirim, grup, waktu, status pengiriman | Layout chat/attachment/aksi belum terverifikasi |
| S-17 `Mobile-Edukasi.pdf` | Artikel langkah evakuasi, isi tas siaga, level siaga | Pilih artikel dan buka detail (detail PDF terpisah tidak ditemukan) | konten, kategori, gambar/sumber jika ada | Daftar/detail dan visual belum terverifikasi |
| S-18 `Mobile-isi tas siaga.pdf` | Checklist item; progres harus tersimpan setelah aplikasi ditutup | Centang/batalkan item | katalog item, status centang per pengguna | Daftar item awal/CTA belum terverifikasi |
| S-19 `Mobile-Riwayat bencana.pdf` | Daftar kejadian lalu beserta level, urut terbaru | Pilih kejadian untuk detail (detail tidak ditegaskan dalam FR) | kejadian, tanggal, level, ringkasan | Bentuk daftar/detail belum terverifikasi |
| S-20 `Mobile-Kontak.pdf` | Kontak BPBD, Damkar, PMI, posko; tombol membuka dialer | Pilih kontak dan buka dialer | nama layanan, nomor terverifikasi, jenis kontak | Nomor dan tindakan visual belum terverifikasi |
| S-21 `Mobile-Profil.pdf` | Profil nama, nomor HP, lokasi rumah | Lihat/ubah/simpan data diri | user, nomor HP, alamat/lokasi rumah | Field dan validasi belum terverifikasi |
| S-22 `Mobile-Pengaturan.pdf` | Preferensi dan pengaturan akun; BRD menyebut izin/notifikasi dan privasi | Ubah preferensi/akun (opsi persis belum disebut BRD) | notification preferences, consent, profil | Item menu/tindakan belum terverifikasi |
| S-23 `Mobile-Notifikasi.pdf` | Daftar peringatan dan artikel, urut terbaru, tautan ke detail | Buka notifikasi/halaman tujuan; menandai dibaca hanya jika desain memuatnya (belum diketahui) | notifikasi, jenis, waktu, tujuan, status baca | Aksi dan empty state belum terverifikasi |
| S-24 `Mobile-Menu.pdf` | Navigasi ke fitur Android; daftar item menu tidak dapat dibaca dari nama berkas | Buka layar fitur | sesi pengguna dan tujuan navigasi | Struktur/menu/ikon tidak dapat diverifikasi |
| S-25 `Mobile-Logo.pdf` | Aset identitas aplikasi | Tidak ada aksi layar; aset digunakan sesuai desain | file logo, varian/ukuran | Warna/bentuk/rasio belum dapat dilihat |

## Web warga (BRD; tidak ada PDF Web warga yang teridentifikasi)

| Halaman konseptual | Elemen/aksi berdasarkan BRD | Data |
|---|---|---|
| Beranda/status | Status, waktu update, cuaca singkat, peta/status; navigasi info | status, warning, cuaca |
| Peta dan evakuasi | Titik bahaya, posko, laporan terverifikasi, jalan/rute | lokasi, posko, rute, laporan terverifikasi |
| Cuaca dan sungai | Prakiraan BMKG dan atribusi; TMA, level, tren, waktu | cuaca/cache, bacaan sungai |
| Peringatan/notifikasi | Peringatan web diputuskan ada; izin browser/layanan belum dipilih | announcement, preference/delivery state |
| Laporan | Form dan riwayat sesuai BRD; tanpa SOS | laporan milik pengguna, foto, status |
| Edukasi/tas/riwayat/kontak | Informasi sama seperti Android; kontak membuka dialer yang tersedia | konten, checklist (persistensi di web belum dijabarkan), histori, kontak |
| Akun/profil | Login/registrasi/profil warga sesuai fungsi lintas platform | user/profile |

Desain web warga disebut di BRD sebagai sudah menyesuaikan, tetapi file desain web tidak ditemukan pada berkas yang terdaftar di folder acuan ini.

## Dashboard petugas (BRD; desain belum tersedia/terkonfirmasi)

| Halaman konseptual | Elemen/aksi berdasarkan BRD | Data |
|---|---|---|
| Login petugas | Email, autentikasi, akses satu peran petugas | staff user/session |
| Ringkasan | Jumlah SOS/laporan/status siaga; komposisi angka belum dirinci | SOS, reports, current alert |
| Antrian SOS/detail | Daftar waktu, jenis, lokasi, kontak; konfirmasi; update Ditangani/Selesai; riwayat tindakan | SOS, status history, lokasi dan audit |
| Verifikasi laporan | Detail teks/foto/lokasi; setuju atau tolak | report, photo, verification history |
| Kelola data peta/evakuasi | CRUD titik bahaya, posko, rute, status jalan | danger point, post, route, road segment |
| Status, sungai, peringatan | Set status dan keterangannya; input bacaan manual; rilis alert | alert, river reading |
| Konten | CRUD edukasi, kontak darurat, riwayat bencana | educational content, contact, disaster history |

Tidak ada desain petugas yang dapat diidentifikasi; BRD mencatat kebutuhan desain dashboard perlu dikonfirmasi/dibuat. Semua halaman di atas adalah pemetaan kebutuhan, bukan hasil inspeksi UI.

## Navigasi lintas layar dan data sensitif

- Beranda menjadi titik masuk informasi dan akses SOS; FR-006 menyebut peta mini, FR-005 cuaca singkat.
- Menu menuju fitur sesuai daftar Android in-scope, tetapi urutan/tab bar/drawer tidak dapat diverifikasi.
- SOS hanya menyimpan lokasi ketika pengguna melakukan aksi dan menyetujui izin; tidak ada background tracking.
- Laporan ditandai Diproses sampai petugas memverifikasi; hanya yang disetujui masuk peta publik.
- Semua titik bahaya/posko/rute/TMA/status/peringatan demo diberi label simulasi, provenance, dan waktu update; batas Padang tidak boleh diisi memakai angka Katulampa.
- Family group membatasi status/chat ke anggota yang sama; share SOS ke keluarga hanya jika dipilih pengirim.

## Pembaruan keputusan pengguna (23 Oktober 2026)

Pembaruan alur berikut bersumber dari keputusan pengguna; elemen visual PDF tetap belum diverifikasi.

- **S-02/S-03 autentikasi:** warga wajib email + kata sandi; Google Sign-In boleh ditambahkan jika konfigurasi memungkinkan. Jangan menambahkan OTP atau Apple login. Akun petugas tidak didaftarkan dari UI publik.
- **S-06/S-07 SOS:** tekan harus genap 3 detik; jika jari dilepas lebih awal, jangan membuat SOS server. Jika sukses, status awal `Menunggu konfirmasi petugas`. Warga dapat membatalkan status `Menunggu konfirmasi petugas`, `Terkonfirmasi`, dan `Ditangani`; pada status terakhir ubah menjadi `Dibatalkan`. Jangan hapus detail atau histori; semua waktu dan aktor tampil/tercatat untuk petugas. Penafian bahwa ini simulasi tetap diperlukan.
- **S-12/S-14/S-15 keluarga:** join dengan kode tetap didukung. Pencarian melalui nomor HP menghasilkan permintaan yang perlu disetujui penerima; sebelum persetujuan jangan tampilkan data grup atau tambahkan anggota. Tidak ada SMS/OTP.
- **S-16 chat:** tetap direncanakan sebagai prioritas rendah dan hanya bila waktu memungkinkan.
- **S-08 peta/evakuasi:** mulai dari peta sederhana; vendor/SDK dan dukungan rute belum diputuskan. Semua lokasi simulasi perlu label `DEMO`/`DATA SIMULASI`.
- **S-23 notifikasi:** tahap awal notifikasi dalam aplikasi. Jangan menyebut push tersedia sampai integrasi dibuat dan diuji. Apakah web warga memiliki notifikasi in-app masih perlu ditentukan.
- **S-10 sungai/S-05 siaga:** ambang demo berlabel `DEMO`/`DATA SIMULASI`; nilai Katulampa tidak menjadi ambang resmi Padang.

## Berkas desain yang ditemukan dan status periksa

Semua berikut ditemukan lokal, tetapi visualnya belum tervalidasi:

`Mobile- SOS terkirim.pdf`, `Mobile-ChatKeluarga.pdf`, `Mobile-Cuaca.pdf`, `Mobile-Edukasi.pdf`, `Mobile-Evakuasi.pdf`, `Mobile-Gabung keluarga dgn kode.pdf`, `Mobile-Home.pdf`, `Mobile-isi tas siaga.pdf`, `Mobile-Ketinggian sungai.pdf`, `Mobile-Kirim SOS.pdf`, `Mobile-Kontak.pdf`, `Mobile-Lapor warga.pdf`, `Mobile-login.pdf`, `Mobile-Logo.pdf`, `Mobile-Menu.pdf`, `Mobile-Notifikasi.pdf`, `Mobile-Pengaturan.pdf`, `Mobile-Profil.pdf`, `Mobile-Riwayat bencana.pdf`, `Mobile-Sign up.pdf`, `Mobile-status Keluarga.pdf`, `Mobile-StatusSiaga.pdf`, `Mobile-Tambah Anggota dgn kode.pdf`, `Mobile-Tambah Anggota dgn no hp.pdf`, `Mobile-Welcome.pdf`.

Untuk menyelesaikan inspeksi visual secara akurat, sediakan ekspor PNG/JPG tiap frame atau screenshot dari PDF viewer (nama file yang sama sudah cukup). Setelah itu warna, tipografi, layout, ikon, state/error/empty, dan alur yang tampak dapat dicatat tanpa menebak.
