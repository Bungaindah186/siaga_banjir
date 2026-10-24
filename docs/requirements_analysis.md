# Analisis Kebutuhan — Siaga Banjir Padang

## 1. Sumber, status, dan batas analisis

**Sumber utama:** `E:\Flutter project\docs\reference\Tugas PBP_BRD_SiagaBanjir.pdf`, versi 0.1 draft, bertanggal 13 Oktober 2026, status belum ditinjau/disetujui. Isi teks BRD dibaca dari PDF. Dokumen memakai label `[Terkonfirmasi]`, `[Asumsi]`, `[Perlu validasi]`, `[Perlu konfirmasi]`, `[Usulan]`, serta prioritas Must/Should/Could; label-label itu dipertahankan maknanya di sini.

**Sumber pelengkap:** brief kebutuhan yang diberikan dalam percakapan dan metadata/nama PDF desain yang berada di `E:\Flutter project\docs\reference\`. Isi visual PDF desain belum berhasil diperiksa (lihat `screen_inventory.md`). Karena itu, analisis kebutuhan fungsional bersandar pada teks BRD dan brief; rincian visual tidak dianggap telah tervalidasi.

**Pemisahan sumber:** butir bertanda **BRD** merangkum isi tertulis BRD. Butir bertanda **Usulan teknis** adalah rancangan awal untuk ditinjau, bukan keputusan BRD. Tidak ada klaim bahwa integrasi pihak ketiga sudah berjalan.

## 2. Konteks produk dan ruang lingkup BRD

BRD mendefinisikan sistem untuk warga Kota Padang dengan tiga permukaan: Android Flutter untuk warga (fitur lengkap), web warga untuk informasi/partisipasi, dan dashboard web petugas/admin simulasi. Semuanya memakai satu server. iOS dan wilayah di luar Padang tidak termasuk.

Tujuan yang dinyatakan: memudahkan warga menemukan status siaga, titik bahaya, dan posko; menyediakan SOS dan koordinasi keluarga; menyediakan saluran laporan yang diverifikasi; memberi petugas alat simulasi untuk mengelola data. BRD tidak mengklaim bahwa aplikasi mengurangi korban jiwa atau menggantikan layanan darurat. Petugas adalah peran simulasi; belum ada kerja sama resmi BPBD.

### In scope (BRD)

- Android: akun/onboarding, beranda, peta/evakuasi, cuaca, tinggi sungai, notifikasi, SOS, keluarga/chat, laporan, edukasi, tas siaga, riwayat bencana, kontak, profil, pengaturan.
- Web warga: informasi, partisipasi/pelaporan, dan peringatan; tanpa SOS, keluarga, chat, atau status keluarga.
- Dashboard petugas satu peran: SOS, verifikasi laporan, titik bahaya, posko, rute, status siaga, tinggi sungai, peringatan, konten.
- Wilayah layanan: Kota Padang. Antarmuka Bahasa Indonesia.
- Data titik bahaya, posko, jalur, tinggi sungai, dan peringatan: dummy simulasi yang diinput petugas.
- Prakiraan cuaca BMKG termasuk kebutuhan Should dan integrasi yang direncanakan, tetapi tetap bergantung pada akses/ketentuan aktual.

### Out of scope (BRD)

iOS; fitur SOS/keluarga di web; OTP nomor telepon; login Apple; SMS (termasuk undangan SMS); pelacakan lokasi kontinu; sensor/IoT sungai; prediksi banjir AI; offline penuh; peran petugas terpisah; integrasi darurat nasional 110/112/119; integrasi data resmi BPBD/infobencana.padang.go.id; bahasa selain Indonesia; wilayah selain Padang.

## 3. Aktor dan akses

| Aktor | Kebutuhan/akses menurut BRD | Batasan |
|---|---|---|
| Warga | Akun/profil, informasi, peta, laporan; SOS dan keluarga di Android | Hanya pemilik mengubah profil; web tidak memiliki SOS/keluarga |
| Anggota keluarga | Status Aman/Waspada/Darurat/Butuh Bantuan, chat | Data hanya anggota kelompok keluarga yang sama |
| Petugas/admin simulasi | Memproses SOS/laporan dan mengelola data simulasi | Satu peran; warga tidak boleh mengakses fungsi petugas |
| BPBD Padang | Sumber data potensial | Belum ada kerja sama/API/izin terkonfirmasi; bukan aktor sistem operasional |
| BMKG | Sumber prakiraan cuaca | Sumber harus dicantumkan; endpoint, format, batas aktual harus diverifikasi |

## 4. Kebutuhan fungsional BRD

Prioritas dipertahankan dari BRD: Must, Should, Could. Penanda platform: A=Android warga, W=web warga, P=dashboard petugas, S=server/integrasi.

| ID BRD/FR | Kebutuhan dan kriteria ringkas BRD | Prioritas/platform |
|---|---|---|
| BR-001 / FR-005 | Status Aman, Waspada, Siaga, Awas; beranda menampilkan keterangan dan waktu pembaruan. Awas berarti segera evakuasi. Label dan warna sesuai tingkat. | Must A/W |
| BR-002 / FR-006, FR-028 | Peta memuat titik bahaya berlevel, posko, dan laporan terverifikasi. Titik yang dikelola petugas tampil ke warga; level memiliki label selain warna. | Must A/W/P |
| BR-003 / FR-009–010 | Peringatan/status berubah memicu notifikasi ke pengguna aktif Android atau pengguna web yang memberi izin; daftar notifikasi terbaru membuka tujuan terkait. | Must A/W/S; delivery layanan belum dipilih |
| BR-004 / FR-013–015 | Warga memilih Terjebak/Terluka/Butuh Evakuasi; menahan SOS penuh 3 detik; melepas lebih awal membatalkan. Opsi berbagi keluarga mengubah penerima. Lokasi dan waktu dicatat. Gagal kirim harus jelas dan tidak tampak sukses; sediakan tombol telepon kontak darurat. | Must A |
| BR-005 / FR-026 | Petugas melihat SOS berurutan waktu dengan jenis, lokasi, waktu, kontak; mengonfirmasi Menunggu konfirmasi menjadi Terkonfirmasi lalu Ditangani/Selesai. Warga melihat status. | Must P/A |
| FR-014 | Warga dapat membatalkan SOS aktif; dashboard menampilkan status batal. Aturan status mana yang masih bisa dibatalkan perlu ditentukan. | Must A/P |
| BR-006 / FR-016 | Kontak BPBD, Damkar, PMI, posko; tindakan membuka dialer dengan nomor yang tersimpan. Kontak adalah cadangan jika SOS gagal. | Must A/W |
| BR-007 / FR-001–004 | Registrasi email/kata sandi dan persetujuan privasi; login warga via email atau Google di BRD; petugas via email; profil nama, nomor HP, lokasi rumah; nomor HP bukan kredensial login; izin lokasi/notifikasi dapat ditunda. | Must A/W/P |
| BR-008 / FR-028–031 | Petugas mengelola titik bahaya, posko, jalur, status, tinggi sungai, peringatan dan konten; perubahan tampil ke warga setelah disimpan. | Must/Should P |
| BR-009 / FR-034 | Lokasi hanya saat SOS/laporan; data sesuai peran; anggota keluarga hanya melihat data kelompoknya. | Must A/W/P/S |
| BR-010 / FR-008, FR-032 | Prakiraan cuaca per lokasi rumah/kelurahan dan atribusi BMKG; saat gagal tampilkan error dan data tersimpan terakhir. | Should A/W/S |
| BR-011 / FR-007, FR-030 | Tinggi sungai dalam cm, level/tren per titik pantau, waktu pembaruan; data manual petugas. | Should A/W/P |
| BR-012 / FR-011–012, FR-029 | Posko/pengungsian terdekat diurutkan berdasarkan jarak; kondisi jalan terbuka/tertutup dan rute ke pengungsian; hindari jalan tertutup jika data tersedia. Lokasi rumah menjadi fallback bila lokasi perangkat tidak ada. | Should A/W/P |
| BR-013 / FR-017–019 | Bergabung lewat kode atau nomor HP anggota; kode salah/kedaluwarsa ditolak; kode undangan unik berlaku 24 jam dan bisa disalin/dibagikan via WhatsApp; status anggota dan waktu terlihat. | Should A |
| BR-014 / FR-021–022, FR-027 | Laporan lokasi/jenis wajib, deskripsi, foto opsional berbatas ukuran; warga melihat Diproses/Selesai/Ditolak; petugas setuju/tolak; hanya disetujui tampil di peta. | Should A/W/P |
| BR-015 / FR-020 | Chat keluarga; pesan hanya dapat dilihat anggota keluarga sama. | Could A |
| BR-016 / FR-023–025, FR-031 | Artikel langkah evakuasi, tas siaga, level status; checklist tersimpan; riwayat kejadian urut terbaru. Konten dikelola petugas. | Could A/W/P |
| FR-002 | Login Google dicantumkan untuk warga; autentikasi Google membutuhkan konfigurasi dan validasi pihak ketiga. Tidak disamakan dengan login Apple/OTP yang out of scope. | Must A/W; keputusan teknis/izin perlu dikonfirmasi |
| FR-033 | Impor data BPBD ditandai tidak dikerjakan pada proyek ini; pakai data dummy yang diinput petugas. | Could S, eksplisit tidak dikerjakan |

## 5. Kebutuhan nonfungsional

BRD menegaskan angka kinerja berikut adalah **Usulan**, perlu disepakati/diuji, bukan target terkonfirmasi.

| ID | Isi BRD | Status di BRD |
|---|---|---|
| NFR-001 | Kata sandi ter-hash, HTTPS, API dibatasi menurut peran | Usulan |
| NFR-002 | Lokasi hanya dikirim saat SOS/lapor; tanpa pelacakan; persetujuan privasi saat daftar | Terkonfirmasi sebagai keputusan penyusun |
| NFR-003 | Minimasi data (nama, email, nomor HP, alamat rumah, lokasi saat tindakan) | Usulan |
| NFR-004 | Beranda tampil ≤3 detik pada 4G normal | Usulan |
| NFR-005 | SOS tampak di dashboard ≤10 detik pada jaringan normal | Usulan |
| NFR-006 | SOS dapat dijangkau dari semua layar utama; tahan 3 detik untuk mencegah salah kirim | Terkonfirmasi pada desain/keputusan BRD |
| NFR-007 | Tingkat siaga tidak hanya dibedakan warna; label teks dan kontras memadai | Usulan |
| NFR-008 | Versi minimum Android belum ditentukan; Chrome/Edge terbaru dan web responsif | Perlu keputusan |
| NFR-009 | Saat internet/API BMKG gagal ada pesan dan data terakhir; SOS gagal tidak boleh diklaim berhasil | Usulan |
| NFR-010 | Petugas mengubah data tanpa bantuan developer | Terkonfirmasi |
| NFR-011 | Skala demo/uji; target pengguna serentak belum ditetapkan | Belum dikonfirmasi |
| NFR-012 | Semua antarmuka Indonesia | Terkonfirmasi |

## 6. Aturan/domain kritis

1. **Autentikasi.** BRD: warga daftar email+kata sandi dan menyetujui privasi; login email atau Google untuk warga; petugas login email; nomor HP bukan login; akun admin dibuat tim pengembang (A-06 adalah usulan). OTP dan Apple login di luar cakupan. Perlu menegaskan apakah Google Sign-In wajib, opsional, atau ditiadakan bila kredensial/konfigurasi tidak tersedia.
2. **Otorisasi petugas.** Satu peran petugas/admin simulasi. Semua CRUD, konfirmasi SOS, verifikasi laporan, dan rilis peringatan dibatasi ke peran tersebut; API warga tidak boleh mengakses fungsi petugas. Penegakan server-side adalah usulan teknis wajib, bukan sekadar menyembunyikan tombol.
3. **SOS.** Jenis wajib dipilih; durasi tekan kontinu penuh 3 detik; lepas sebelum selesai membatalkan tanpa request. Setelah terkirim, simpan waktu, jenis, lokasi saat aksi, dan pilihan berbagi keluarga. Status awal Menunggu konfirmasi, tampil di dashboard dan warga sebagai “Menunggu konfirmasi petugas”. Setelah petugas konfirmasi menjadi Terkonfirmasi, lalu Ditangani/Selesai. Kegagalan jaringan jangan pernah ditampilkan sebagai sukses.
4. **Pembatalan SOS.** BRD menyebut warga dapat membatalkan SOS aktif dan daftar petugas menampilkan status dibatalkan, tetapi tidak menyebut batas status/tenggat atau alasan. Perlu keputusan. Catat histori transisi untuk audit (usulan teknis).
5. **Laporan.** Lokasi dan jenis wajib; foto opsional; laporan belum terverifikasi tidak muncul pada peta publik/web warga; petugas menyetujui atau menolak dan status terlihat oleh pengirim.
6. **Lokasi/privasi.** Tidak ada tracking kontinu. Lokasi hanya diambil pada tindakan SOS/laporan dengan izin; profil juga memuat lokasi rumah menurut BRD. Hanya petugas dan pemilik dapat melihat lokasi SOS/laporan sesuai aturan; penerima keluarga hanya jika pengirim memilih berbagi SOS. Mekanisme retensi/hapus akun belum ditentukan.
7. **Keluarga.** Kode 24 jam; kode salah/kedaluwarsa ditolak; akses status/chat hanya anggota keluarga yang sama. Undangan lewat nomor HP disebut sebagai cara bergabung, sementara pengiriman SMS dilarang; alur pencarian/invitasi nomor HP belum jelas.
8. **Data simulasi.** Titik bahaya, posko, rute, jalan, status siaga, tinggi sungai, dan peringatan dimasukkan manual petugas dan diberi label simulasi. Tampilkan waktu pembaruan dan status kedaluwarsa bila memungkinkan (label kedaluwarsa adalah mitigasi usulan BRD). Data ambang sungai Padang belum diketahui; angka Katulampa di Lampiran C hanya contoh dan tidak boleh dipakai untuk Padang.
9. **Cuaca.** BRD menyebut BMKG, atribusi wajib, prakiraan 3 hari dan pemetaan kode wilayah kelurahan; batas 60 request/menit/IP dicatat BRD sebagai hasil verifikasi penyusun dan tetap perlu cek aktual saat implementasi. Jangan mengklaim live integration sebelum endpoint/format/izin/akses diuji. Gagal API: pesan jelas dan cache terakhir jika ada; data demo diberi label.
10. **Notifikasi dan peta.** BRD memutuskan peringatan web juga ada (D-10) dan menarget pengguna aktif Android/web dengan izin, tidak dibatasi wilayah (D-13). Layanan push dan web belum dipilih (Q-07/Q-08), asumsi gratis (A-07) perlu validasi. Peta pihak ketiga dan kuota/biayanya belum dipilih.
11. **Kontak darurat.** Tombol hanya membuka dialer ke nomor yang disimpan; nomor harus divalidasi. Tidak ada SMS otomatis, panggilan otomatis, atau integrasi 110/112/119.

## 7. Matriks keterkaitan BRD → platform → data/API

**Tabel/endpoints di bawah adalah Usulan teknis**, bukan skema atau kontrak API yang tertulis pada BRD. Nama endpoint mengasumsikan prefiks `/api/v1`; detail auth, pagination, status code, filter, serta payload ditetapkan pada desain API.

| Kebutuhan BRD | Layar Android | Web warga | Dashboard petugas | Tabel yang diusulkan | Endpoint API yang diusulkan |
|---|---|---|---|---|---|
| BR-001 status siaga | Beranda, Status Siaga | Beranda/status | Ringkasan; kelola status | `alert_levels`, `flood_alerts` | `GET /alerts/current`, `GET /alerts`, `POST /staff/alerts`, `PATCH /staff/alerts/{id}` |
| BR-002 titik bahaya/posko; BR-012 rute | Beranda peta mini, Evakuasi | Peta/info evakuasi | CRUD titik/posko/rute | `danger_points`, `evacuation_posts`, `evacuation_routes`, `road_segments` | `GET /map/features`, `GET /evacuation/posts`, `GET /evacuation/routes`; staff CRUD di `/staff/danger-points`, `/staff/evacuation-posts`, `/staff/routes` |
| BR-003 peringatan/notifikasi | Daftar/detail notifikasi, Home | Notifikasi web, Home | Rilis peringatan | `alerts`, `notifications`, `notification_preferences`, `device_tokens` (jika push dipilih) | `GET /notifications`, `PATCH /notifications/{id}/read`, `POST /staff/announcements`, `POST /staff/announcements/{id}/publish` |
| BR-004/005 SOS | Kirim SOS, SOS terkirim, riwayat | Tidak tersedia | Daftar/detail SOS, tindak lanjut | `emergencies`, `emergency_status_histories`, `audit_logs` | `POST /emergencies`, `GET /emergencies/{id}`, `GET /emergencies`, `POST /emergencies/{id}/cancel`, `POST /staff/emergencies/{id}/confirm`, `PATCH /staff/emergencies/{id}/status` |
| BR-006 kontak | Kontak | Kontak | CRUD kontak | `emergency_contacts` | `GET /emergency-contacts`, `POST/PATCH/DELETE /staff/emergency-contacts/{id}` |
| BR-007/FR-001–004 akun | Welcome, Login, Sign up, Profil, Pengaturan | Login/register, Profil | Login petugas | `users`, `citizen_profiles`, `staff_profiles` atau role field | `POST /auth/register`, `POST /auth/login`, `POST /auth/logout`, `GET/PATCH /me`; Google token exchange hanya jika diputuskan |
| BR-008, FR-028–031 CRUD data | Pembaca peta, siaga, sungai, konten | Pembaca peta/edukasi | CRUD seluruh data bencana/konten | Tabel lokasi, status, konten; `audit_logs` | `/staff/danger-points`, `/staff/posts`, `/staff/routes`, `/staff/river-readings`, `/staff/alerts`, `/staff/contents` CRUD |
| BR-009 privasi | izin lokasi, SOS/laporan, keluarga | lokasi laporan opsional | Data sesuai kewenangan | `users`, `emergencies`, `citizen_reports`, `family_members` | API terbatas per pemilik/anggota/peran; lokasi dikirim hanya di `POST /emergencies` dan `POST /reports` |
| BR-010 cuaca | Cuaca | Cuaca | Status integrasi/monitoring opsional | `weather_cache` (usulan; cache mungkin tidak persisten) | `GET /weather?area_code=...` melalui adapter server BMKG; tidak ada endpoint BMKG dianggap tersedia sebelum diverifikasi |
| BR-011 sungai | Ketinggian sungai | Ketinggian sungai | Input bacaan | `river_stations`, `river_readings` | `GET /river-readings`, staff `POST /staff/river-readings` |
| BR-013/015 keluarga | Status Keluarga, Gabung, Tambah Anggota kode/HP, Chat | Tidak tersedia | Tidak tersedia | `family_groups`, `family_members`, `family_invitations`, `family_messages` | `POST /families`, `POST /families/join`, `POST /families/invitations`, `GET /families/{id}`, `PATCH /families/{id}/status`, `GET/POST /families/{id}/messages` |
| BR-014 laporan | Lapor warga, Riwayat laporan (diusulkan; layar tidak jelas pada PDF) | Form/riwayat laporan | Antrian verifikasi | `citizen_reports`, `report_photos`, `report_status_histories` | `POST /reports`, `GET /reports/mine`, `GET /staff/reports`, `POST /staff/reports/{id}/verify`, `POST /staff/reports/{id}/reject` |
| BR-016 edukasi/checklist/riwayat | Edukasi, detail, tas siaga, riwayat bencana | Edukasi, riwayat | CRUD konten | `educational_contents`, `go_bag_items`, `checklist_progress`, `disaster_histories` | `GET /contents`, `GET /contents/{slug}`, `GET/PATCH /checklist`, `GET /disaster-histories`; CRUD petugas di `/staff/contents` |

### Catatan model data teknis

- **Usulan teknis:** gunakan user dengan role warga/petugas yang jelas, profil warga terpisah untuk data pribadi, FK/indeks koordinat untuk data geospasial, enum/status dengan histori, audit petugas, dan paginasi/filter daftar SOS/laporan.
- Simpan foto laporan pada storage dengan validasi tipe/ukuran; simpan path/metadata di `report_photos`.
- Jangan simpan token rahasia/API key pada kode. Tidak memutuskan driver peta, push, auth Google, atau API BMKG dalam analisis ini.
- Model tabel di matriks adalah daftar konseptual untuk diskusi. Finalisasi hanya setelah review BRD, pilihan backend/auth, retention, dan alur layar.

## 8. Konflik/ketidakjelasan yang benar-benar ditemukan

1. **Akun warga Google vs email/kata sandi:** FR-001 menyatakan daftar email+katasandi; FR-002 memasukkan Google untuk warga; A-06 membahas akun admin. Brief percakapan meminta metode sesuai BRD namun melarang hanya OTP/Apple. Perlu putuskan apakah Google Sign-In benar-benar harus diimplementasikan.
2. **Gabung keluarga lewat nomor HP vs tanpa SMS:** FR-017 menyebut kode atau nomor HP; FR-018 membagikan kode via WhatsApp/salin; SMS dilarang. Tidak jelas bagaimana pencarian/undangan nomor HP dilakukan dan persetujuan penerima dikelola.
3. **Batal SOS setelah dikirim:** BRD awal tidak mendefinisikan status yang boleh dibatalkan, batas waktu, alasan, atau konsekuensi setelah petugas mulai menangani. Keputusan pengguna 23 Oktober 2026 menyelesaikan status yang boleh dibatalkan (Menunggu konfirmasi, Terkonfirmasi, Ditangani); alasan pembatalan masih menjadi usulan teknis.
4. **Chat Could tapi UI ada:** BRD memprioritaskan chat sebagai Could; desain bernama ChatKeluarga ada, namun visualnya belum dapat diperiksa. Keputusan pengguna: tetap direncanakan tetapi prioritas rendah, dikerjakan jika waktu memungkinkan.
5. **Dashboard petugas belum punya desain terkonfirmasi:** BRD menyatakan desain petugas perlu dikonfirmasi/dibuat. Brief meminta dashboard profesional responsif; belum ada PDF dashboard teridentifikasi di folder referensi.
6. **Peta/rute:** kebutuhan rute/kondisi jalan ada, tetapi penyedia peta, perhitungan rute, data jalan, kuota, dan biaya belum diputuskan. “Menghindari jalan tertutup” hanya jika data rute tersedia.
7. **Notifikasi web/push:** peringatan web diputuskan, namun layanan web belum dipilih; push Android juga bergantung konfigurasi/layanan. Perilaku pengguna yang membuka web dan izin browser perlu spesifikasi teknis.
8. **Kriteria level/ambang sungai Padang:** level Aman/Waspada/Siaga/Awas ditetapkan; indikator detil pada Lampiran C generik dan contoh TMA Katulampa secara eksplisit tidak berlaku untuk Padang. Nilai dummy per stasiun harus ditentukan tim; jangan mengadopsi angka Katulampa.
9. **Lokasi rumah dan izin lokasi:** FR-003 memuat lokasi rumah; FR-004 mengizinkan menunda izin lokasi; FR-011 memakai lokasi rumah sebagai fallback. Belum jelas bagaimana lokasi rumah diisi bila izin ditolak dan apakah alamat rumah berupa teks, koordinat, atau kelurahan.
10. **Retensi dan penghapusan:** masa penyimpanan lokasi, SOS, foto, chat, serta prosedur hapus akun/data belum ditetapkan (BRD Q-09).
11. **Cakupan/dokumen akademik:** BRD mencatat tim 2 orang, sekitar 3 minggu dan daftar fitur Must/Should/Could yang besar; dokumen DRD dari dosen belum didefinisikan. Perlu pilih prioritas realistis dan konfirmasi artefak wajib.

## 9. Pertanyaan terbuka dari BRD

| ID BRD | Pertanyaan | Efek |
|---|---|---|
| Q-01 | Apakah BPBD/infobencana menyediakan API/berkas resmi dan izin? | Tidak memblokir simulasi karena D-11 menetapkan dummy; menentukan integrasi lanjutan |
| Q-02 | Apa kepanjangan/isi DRD yang diminta dosen? | Dokumen akademik |
| Q-03 | Bagaimana alur laporan warga yang tepat? | Detail laporan/status dan web |
| Q-04 | Apakah login Google harus dipakai dan konfigurasi tersedia? | Auth warga |
| Q-05 | Layanan peta apa yang dipilih dan apakah kuota/biayanya sesuai? | Peta/rute |
| Q-06 | Minimum Android dan browser target? | Kompatibilitas |
| Q-07 | Layanan notifikasi push dan peta pihak ketiga apa yang digunakan? | Biaya, izin, jadwal |
| Q-08 | Layanan notifikasi web apa yang dipakai? | Notifikasi web |
| Q-09 | Kebijakan penyimpanan dan penghapusan data? | Privasi dan retensi |
| Q-10 | Siapa pemilik akun admin dan bagaimana akun dibuat? | Operasi/akses petugas |
| Q-11 | Berapa batas TMA tiap titik pantau Padang? | Data simulasi/kalibrasi level |

## 10. Usulan keputusan teknis untuk persetujuan (bukan fakta BRD)

- Definisikan kontrak API versi `/api/v1`, serialisasi waktu UTC dengan tampilan lokal, paginasi/filter untuk SOS/laporan, error envelope konsisten, dan validasi server.
- Gunakan transaksi untuk SOS + status awal + histori; gunakan histori perubahan status dan identitas petugas untuk SOS/laporan.
- Pilih Sanctum hanya setelah versi Laravel dan kebutuhan klien dikonfirmasi; sesi web terpisah dari token aplikasi; policies/middleware server-side untuk semua route petugas.
- Representasikan status/alur sebagai state machine dengan transisi yang diizinkan. Daftar transisi (khusus pembatalan) harus disetujui sebelum implementasi.
- Semua data simulasi diberi `is_simulated` atau provenance yang setara serta `updated_at`; UI menyebut “Data simulasi” dan menampilkan waktu.
- Adapter cuaca backend terpisah dengan timeout, cache, atribusi, dan fallback eksplisit; implementasi integrasi hanya setelah endpoint dan akses diuji.
- Jangan implementasikan push, web push, Google Sign-In, atau SDK peta sebelum pilihan layanan/credential/kebijakan disepakati. Sediakan status tidak tersedia/demo sementara.

## 11. Status analisis dan gerbang berikutnya

Analisis kebutuhan dari teks BRD selesai untuk kebutuhan, alur, aturan, risiko, dan pertanyaan. Pemeriksaan visual desain belum lengkap; inventaris pada dokumen pendamping secara eksplisit menandai elemen yang tak dapat diverifikasi. Pada saat analisis awal belum ada kode, migration, database, konfigurasi Laragon, atau layanan Windows yang dibuat/diubah. Keputusan dan implementasi fondasi setelahnya dicatat terpisah pada bagian 12 dan README backend. Pertanyaan yang sudah dijawab pada bagian 12 tidak diminta ulang.

## 12. Pembaruan keputusan pengguna (23 Oktober 2026)

Bagian ini mencatat keputusan yang diberikan pengguna setelah analisis awal. Jika bertentangan dengan usulan/pertanyaan di atas, keputusan di sini yang berlaku. Label: **BRD** = teks kebutuhan asal; **Keputusan pengguna** = arahan baru yang telah disetujui; **Usulan teknis** = rancangan belum disetujui.

### Keputusan disetujui

| Topik | Keputusan pengguna | Kaitannya dengan BRD |
|---|---|---|
| Login warga | Email dan kata sandi. Google Sign-In boleh ditambahkan bila konfigurasi memungkinkan. | Mengunci FR-001/002 menjadi email/password sebagai jalur awal; Google opsional, bukan prasyarat. OTP/Apple tetap di luar cakupan. |
| Permintaan keluarga via HP | Pencarian/permintaan melalui nomor HP memerlukan persetujuan penerima sebelum keanggotaan terbentuk. | Memperjelas BRD FR-017; nomor HP tidak boleh menambahkan anggota secara otomatis. SMS tetap tidak digunakan. |
| Pembatalan SOS | Warga boleh membatalkan ketika Menunggu konfirmasi, Terkonfirmasi, atau Ditangani. Saat Ditangani status menjadi Dibatalkan. Semua perubahan, waktu, dan pelaku tercatat dan dapat dilihat petugas. | Memperjelas FR-014 dan melengkapi area yang sebelumnya terbuka. Tidak menghapus record. |
| Chat keluarga | Tetap direncanakan, prioritas rendah, implementasi jika waktu memungkinkan. | Sesuai Could pada BR-015; bukan fondasi awal. |
| Peta/notifikasi awal | Peta sederhana; notifikasi dalam aplikasi. Jangan menyatakan push tersedia sebelum integrasi dibuat dan diuji. | Memilih cakupan awal tanpa mengklaim layanan peta/push eksternal. |
| Retensi data | Minta usulan kebijakan aman sebelum penerapan. | Q-09 masih terbuka; tidak ada periode retensi yang disetujui. |
| Akun petugas | Dibuat manual oleh pengembang; tidak ada registrasi petugas publik. | Memperjelas A-06 (sebelumnya usulan BRD) menjadi keputusan pengguna. |
| Data simulasi | Tinggi muka air dan ambang demo diberi label `DEMO` atau `DATA SIMULASI`; angka Katulampa tidak dipakai sebagai ambang resmi Padang. | Mempertegas A-02/D-11 dan Lampiran C. |

### Aturan transisi SOS

**Keputusan pengguna:** tekan harus berlangsung penuh 3 detik; lepas sebelum selesai membatalkan pengiriman. SOS baru berstatus `Menunggu konfirmasi petugas`. Riwayat status tidak pernah dihapus. Warga dapat membatalkan di tiga status aktif yang disebut di bawah.

**Usulan teknis untuk ditinjau:** status terminal `Selesai` dan `Dibatalkan` tidak dapat diubah lewat alur normal. Transisi:

| Status asal | Aksi/aktor | Status tujuan | Sumber/jenis keputusan |
|---|---|---|---|
| Belum terkirim | Lepas sebelum 3 detik / warga | Tidak ada record SOS terkirim; UI menyatakan dibatalkan sebelum pengiriman | Keputusan pengguna |
| Belum ada | Kirim setelah tahan 3 detik / warga | Menunggu konfirmasi petugas | BRD + keputusan pengguna |
| Menunggu konfirmasi petugas | Konfirmasi / petugas | Terkonfirmasi | BRD |
| Menunggu konfirmasi petugas | Batalkan / warga | Dibatalkan | Keputusan pengguna |
| Terkonfirmasi | Mulai penanganan / petugas | Ditangani | BRD |
| Terkonfirmasi | Batalkan / warga | Dibatalkan | Keputusan pengguna |
| Ditangani | Batalkan / warga | Dibatalkan | Keputusan pengguna; tetap simpan histori dan tampilkan petugas |
| Ditangani | Selesaikan / petugas | Selesai | BRD |
| Dibatalkan atau Selesai | Aksi status normal | Tidak ada transisi | Usulan teknis; perlu persetujuan |

Setiap transisi tersimpan atomik bersama waktu kejadian, status asal/tujuan, aktor (warga/petugas/sistem), dan aksi; tidak menghapus SOS. **Usulan teknis:** simpan alasan opsional untuk pembatalan dan tampilkan catatan aktor/waktu pada tampilan riwayat petugas. Status `Dibatalkan` harus menonjol di dashboard, termasuk bila pembatalan terjadi setelah status Ditangani.

### Permintaan bergabung keluarga melalui nomor HP

**Keputusan pengguna:** hasil pencarian nomor HP membuat permintaan tertunda; penerima menyetujui atau menolak; baru setelah persetujuan anggota ditambahkan ke grup. Ini bukan SMS/OTP. **Usulan teknis:** catat status permintaan `Menunggu`, `Disetujui`, `Ditolak`, `Dibatalkan`, pemohon, penerima, grup tujuan, waktu dibuat/keputusan, dan cegah pemohon membaca data grup sebelum disetujui. Keamanan respons untuk nomor yang tidak terdaftar dan batas jumlah pencarian perlu dirancang agar nomor tidak dapat dienumerasi.

Pembaruan matriks tabel/API konseptual:

| Kebutuhan | Tabel yang diusulkan | Endpoint yang diusulkan |
|---|---|---|
| Permintaan keanggotaan via HP | `family_join_requests` (pemohon, penerima, grup, status, timestamps); audit perubahan | `POST /families/join-requests` (buat), `GET /families/join-requests/received`, `POST /families/join-requests/{id}/approve`, `POST /families/join-requests/{id}/reject`; akses dibatasi pemohon/penerima/petugas berwenang |
| Pembatalan & histori SOS | `emergencies`, `emergency_status_histories`, `audit_logs` | `POST /emergencies/{id}/cancel` untuk pemilik; status/histori petugas pada `GET /staff/emergencies/{id}`; transisi divalidasi server-side |

### Notifikasi, peta, integrasi

**Keputusan pengguna:** implementasi awal hanya notifikasi dalam aplikasi dan peta sederhana. Push notification tidak tersedia sampai layanan dipilih, dibangun, dan diuji. Peta sederhana tidak menentukan vendor, SDK, tiles, geocoding, atau engine rute. Semua tetap pertanyaan teknis terbuka dan harus dibedakan dari kebutuhan inti. Cuaca BMKG tetap membutuhkan verifikasi endpoint, format, ketentuan, serta atribusi; data resmi BPBD tidak tersedia/di luar cakupan sampai akses dan izin ada.

### Usulan retensi dan penghapusan — belum disetujui

Berikut **Usulan teknis** untuk diskusi, bukan kebijakan aktif:

| Jenis data | Usulan masa simpan | Perlakuan saat masa berakhir/penghapusan akun |
|---|---|---|
| Akun/profil | Selama akun aktif | Penghapusan akun memulai penghapusan/anonymization data profil dan token setelah masa tenggang operasional singkat yang disepakati; jangan menghapus histori yang perlu dipertahankan tanpa dasar dan proses yang disetujui |
| Koordinat SOS/laporan | Maksimal 90 hari setelah kasus ditutup | Hapus koordinat presisi atau generalisasi/anonymize; pertahankan statistik tanpa identitas jika disetujui |
| Foto laporan | Maksimal 90 hari setelah keputusan verifikasi | Hapus file dari storage beserta metadata, kecuali pengguna menyetujui kebutuhan dokumentasi lebih lama |
| Record SOS/laporan dan histori status | 12 bulan setelah ditutup untuk simulasi/audit akademik | Hapus atau anonimisasi identitas; tetapkan pengecualian yang dapat dipertanggungjawabkan sebelum produksi |
| Pesan keluarga | 90 hari sejak dikirim atau sampai grup dihapus (mana yang lebih cepat) | Hapus pesan dan media (bila kelak ada); ekspor tidak diasumsikan |
| Log audit petugas | 12 bulan | Kurangi/anonimkan identitas bila tidak dibutuhkan untuk audit setelah periode |
| Token akses dan data sementara/cache cuaca | Token dicabut saat logout/hapus akun; cache cuaca maksimum 1 jam (nilai awal) | Hapus saat dicabut/kedaluwarsa; kebijakan cache mengikuti ketentuan sumber |

Periode di atas hanya titik awal: pengguna perlu menyetujui atau mengubahnya sebelum implementasi retensi otomatis. Produksi memerlukan peninjauan dasar hukum, tujuan, kebutuhan akademik, dan prosedur permintaan hapus. Jangan membuat job penghapusan sebelum kebijakan final disetujui.

## 13. Pertanyaan tersisa setelah keputusan baru

- **Q-05/07 (dipersempit):** peta sederhana dimulai; engine/vendor/tiles dan biaya belum dipilih. Peringatan awal hanya in-app; apakah web warga juga perlu daftar notifikasi in-app (tanpa push)?
- **Q-09 (tetap terbuka):** apakah pengguna menyetujui usulan retensi bertingkat di atas, khususnya 90 hari untuk lokasi/foto, 12 bulan untuk rekam kasus/audit, dan 90 hari untuk chat?
- **Q-11:** ambang TMA demo untuk tiap titik pantau belum ditetapkan; siapa yang memberi angka dummy dan satuan/levelnya?
- **Q-03:** flow detail laporan tetap perlu dipastikan (kategori, status akhir, alasan penolakan, edit/hapus laporan).
- **Q-06:** versi minimum Android dan browser belum diputuskan.
- **Q-10:** pembuatan manual diputuskan; cara provisioning aman, rotasi password, dan pemulihan akun petugas belum ditentukan.
- **Keluarga via HP:** apakah permintaan penerima harus memilih grup secara eksplisit bila lebih dari satu grup? Berapa lama permintaan menunggu sebelum kedaluwarsa?
- **Pembatalan SOS:** apakah alasan pembatalan wajib atau opsional? Apakah petugas menerima notifikasi in-app saat SOS aktif dibatalkan?
- **Aset desain:** inspeksi visual PDF tetap belum berhasil; ekspor PNG/JPG diperlukan untuk validasi layout sebelum implementasi UI.

Q-04 (Google wajib) kini dijawab: email/password adalah jalur wajib awal, Google opsional bila konfigurasi memungkinkan. Q-08 (web push) tidak relevan untuk tahap awal yang hanya memakai notifikasi dalam aplikasi; push tetap di luar klaim sampai dibangun/diuji. Q-10 (registrasi publik petugas) dijawab: tidak ada; akun dibuat manual pengembang.

## 14. Audit kebutuhan dan implementasi aktual (23 Oktober 2026)

Bagian ini memperbarui status implementasi setelah fondasi Laravel dan skema dasar selesai. Bagian kebutuhan pada §2–9 tetap merupakan ringkasan isi BRD versi 0.1 (draft, belum ditinjau/disetujui). Jika status lama pada catatan historis §11–13 berbeda, snapshot implementasi di bawah ini adalah pemeriksaan terbaru. Keputusan pengguna pada §12 tetap berlaku dan tidak diminta ulang.

### 14.1 Ringkasan kebutuhan BRD

BRD meminta tiga permukaan untuk wilayah Kota Padang dan antarmuka Bahasa Indonesia: aplikasi Android Flutter untuk warga, web warga untuk informasi/partisipasi, dan dashboard web petugas/admin simulasi yang menggunakan server yang sama.

- **Must:** akun dan profil warga/petugas; informasi tingkat siaga; peta titik bahaya dan posko; notifikasi peringatan; alur SOS dengan tahan 3 detik, lokasi saat tindakan, status penanganan, dan kontak darurat; pengelolaan serta konfirmasi SOS oleh petugas; laporan warga yang diverifikasi; pengelolaan data simulasi oleh petugas; pembatasan akses dan privasi lokasi.
- **Should:** prakiraan cuaca BMKG dengan atribusi dan fallback; tinggi muka air yang diinput manual; posko/rute evakuasi; alur keluarga dan undangan; pelaporan lintas platform.
- **Could:** chat keluarga; edukasi, checklist tas siaga, dan riwayat bencana.
- **Batas BRD:** iOS, OTP, login Apple, SMS, pelacakan lokasi kontinu, IoT, prediksi AI, integrasi darurat 110/112/119, integrasi resmi BPBD, dan wilayah di luar Padang berada di luar cakupan. Data bahaya/sungai/posko untuk simulasi perlu diberi label yang jujur.

Rincian requirement dan prioritas per ID tetap berada di tabel §4–5; batasan serta aturan domain lebih lengkap berada di §6–9.

### 14.2 Berkas desain yang ditemukan

Folder `E:\Flutter project\docs\reference\` memuat 25 berkas desain mobile berikut. Nama berkas digunakan sebagai identifikasi layar, bukan bukti tampilan atau perilaku visual:

`Mobile-Welcome.pdf`; `Mobile-login.pdf`; `Mobile-Sign up.pdf`; `Mobile-Home.pdf`; `Mobile-StatusSiaga.pdf`; `Mobile-Kirim SOS.pdf`; `Mobile- SOS terkirim.pdf`; `Mobile-Evakuasi.pdf`; `Mobile-Cuaca.pdf`; `Mobile-Ketinggian sungai.pdf`; `Mobile-Lapor warga.pdf`; `Mobile-Gabung keluarga dgn kode.pdf`; `Mobile-Tambah Anggota dgn kode.pdf`; `Mobile-Tambah Anggota dgn no hp.pdf`; `Mobile-status Keluarga.pdf`; `Mobile-ChatKeluarga.pdf`; `Mobile-Edukasi.pdf`; `Mobile-isi tas siaga.pdf`; `Mobile-Riwayat bencana.pdf`; `Mobile-Kontak.pdf`; `Mobile-Profil.pdf`; `Mobile-Pengaturan.pdf`; `Mobile-Notifikasi.pdf`; `Mobile-Menu.pdf`; `Mobile-Logo.pdf`.

**Keterbatasan terverifikasi:** halaman PDF desain tidak berhasil dirender/dibaca secara visual dalam pemeriksaan ini. `screen_inventory.md` memetakan kebutuhan dan alur BRD ke nama berkas; uraian fungsionalnya bukan hasil observasi layout. Warna, tipografi, ikon, ukuran, urutan komponen, teks aktual, dan aksi tombol tidak boleh dianggap telah diverifikasi. Tidak ditemukan PDF desain web warga atau dashboard petugas pada folder acuan.

### 14.3 Implementasi yang diperiksa

**Flutter:** proyek masih scaffold Flutter. `lib/main.dart` menampilkan contoh penghitung Flutter; `lib/` hanya memiliki berkas Dart tersebut. `pubspec.yaml` hanya memuat Flutter dan Cupertino Icons; belum ada dependensi atau integrasi API aplikasi. Belum ada layar atau alur Siaga Banjir yang diimplementasikan.

**Laravel:** `php artisan --version` menghasilkan Laravel Framework 13.38.0. `php artisan route:list` menunjukkan route aplikasi `GET /` (welcome) dan `GET /api/user` dengan `auth:sanctum`. Route lainnya (`sanctum/csrf-cookie`, storage, dan health check `/up`) adalah route framework. Model `User` memiliki trait Sanctum; controller aplikasi selain controller dasar belum ada. Tidak ditemukan endpoint daftar/login, profil, SOS, laporan, keluarga, konten, maupun dashboard.

**Database dan migration:** pemeriksaan status terakhir menunjukkan empat migration dasar berstatus `Ran`. Database memiliki tabel dasar `users`, `password_reset_tokens`, `sessions`, `cache`, `cache_locks`, `jobs`, `job_batches`, `failed_jobs`, `personal_access_tokens`, dan metadata `migrations`. Belum ada tabel domain Siaga Banjir seperti peringatan, titik bahaya, posko, pembacaan sungai, SOS, laporan, atau keluarga. Keberadaan tabel dasar tidak berarti fitur penggunaannya sudah dibuat.

### 14.4 Kesenjangan BRD terhadap implementasi

| Area | Kebutuhan BRD | Kondisi implementasi yang diperiksa | Kesenjangan |
|---|---|---|---|
| Akun dan profil | Registrasi/login warga dan petugas, profil dan kontrol akses | Tabel `users`, model dasar, route `/api/user` terautentikasi | Belum ada endpoint/alur login, registrasi, profil, role/otorisasi petugas, atau UI |
| Status dan informasi | Status siaga, peta bahaya/posko, cuaca, tinggi sungai, peringatan | Belum ada model, tabel domain, endpoint, atau layar | Seluruh kebutuhan informasi belum diimplementasikan |
| SOS dan operasi petugas | Kirim SOS, status/transisi, lokasi saat tindakan, dashboard dan tindak lanjut | Belum ada model, tabel domain, endpoint, atau layar | Alur Must SOS belum tersedia |
| Laporan warga | Kirim dan lacak laporan, verifikasi petugas, publikasi yang disetujui | Belum ada implementasi | Alur laporan lintas warga/petugas belum tersedia |
| Keluarga | Undangan/keanggotaan, status; chat berprioritas Could | Belum ada implementasi | Fitur keluarga belum tersedia; keputusan alur yang sudah tercatat di §12 tetap berlaku |
| Edukasi/kesiapsiagaan | Konten, tas siaga, riwayat dan kontak | Belum ada implementasi | Belum tersedia; sebagian berprioritas Could |
| Web warga dan petugas | Informasi/pelaporan warga dan pengelolaan simulasi oleh petugas | Hanya halaman welcome Laravel | Kedua permukaan web belum dibuat |
| Desain | Mengacu pada layar yang disediakan | PDF ada, tetapi inspeksi visual belum berhasil | Layout dan alur visual harus divalidasi sebelum UI dibangun |

### 14.5 Urutan pengerjaan yang disarankan — usulan

1. **Validasi acuan:** tinjau visual PDF melalui ekspor PNG/JPG atau viewer yang dapat dibaca; cocokkan dengan BRD draft dan keputusan pengguna §12. Jangan menganggap uraian di inventaris sebagai hasil observasi desain.
2. **Sepakati kebutuhan terbuka:** tetapkan keputusan yang mempengaruhi privasi, data, atau integrasi sebelum membuat skema domain.
3. **Rancang dan tinjau kontrak data/API:** mulai dari autentikasi/profil dan role petugas, kemudian data siaga simulasi; tinjau tabel domain dan akses server-side sebelum migration baru.
4. **Bangun alur Must bertahap:** akun/otorisasi; status siaga dan informasi; SOS beserta transisi/audit serta alur petugas; laporan dan verifikasi. Hubungkan Flutter dan API per alur.
5. **Bangun kebutuhan Should/Could:** cuaca, data sungai, evakuasi, keluarga; kemudian chat, edukasi, checklist, riwayat, dan konten sesuai prioritas serta waktu proyek.
6. **Bangun web warga dan dashboard petugas** setelah kebutuhan halaman dan akses dikonfirmasi; gunakan API/data yang sama dan lindungi tindakan petugas di server.
7. **Verifikasi setiap tahap:** uji hak akses, validasi, kegagalan jaringan, privasi lokasi, data DEMO, aksesibilitas, dan alur utama sebelum menyebut fitur siap.

### 14.6 Hal yang masih perlu dikonfirmasi sebelum implementasi terkait

Keputusan yang telah dibuat pada §12 (email/password dengan Google opsional; akun petugas dibuat manual; notifikasi awal in-app; peta sederhana; aturan pembatalan SOS; persetujuan penerima untuk permintaan keluarga via nomor HP; chat prioritas rendah; label data simulasi) tidak diulang sebagai pertanyaan. Hal yang masih terbuka:

- Ekspor/akses visual desain dan konfirmasi apakah alur serta teks PDF sesuai dengan BRD.
- Persetujuan kebijakan retensi data; usulan periode di §12 belum menjadi kebijakan dan purge otomatis belum boleh dibuat.
- Ambang TMA demo per titik, satuan/level, dan penanggung jawab penetapan data simulasi.
- Kategori, field, status, alasan penolakan, serta edit/hapus pada alur laporan.
- Versi minimum Android dan browser.
- Engine/vendor peta, tiles/geocoding/rute, batas biaya/kuota; “peta sederhana” belum menentukan teknologi.
- Endpoint/format/izin BMKG dan atribusi aktual; jangan mengklaim integrasi langsung sebelum diverifikasi.
- Apakah web warga memerlukan daftar notifikasi in-app; push tetap belum termasuk sebelum layanan dipilih dan diuji.
- Masa berlaku permintaan keluarga via nomor HP dan pemilihan grup bila penerima memiliki lebih dari satu grup.
- Detail operasional akun petugas, serta nomor/kontak darurat yang benar-benar akan dipakai.
- Kebutuhan halaman web warga dan dashboard petugas yang lebih rinci; berkas desain kedua permukaan itu tidak ditemukan.
