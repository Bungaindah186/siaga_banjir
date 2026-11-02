import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/app_routes.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../widgets/feature_page_shell.dart';
import '../widgets/reference_components.dart';

const _navy = Color(0xFF0B2E3B);
const _teal = Color(0xFF12809A);
const _paper = Color(0xFFF1F6F8);

class EducationScreen extends StatelessWidget {
  const EducationScreen({
    super.key,
    required this.account,
    required this.locationService,
  });
  final AuthenticatedUser account;
  final LocationService locationService;

  @override
  Widget build(BuildContext context) => FeaturePageShell(
    title: 'Edukasi',
    account: account,
    locationService: locationService,
    activeTab: 'Home',
    showTopActions: false,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _EducationTile(
          title: 'Langkah Cepat Evakuasi',
          subtitle: 'Panduan menyelamatkan diri saat air naik cepat',
          onTap: () => _showEducation(
            context,
            'Langkah Cepat Evakuasi',
            'Kenali jalur keluar, ikuti arahan petugas setempat, dan bawa kebutuhan penting bila aman dilakukan. Materi awal untuk ditinjau.',
          ),
        ),
        _EducationTile(
          title: 'Isi Tas Siaga Bencana',
          subtitle: '10 barang wajib sebelum musim hujan',
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.emergencyBag,
            arguments: AppRouteArguments(
              account: account,
              locationService: locationService,
            ),
          ),
        ),
        _EducationTile(
          title: 'Baca Level Status Siaga',
          subtitle: 'Arti Aman, Waspada, Siaga, Awas',
          onTap: () => _showEducation(
            context,
            'Baca Level Status Siaga',
            'Aman, Waspada, Siaga, dan Awas menunjukkan tingkat kesiapsiagaan. Ikuti informasi resmi pemerintah daerah. Materi awal untuk ditinjau.',
          ),
        ),
      ],
    ),
  );

  void _showEducation(BuildContext context, String title, String text) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
}

class _EducationTile extends StatelessWidget {
  const _EducationTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 95,
                height: 94,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_teal, _navy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(color: _navy)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class EmergencyBagScreen extends StatefulWidget {
  const EmergencyBagScreen({
    super.key,
    required this.account,
    required this.locationService,
  });
  final AuthenticatedUser account;
  final LocationService locationService;
  @override
  State<EmergencyBagScreen> createState() => _EmergencyBagScreenState();
}

class _EmergencyBagScreenState extends State<EmergencyBagScreen> {
  static const String _storageKey = 'emergency_bag_checked_items';

  late List<bool> _checked;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checked = List<bool>.filled(_bagItems.length, false);
    _loadCheckedItems();
  }

  Future<void> _loadCheckedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedItems = prefs.getStringList(_storageKey);

      if (!mounted) return;

      setState(() {
        if (savedItems != null && savedItems.length == _bagItems.length) {
          _checked = savedItems.map((value) => value == 'true').toList();
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      debugPrint('Gagal memuat daftar tas siaga: $e');
    }
  }

  Future<void> _saveCheckedItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      _checked.map((value) => value.toString()).toList(),
    );
  }

  Future<void> _updateCheckedItem(int index, bool value) async {
    setState(() {
      _checked[index] = value;
    });
    await _saveCheckedItems();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final count = _checked.where((value) => value).length;
    return FeaturePageShell(
      title: 'Isi tas siaga',
      account: widget.account,
      locationService: widget.locationService,
      activeTab: 'Home',
      showTopActions: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 105),
        children: [
          ReferenceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count dari 10 siap',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: count / 10,
                    minHeight: 14,
                    color: _teal,
                    backgroundColor: const Color(0xFFE2F1F4),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < _bagItems.length; i++)
            CheckboxListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              dense: true,
              visualDensity: VisualDensity.compact,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: _teal,
              title: Text(_bagItems[i]),
              value: _checked[i],
              onChanged: (value) {
                if (value != null) {
                  _updateCheckedItem(i, value);
                }
              },
            ),
          const Text(
            'Status daftar tersimpan di perangkat ini.',
            style: TextStyle(color: Color(0xFF71808D), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

const _bagItems = [
  'Air minum dan makanan instan',
  'Senter dan baterai cadangan',
  'Obat pribadi dan P3K',
  'Salinan dokumen dalam plastik',
  'Pakaian ganti',
  'Power bank',
  'Peluit',
  'Uang tunai',
  'Selimut',
  'Masker',
];

class CitizenReportScreen extends StatefulWidget {
  const CitizenReportScreen({
    super.key,
    required this.account,
    required this.locationService,
  });
  final AuthenticatedUser account;
  final LocationService locationService;
  @override
  State<CitizenReportScreen> createState() => _CitizenReportScreenState();
}

class _CitizenReportScreenState extends State<CitizenReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _location = TextEditingController();
  final _description = TextEditingController();
  final _eventTime = TextEditingController();
  final _waterLevel = TextEditingController();
  String? _type;
  final ApiClient _apiClient = ApiClient();
  bool _isSubmitting = false;
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedPhoto;
  Uint8List? _selectedPhotoBytes;
  List<Map<String, dynamic>> _recentReports = [];
  bool _isLoadingRecentReports = true;
  String? _recentReportsError;

  Future<void> _pickPhoto() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (!mounted || photo == null) return;

      final bytes = await photo.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedPhoto = photo;
        _selectedPhotoBytes = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      _message('Tidak dapat memilih foto.');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRecentReports();
  }

  Future<void> _loadRecentReports() async {
    try {
      final reports = await _apiClient.fetchMyCitizenReports(
        token: widget.account.token,
      );

      if (!mounted) return;

      setState(() {
        _recentReports = reports.take(2).toList();
        _isLoadingRecentReports = false;
        _recentReportsError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingRecentReports = false;
        _recentReportsError = 'Riwayat laporan gagal dimuat.';
      });
    }
  }

  @override
  void dispose() {
    _location.dispose();
    _description.dispose();
    _eventTime.dispose();
    _waterLevel.dispose();
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FeaturePageShell(
    title: 'Lapor Warga',
    account: widget.account,
    locationService: widget.locationService,
    activeTab: 'Home',
    showTopActions: false,
    child: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(34, 16, 36, 110),
        children: [
          const _FormLabel('Lokasi Kejadian'),
          TextFormField(
            controller: _location,
            decoration: const InputDecoration(
              hintText: 'Deteksi Otomatis',
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Masukkan lokasi kejadian.'
                : null,
          ),
          const _FormLabel('Jenis Kejadian'),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(
              hintText: 'Pilih jenis kejadian',
              filled: true,
              fillColor: Colors.white,
            ),
            items: const [
              DropdownMenuItem(
                value: 'Genangan / Banjir',
                child: Text('Genangan / Banjir'),
              ),
              DropdownMenuItem(
                value: 'Jalan Tertutup',
                child: Text('Jalan Tertutup'),
              ),
              DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
            ],
            onChanged: (value) => setState(() => _type = value),
            validator: (value) =>
                value == null ? 'Pilih jenis kejadian.' : null,
          ),
          const _FormLabel('Deskripsi'),
          TextFormField(
            controller: _description,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Jelaskan kondisi...',
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Tambahkan deskripsi singkat.'
                : null,
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Informasi tambahan (opsional)'),
            children: [
              TextField(
                controller: _eventTime,
                decoration: const InputDecoration(
                  labelText: 'Waktu kejadian (opsional)',
                  hintText: 'Contoh: sekitar pukul 14.00',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _waterLevel,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ketinggian air (opsional)',
                  hintText: 'Isi jika diketahui',
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _pickPhoto,
                icon: const Icon(Icons.add),
                label: Text(
                  _selectedPhoto == null ? 'Tambah Foto' : 'Ganti Foto',
                ),
                style: OutlinedButton.styleFrom(
                  fixedSize: const Size.fromHeight(74),
                  side: const BorderSide(color: Color(0xFF9BA8AC)),
                ),
              ),

              if (_selectedPhotoBytes != null) ...[
                const SizedBox(height: 10),

                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    _selectedPhotoBytes!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                TextButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _selectedPhoto = null;
                            _selectedPhotoBytes = null;
                          });
                        },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus Foto'),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC8282B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Kirim Laporan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Riwayat Laporan',
                  style: TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.reportHistory,
                  arguments: AppRouteArguments(
                    account: widget.account,
                    locationService: widget.locationService,
                  ),
                ),
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          if (_isLoadingRecentReports)
            const Center(child: CircularProgressIndicator())
          else if (_recentReportsError != null)
            Text(
              _recentReportsError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            )
          else if (_recentReports.isEmpty)
            const Text(
              'Belum ada laporan yang dikirim.',
              style: TextStyle(color: Color(0xFF71808D), fontSize: 12),
            )
          else
            ..._recentReports.take(3).map((report) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(report['event_type']?.toString() ?? '-'),
                subtitle: Text(
                  '${report['location_name'] ?? '-'}\nStatus: ${report['status'] ?? 'Menunggu Verifikasi'}',
                ),
                isThreeLine: true,
              );
            }),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final waterLevelText = _waterLevel.text.trim();
    final waterLevel = waterLevelText.isEmpty
        ? null
        : double.tryParse(waterLevelText);

    if (waterLevelText.isNotEmpty && (waterLevel == null || waterLevel < 0)) {
      _message('Ketinggian air harus berupa angka dan tidak boleh negatif.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim laporan?'),
        content: const Text(
          'Laporan akan dikirim ke server SiagaBanjir untuk diteruskan ke petugas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Periksa lagi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await _apiClient.submitCitizenReport(
        photo: _selectedPhoto,
        token: widget.account.token,
        eventType: _type!,
        locationName: _location.text.trim(),
        description: _description.text.trim(),
        eventTime: _eventTime.text.trim().isEmpty
            ? null
            : _eventTime.text.trim(),
        waterLevelCm: waterLevel,
      );

      if (!mounted) return;

      _message('Laporan berhasil dikirim ke server.');

      _formKey.currentState!.reset();
      _location.clear();
      _description.clear();
      _eventTime.clear();
      _waterLevel.clear();

      setState(() => _type = null);
    } on ApiException catch (e) {
      if (!mounted) return;
      _message('Gagal mengirim laporan: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      _message('Terjadi kesalahan saat mengirim laporan.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _message(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 9, bottom: 5),
    child: Text(
      text,
      style: const TextStyle(color: _navy, fontWeight: FontWeight.w700),
    ),
  );
}

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({
    super.key,
    required this.account,
    required this.locationService,
  });

  final AuthenticatedUser account;
  final LocationService locationService;

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  final ApiClient _apiClient = ApiClient();

  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reports = await _apiClient.fetchMyCitizenReports(
        token: widget.account.token,
      );

      if (!mounted) return;

      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Gagal mengambil riwayat laporan.';
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();

    final local = date.toLocal();

    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  @override
  Widget build(BuildContext context) => FeaturePageShell(
    title: 'Riwayat Laporan',
    account: widget.account,
    locationService: widget.locationService,
    activeTab: 'Home',
    showTopActions: false,
    child: _buildReportContent(),
  );

  Widget _buildReportContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadReports,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_reports.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(30),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.description_outlined, size: 48, color: Color(0xFF71808D)),
          SizedBox(height: 12),
          Text('Belum ada laporan yang dikirim.', textAlign: TextAlign.center),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final report in _reports)
            ReferenceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report['event_type']?.toString() ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(report['location_name']?.toString() ?? '-'),
                  Text(report['description']?.toString() ?? '-'),
                  if (report['event_time'] != null &&
                      report['event_time'].toString().isNotEmpty)
                    Text('Waktu: ${report['event_time']}'),
                  if (report['water_level_cm'] != null)
                    Text('Ketinggian air: ${report['water_level_cm']} cm'),
                  Text('Dikirim: ${_formatDate(report['created_at'])}'),
                  const SizedBox(height: 6),
                  ReferenceStatusPill(
                    label:
                        report['status']?.toString() ?? 'Menunggu Verifikasi',
                    color: const Color(0xFF987300),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class DisasterHistoryScreen extends StatefulWidget {
  const DisasterHistoryScreen({
    super.key,
    required this.account,
    required this.locationService,
  });

  final AuthenticatedUser account;
  final LocationService locationService;

  @override
  State<DisasterHistoryScreen> createState() => _DisasterHistoryScreenState();
}

class _DisasterHistoryScreenState extends State<DisasterHistoryScreen> {
  final ApiClient _apiClient = ApiClient();

  List<Map<String, dynamic>> _histories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistories();
  }

  Future<void> _loadHistories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final histories = await _apiClient.fetchDisasterHistories();

      if (!mounted) return;

      setState(() {
        _histories = histories;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Gagal mengambil riwayat bencana.';
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();

    final local = date.toLocal();

    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FeaturePageShell(
    title: 'Riwayat bencana',
    account: widget.account,
    locationService: widget.locationService,
    activeTab: 'Home',
    showTopActions: false,
    child: _buildContent(),
  );

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 45, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadHistories,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_histories.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadHistories,
        child: ListView(
          padding: const EdgeInsets.all(28),
          children: const [
            SizedBox(height: 100),
            Icon(Icons.history, size: 55, color: Color(0xFF71808D)),
            SizedBox(height: 14),
            Text(
              'Belum ada riwayat bencana yang tercatat.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF71808D), fontSize: 15),
            ),
            SizedBox(height: 8),
            Text(
              'Kejadian banjir yang telah diverifikasi akan ditampilkan di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF71808D), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistories,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          for (final history in _histories)
            ReferenceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    history['title']?.toString() ?? '-',
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 17,
                        color: _teal,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          history['location_name']?.toString() ?? '-',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(history['description']?.toString() ?? '-'),
                  const SizedBox(height: 8),
                  Text(
                    'Tanggal kejadian: ${_formatDate(history['event_time'])}',
                    style: const TextStyle(
                      color: Color(0xFF71808D),
                      fontSize: 12,
                    ),
                  ),
                  if (history['water_level_cm'] != null)
                    Text('Ketinggian air: ${history['water_level_cm']} cm'),
                  if (history['impact'] != null &&
                      history['impact'].toString().isNotEmpty)
                    Text('Dampak: ${history['impact']}'),
                  const SizedBox(height: 10),
                  ReferenceStatusPill(
                    label: history['status']?.toString() ?? '-',
                    color: history['status'] == 'Selesai'
                        ? const Color(0xFF2EA361)
                        : const Color(0xFF987300),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.account,
    required this.locationService,
  });

  final AuthenticatedUser account;
  final LocationService locationService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiClient _apiClient = ApiClient();

  List<bool> _notifications = [true, true, false];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // Mengambil pengaturan notifikasi dari Laravel.
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final saved = await _apiClient.fetchNotificationPreferences(
        token: widget.account.token,
      );

      if (!mounted) return;

      setState(() {
        _notifications = [
          saved['notification_alert'] ?? true,
          saved['notification_river'] ?? true,
          saved['notification_education'] ?? false,
        ];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat pengaturan notifikasi: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  // Menyimpan perubahan toggle ke database Laravel.
  Future<void> _updateNotification(int index, bool value) async {
    if (_isSaving) return;

    final previousNotifications = List<bool>.from(_notifications);

    setState(() {
      _notifications[index] = value;
      _isSaving = true;
    });

    try {
      final saved = await _apiClient.updateNotificationPreferences(
        token: widget.account.token,
        notificationAlert: _notifications[0],
        notificationRiver: _notifications[1],
        notificationEducation: _notifications[2],
      );

      if (!mounted) return;

      setState(() {
        _notifications = [
          saved['notification_alert'] ?? true,
          saved['notification_river'] ?? true,
          saved['notification_education'] ?? false,
        ];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan notifikasi berhasil disimpan.'),
        ),
      );
    } catch (e) {
      debugPrint('Gagal menyimpan pengaturan notifikasi: $e');

      if (!mounted) return;

      setState(() {
        _notifications = previousNotifications;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan pengaturan: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FeaturePageShell(
    title: 'Pengaturan',
    account: widget.account,
    locationService: widget.locationService,
    activeTab: 'Home',
    showTopActions: false,
    child: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _loadError != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, size: 45, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text(
                    'Pengaturan notifikasi gagal dimuat.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadNotifications,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          )
        : ListView(
            padding: const EdgeInsets.fromLTRB(25, 16, 25, 100),
            children: [
              const _SettingHeading('Lokasi & Wilayah'),
              _SettingRow(
                'Lokasi Rumah',
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.homeLocation,
                    arguments: AppRouteArguments(
                      account: widget.account,
                      locationService: widget.locationService,
                    ),
                  );
                },
              ),
              const _SettingHeading('Notifikasi'),
              for (var i = 0; i < 3; i++)
                _SettingToggle(
                  ['Status Siaga', 'Ketinggian Sungai', 'Artikel Edukasi'][i],
                  value: _notifications[i],
                  onChanged: (value) => _updateNotification(i, value),
                ),
              const _SettingHeading('Akun'),
              _SettingRow(
                'Profil',
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.profile,
                  arguments: AppRouteArguments(
                    account: widget.account,
                    locationService: widget.locationService,
                  ),
                ),
              ),
              _SettingRow(
                'Bahasa',
                trailing: 'ID',
                onTap: () =>
                    _note(context, 'Bahasa Indonesia sedang digunakan.'),
              ),
            ],
          ),
  );

  void _note(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SettingHeading extends StatelessWidget {
  const _SettingHeading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 5),
    child: Text(text, style: const TextStyle(color: _navy, fontSize: 19)),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow(this.title, {required this.onTap, this.trailing});
  final String title;
  final VoidCallback onTap;
  final String? trailing;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    child: ListTile(
      title: Text(title),
      trailing: trailing == null
          ? const Icon(Icons.chevron_right)
          : Text('$trailing  ›'),
      onTap: onTap,
      dense: true,
    ),
  );
}

class _SettingToggle extends StatelessWidget {
  const _SettingToggle(
    this.title, {
    required this.value,
    required this.onChanged,
  });
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    child: SwitchListTile(
      title: Text(title),
      value: value,
      activeTrackColor: const Color(0xFF2EA361),
      onChanged: onChanged,
      dense: true,
    ),
  );
}

class FamilyActionScreen extends StatefulWidget {
  const FamilyActionScreen({
    super.key,
    required this.account,
    required this.locationService,
    required this.mode,
    this.inviteCode,
  });

  final AuthenticatedUser account;
  final LocationService locationService;
  final String mode;
  final String? inviteCode;

  @override
  State<FamilyActionScreen> createState() => _FamilyActionScreenState();
}

class _FamilyActionScreenState extends State<FamilyActionScreen> {
  final _controller = TextEditingController();
  String? _activeInviteCode;
  bool _isLoadingInviteCode = false;
  Future<void> _loadInviteCode() async {
    if (widget.mode != 'code') return;

    setState(() {
      _isLoadingInviteCode = true;
    });

    try {
      final groups = await ApiClient().fetchFamilyGroups(
        token: widget.account.token,
      );

      if (!mounted) return;

      if (groups.isNotEmpty) {
        setState(() {
          _activeInviteCode = groups.first['invite_code']?.toString();
        });
      } else {
        setState(() {
          _activeInviteCode = null;
        });
      }
    } catch (e) {
      if (!mounted) return;

      _message('Gagal mengambil kode undangan dari server.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInviteCode = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _activeInviteCode = widget.inviteCode;
    _loadInviteCode();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final join = widget.mode == 'join';
    final codeMode = widget.mode == 'code';

    return FeaturePageShell(
      title: join ? 'Gabung keluarga' : 'Tambah anggota',
      account: widget.account,
      locationService: widget.locationService,
      activeTab: 'Keluarga',
      showTopActions: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(30, 18, 30, 100),
        children: [
          if (!join) ...[
            Row(
              children: [
                Expanded(
                  child: _ChoiceButton(
                    label: 'Nomor HP',
                    selected: !codeMode,
                    onTap: () => _switch(context, AppRoutes.familyAddPhone),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ChoiceButton(
                    label: 'Kode undangan',
                    selected: codeMode,
                    onTap: () => _switch(context, AppRoutes.familyInviteCode),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Halaman untuk menampilkan kode undangan asli dari Laravel.
          if (codeMode) ...[
            ReferenceCard(
              child: Column(
                children: [
                  const Text(
                    'Bagikan kode ini ke keluarga',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  if (_isLoadingInviteCode)
                    const CircularProgressIndicator()
                  else
                    SelectableText(
                      _activeInviteCode != null && _activeInviteCode!.isNotEmpty
                          ? _activeInviteCode!
                          : 'Belum ada kode undangan',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                      ),
                    ),

                  const SizedBox(height: 8),

                  Text(
                    _activeInviteCode != null && _activeInviteCode!.isNotEmpty
                        ? 'Bagikan kode ini kepada anggota keluarga.'
                        : 'Buat grup keluarga terlebih dahulu.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _actionButton('Bagikan lewat WhatsApp', () async {
              final code = _activeInviteCode?.trim();

              if (_isLoadingInviteCode) {
                _message('Sedang mengambil kode undangan. Tunggu sebentar.');
                return;
              }

              if (code == null || code.isEmpty) {
                _message('Belum ada kode undangan untuk dibagikan.');
                return;
              }

              final message =
                  'Halo! Yuk, bergabung dengan grup keluarga kami di SiagaBanjir.\n\n'
                  'Gunakan kode undangan berikut:\n'
                  '$code\n\n'
                  'Masukkan kode tersebut pada menu Gabung Keluarga di aplikasi SiagaBanjir.';

              final whatsappUri = Uri.https('wa.me', '/', {'text': message});

              try {
                final opened = await launchUrl(
                  whatsappUri,
                  mode: LaunchMode.externalApplication,
                );

                if (!opened && mounted) {
                  _message('WhatsApp tidak dapat dibuka. Silakan coba lagi.');
                }
              } catch (e) {
                if (mounted) {
                  _message(
                    'Gagal membuka WhatsApp. Periksa aplikasi WhatsApp kamu.',
                  );
                }
              }
            }),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed:
                  _activeInviteCode == null ||
                      _activeInviteCode!.isEmpty ||
                      _isLoadingInviteCode
                  ? null
                  : () async {
                      await Clipboard.setData(
                        ClipboardData(text: _activeInviteCode!),
                      );

                      if (!mounted) return;

                      _message('Kode undangan berhasil disalin.');
                    },
              child: const Text('Salin kode undangan'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _switch(context, AppRoutes.familyJoinCode),
              child: const Text('Gabung keluarga'),
            ),
          ] else ...[
            // Form untuk bergabung dengan kode atau memasukkan nomor HP.
            ReferenceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    join
                        ? 'Masukkan kode undangan'
                        : 'Masukkan nomor HP anggota keluarga',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    join
                        ? 'Minta kode undangan dari anggota keluargamu.'
                        : 'Pengiriman undangan melalui SMS belum diaktifkan.',
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _controller,
                    keyboardType: join
                        ? TextInputType.text
                        : TextInputType.phone,
                    textCapitalization: join
                        ? TextCapitalization.characters
                        : TextCapitalization.none,
                    decoration: InputDecoration(
                      hintText: join ? 'ABC-1234' : '+62 812-3456-7890',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _actionButton(join ? 'Gabung' : 'Kirim undangan', _submit),
          ],
        ],
      ),
    );
  }

  void _switch(BuildContext context, String route) {
    Navigator.pushReplacementNamed(
      context,
      route,
      arguments: AppRouteArguments(
        account: widget.account,
        locationService: widget.locationService,
        inviteCode: route == AppRoutes.familyInviteCode
            ? widget.inviteCode
            : null,
      ),
    );
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    final join = widget.mode == 'join';

    final validPhone =
        RegExp(r'^\+?[0-9][0-9\s\-()]{7,20}$').hasMatch(value) &&
        value.replaceAll(RegExp(r'\D'), '').length >= 8;

    if (value.isEmpty ||
        (widget.mode == 'phone' && !validPhone) ||
        (join && !RegExp(r'^[A-Za-z]{3}-\d{4}$').hasMatch(value))) {
      _message(
        join
            ? 'Masukkan kode dengan format ABC-1234.'
            : 'Masukkan nomor HP yang valid.',
      );
      return;
    }

    final apiClient = ApiClient();

    try {
      if (join) {
        await apiClient.joinFamilyGroup(
          token: widget.account.token,
          inviteCode: value.toUpperCase(),
        );

        if (!mounted) return;

        _message('Berhasil bergabung dengan grup keluarga.');

        Navigator.popUntil(
          context,
          (route) => route.settings.name == AppRoutes.family || route.isFirst,
        );
        return;
      }

      // Mengirim undangan kepada pengguna yang sudah terdaftar.
      final result = await apiClient.sendFamilyInvitation(
        token: widget.account.token,
        phone: value,
      );

      if (!mounted) return;

      _controller.clear();

      _message(
        result['message']?.toString() ?? 'Undangan keluarga berhasil dikirim.',
      );
    } catch (e) {
      if (!mounted) return;

      _message('Gagal memproses: $e');
    } finally {
      apiClient.dispose();
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onTap,
    style: FilledButton.styleFrom(
      backgroundColor: selected ? _navy : _paper,
      foregroundColor: selected ? Colors.white : _navy,
      side: const BorderSide(color: _navy),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: Text(label, textAlign: TextAlign.center),
  );
}

Widget _actionButton(String label, VoidCallback action) => SizedBox(
  height: 48,
  child: FilledButton(
    onPressed: action,
    style: FilledButton.styleFrom(
      backgroundColor: _teal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
    ),
    child: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
    ),
  ),
);

class SosScreen extends StatefulWidget {
  const SosScreen({
    super.key,
    required this.account,
    required this.locationService,
  });

  final AuthenticatedUser account;
  final LocationService locationService;

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  int _kind = 0;
  bool _family = false;
  bool _isHolding = false;
  double _progress = 0;
  Timer? _holdTimer;

  static const List<String> _emergencyTypes = [
    'Terjebak',
    'Terluka',
    'Butuh Evakuasi',
  ];

  void _startHolding() {
    if (_isHolding) return;

    _holdTimer?.cancel();

    setState(() {
      _isHolding = true;
      _progress = 0;
    });

    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _progress += 0.1 / 3;
      });

      if (_progress >= 1) {
        timer.cancel();
        _holdTimer = null;
        _completeSos();
      }
    });
  }

  void _cancelHolding() {
    if (!_isHolding) return;

    _holdTimer?.cancel();
    _holdTimer = null;

    setState(() {
      _isHolding = false;
      _progress = 0;
    });
  }

  void _completeSos() {
    if (!mounted) return;

    setState(() {
      _isHolding = false;
      _progress = 1;
    });

    Navigator.pushNamed(
      context,
      AppRoutes.sosComplete,
      arguments: AppRouteArguments(
        account: widget.account,
        locationService: widget.locationService,
        title: _emergencyTypes[_kind],
        detail: _family ? 'true' : 'false',
      ),
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FeaturePageShell(
    title: 'Kirim SOS',
    account: widget.account,
    locationService: widget.locationService,
    activeTab: 'Home',
    showSos: false,
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const Text(
                    'Pilih jenis Darurat',
                    style: TextStyle(color: _navy, fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < _emergencyTypes.length; i++)
                        ChoiceChip(
                          label: Text(_emergencyTypes[i]),
                          selected: _kind == i,
                          onSelected: _isHolding
                              ? null
                              : (_) => setState(() => _kind = i),
                          selectedColor: _navy,
                          backgroundColor: _paper,
                          side: BorderSide(
                            color: _kind == i ? _navy : const Color(0xFF9BA8AC),
                          ),
                          labelStyle: TextStyle(
                            color: _kind == i ? Colors.white : _navy,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTapDown: (_) => _startHolding(),
                    onTapUp: (_) => _cancelHolding(),
                    onTapCancel: _cancelHolding,
                    child: SizedBox(
                      width: 150,
                      height: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: CircularProgressIndicator(
                              value: _progress,
                              strokeWidth: 8,
                              backgroundColor: const Color(0xFFF4C9CA),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFC8282B),
                              ),
                            ),
                          ),
                          Container(
                            width: 116,
                            height: 116,
                            decoration: const BoxDecoration(
                              color: Color(0xFFC8282B),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    _isHolding
                        ? 'Tahan ${((3 * (1 - _progress)).ceil()).clamp(0, 3)} detik...'
                        : 'Tahan 3 detik......',
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Lepas untuk membatalkan',
                    style: TextStyle(color: Color(0xFF526B78), fontSize: 11),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E7EA)),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text(
                    'Kirim juga ke keluarga',
                    style: TextStyle(fontSize: 12, color: _navy),
                  ),
                  value: _family,
                  activeTrackColor: const Color(0xFF2EA361),
                  onChanged: _isHolding
                      ? null
                      : (value) => setState(() => _family = value),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: _isHolding
                    ? _cancelHolding
                    : () => Navigator.pop(context),
                child: const Text('Batalkan', style: TextStyle(color: _navy)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SosCompleteScreen extends StatelessWidget {
  const SosCompleteScreen({
    super.key,
    required this.account,
    required this.locationService,
    required this.emergencyType,
    required this.notifyFamily,
  });

  final AuthenticatedUser account;
  final LocationService locationService;
  final String emergencyType;
  final bool notifyFamily;

  @override
  Widget build(BuildContext context) {
    // Belum ada data posko dan estimasi waktu dari server.
    const destinationName = 'Belum tersedia';
    const estimatedTime = 'Belum tersedia';

    return FeaturePageShell(
      title: 'SOS',
      account: account,
      locationService: locationService,
      activeTab: 'Home',
      showSos: false,
      showTopActions: false,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 28, 18, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 52),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ikon centang hijau.
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2EA361),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 82),
                ),

                const SizedBox(height: 12),

                // Judul.
                const Text(
                  'SOS Berhasil Dikirim',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                // Keterangan simulasi.
                const Text(
                  'Simulasi SOS berhasil diselesaikan. '
                  'Tidak ada petugas yang benar-benar menerima '
                  'laporan dan tidak ada bantuan yang dikirim.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF263840), fontSize: 13),
                ),

                const SizedBox(height: 18),

                // Informasi jenis keadaan darurat.
                Text(
                  'Jenis darurat: $emergencyType',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  notifyFamily
                      ? 'Pilihan keluarga: Diaktifkan'
                      : 'Pilihan keluarga: Tidak diaktifkan',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF526B78),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 18),

                // Dua kartu informasi seperti desain Figma.
                Row(
                  children: [
                    Expanded(
                      child: _sosInfoCard(
                        title: 'Diterima',
                        value: destinationName,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _sosInfoCard(
                        title: 'Estimasi',
                        value: estimatedTime,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Tombol Kembali tetap dipertahankan.
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _navy,
                      side: const BorderSide(color: Color(0xFF81949B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Kembali',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sosInfoCard({required String title, required String value}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E7EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF526B78), fontSize: 11),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _navy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
