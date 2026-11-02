import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../navigation/app_routes.dart';
import '../widgets/feature_page_shell.dart';

import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.account,
    required this.locationService,
    required this.apiClient,
  });

  final AuthenticatedUser account;
  final LocationService locationService;
  final ApiClient apiClient;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  bool _initialCheckStarted = false;
  bool _locationDialogShown = false;
  bool _gettingLocation = false;
  bool _loadingProfile = false;
  bool _savingProfile = false;
  bool _uploadingPhoto = false;
  String? _profilePhotoPath;

  String _locationState = 'Belum diperiksa';
  String? _coordinates;
  String? _homeCoordinates;

  late final TextEditingController _phoneController;
  late final TextEditingController _homeController;

  @override
  void initState() {
    super.initState();

    _phoneController = TextEditingController();
    _homeController = TextEditingController();

    WidgetsBinding.instance.addObserver(this);

    _loadProfile();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnOpen();
    });
  }

  // Mengambil data profil dari server Laravel.
  Future<void> _loadProfile() async {
    if (_loadingProfile) return;

    setState(() {
      _loadingProfile = true;
    });

    try {
      final profile = await widget.apiClient.getProfile(
        token: widget.account.token,
      );

      if (!mounted) return;

      setState(() {
        _phoneController.text = profile.phone ?? '';
        _homeController.text = profile.homeAddress ?? '';
        _homeCoordinates =
            profile.homeLatitude != null && profile.homeLongitude != null
            ? '${profile.homeLatitude!.toStringAsFixed(5)}, '
                  '${profile.homeLongitude!.toStringAsFixed(5)}'
            : null;
        _profilePhotoPath = profile.profilePhotoPath;
      });
      debugPrint('FOTO DARI API: ${profile.profilePhotoPath}');
      debugPrint('URL FOTO: $_profilePhotoUrl');
    } catch (error) {
      if (!mounted) return;

      _message('Gagal mengambil data profil dari server.');
    } finally {
      if (mounted) {
        setState(() {
          _loadingProfile = false;
        });
      }
    }
  }

  // Memilih foto dari perangkat dan mengunggahnya ke Laravel.
  Future<void> _pickAndUploadPhoto() async {
    if (_uploadingPhoto) return;

    try {
      final picker = ImagePicker();

      final photo = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      // Jika pengguna membatalkan pemilihan foto, berhenti.
      if (photo == null || !mounted) return;

      setState(() {
        _uploadingPhoto = true;
      });

      final profile = await widget.apiClient.uploadProfilePhoto(
        token: widget.account.token,
        photo: photo,
      );

      if (!mounted) return;

      setState(() {
        _profilePhotoPath = profile.profilePhotoPath;
      });

      _message('Foto profil berhasil diperbarui.');
    } catch (error) {
      if (!mounted) return;

      _message('Foto profil gagal diunggah: $error');
    } finally {
      if (mounted) {
        setState(() {
          _uploadingPhoto = false;
        });
      }
    }
  }

  // Membentuk URL foto yang tersimpan di Laravel.
  String? get _profilePhotoUrl {
    final path = _profilePhotoPath;

    if (path == null || path.trim().isEmpty) {
      return null;
    }

    final serverUrl = widget.apiClient.baseUrl.replaceFirst(
      RegExp(r'/api/?$'),
      '',
    );

    return '$serverUrl/storage/${path.replaceFirst(RegExp(r'^/+'), '')}';
  }

  // Menyimpan nomor HP dan alamat rumah ke server Laravel.
  Future<void> _saveProfile() async {
    if (_savingProfile) return;

    setState(() {
      _savingProfile = true;
    });

    try {
      await widget.apiClient.updateProfile(
        token: widget.account.token,
        phone: _phoneController.text.trim(),
        homeAddress: _homeController.text.trim(),
      );

      if (!mounted) return;

      _message('Profil berhasil disimpan.');
    } catch (error) {
      if (!mounted) return;

      _message('Profil gagal disimpan. Periksa koneksi ke server.');
    } finally {
      if (mounted) {
        setState(() {
          _savingProfile = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _phoneController.dispose();
    _homeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _refreshIfPermissionGranted();
    }
  }

  // Memeriksa izin lokasi saat halaman profil dibuka.
  Future<void> _checkOnOpen() async {
    if (_initialCheckStarted || !mounted) return;

    _initialCheckStarted = true;

    final permission = await widget.locationService.checkPermissionStatus();

    if (!mounted) return;

    if (permission == LocationStatus.available) {
      await _getLocation(showError: false);
    } else {
      setState(() {
        _locationState = 'Izin lokasi belum diberikan';
      });

      await _showLocationDialog(permission);
    }
  }

  // Memperbarui lokasi ketika aplikasi kembali aktif.
  Future<void> _refreshIfPermissionGranted() async {
    if (_gettingLocation) return;

    final permission = await widget.locationService.checkPermissionStatus();

    if (!mounted || permission != LocationStatus.available) return;

    await _getLocation(showError: false, showRecoveryDialog: false);
  }

  // Menampilkan dialog untuk meminta pengguna mengaktifkan lokasi.
  Future<void> _showLocationDialog(LocationStatus status) async {
    if (_locationDialogShown || !mounted) return;

    _locationDialogShown = true;

    final deniedForever = status == LocationStatus.permissionDeniedForever;

    final serviceDisabled = status == LocationStatus.serviceDisabled;

    final actionLabel = deniedForever ? 'Buka Pengaturan' : 'Aktifkan Lokasi';

    final selectedAction = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aktifkan Lokasi'),
        content: Text(
          deniedForever
              ? 'Izin lokasi ditolak permanen. Buka pengaturan aplikasi dan izinkan akses Lokasi saat aplikasi digunakan agar informasi banjir dan wilayah sesuai posisi kamu.'
              : serviceDisabled
              ? 'Layanan lokasi perangkat sedang nonaktif. Aktifkan lokasi agar informasi banjir dan wilayah dapat disesuaikan.'
              : 'Lokasi diperlukan untuk menampilkan informasi banjir dan wilayah yang sesuai dengan posisi kamu.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Nanti'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    _locationDialogShown = false;

    if (!mounted || selectedAction != true) return;

    if (deniedForever) {
      await widget.locationService.openAppSettings();
      return;
    }

    if (serviceDisabled) {
      await widget.locationService.openLocationSettings();
      return;
    }

    await _getLocation(showError: true);
  }

  // Mengambil posisi perangkat.
  Future<void> _getLocation({
    required bool showError,
    bool showRecoveryDialog = true,
  }) async {
    if (_gettingLocation || !mounted) return;

    setState(() {
      _gettingLocation = true;
    });

    final result = await widget.locationService.checkAndGetCurrentPosition();

    if (!mounted) return;

    setState(() {
      _gettingLocation = false;

      switch (result.status) {
        case LocationStatus.available:
          final position = result.position!;

          _coordinates =
              '${position.latitude.toStringAsFixed(5)}, '
              '${position.longitude.toStringAsFixed(5)}';

          _locationState = 'Posisi perangkat tersedia';

        case LocationStatus.permissionDenied:
          _locationState = 'Izin lokasi ditolak';

        case LocationStatus.permissionDeniedForever:
          _locationState = 'Izin lokasi ditolak permanen';

        case LocationStatus.serviceDisabled:
          _locationState = 'GPS/lokasi perangkat nonaktif';

        case LocationStatus.failed:
          _locationState = 'Lokasi gagal diperoleh';
      }
    });

    if (showRecoveryDialog &&
        result.status == LocationStatus.permissionDeniedForever) {
      await _showLocationDialog(LocationStatus.permissionDeniedForever);
    } else if (showRecoveryDialog &&
        result.status == LocationStatus.serviceDisabled) {
      await _showLocationDialog(LocationStatus.serviceDisabled);
    } else if (showError && result.status != LocationStatus.available) {
      _message(_messageFor(result));
    } else if (showError && result.status == LocationStatus.available) {
      _message('Lokasi perangkat berhasil diperoleh.');
    }
  }

  String _messageFor(LocationResult result) {
    return switch (result.status) {
      LocationStatus.permissionDenied =>
        'Izin lokasi ditolak. Posisi terkini belum dapat digunakan.',
      LocationStatus.permissionDeniedForever =>
        'Izin ditolak permanen. Aktifkan melalui pengaturan aplikasi.',
      LocationStatus.serviceDisabled =>
        'Aktifkan GPS/lokasi perangkat untuk mendapatkan posisi.',
      LocationStatus.failed => result.message ?? 'Lokasi gagal diperoleh.',
      LocationStatus.available => 'Lokasi perangkat tersedia.',
    };
  }

  // Menampilkan pesan di bagian bawah layar.
  void _message(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.account.name.trim().isEmpty
        ? '?'
        : widget.account.name.trim()[0].toUpperCase();
    final photoUrl = _profilePhotoUrl;

    return FeaturePageShell(
      title: 'Profil',
      account: widget.account,
      locationService: widget.locationService,
      activeTab: 'Home',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(36, 39, 15, 112),
        children: [
          // Foto profil.
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF118AA1),
                  child: ClipOval(
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: photoUrl != null
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              webHtmlElementStrategy:
                                  WebHtmlElementStrategy.prefer,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: const Color(0xFFF1F6F8),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 17,
                      tooltip: 'Ubah foto profil',
                      onPressed: _uploadingPhoto ? null : _pickAndUploadPhoto,
                      icon: _uploadingPhoto
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.edit_outlined,
                              color: AppColors.teal,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Nama pengguna.
          _ProfileField(label: 'Nama Lengkap', value: widget.account.name),

          const SizedBox(height: 10),

          // Nomor HP.
          const Text(
            'Nomor HP',
            style: TextStyle(
              color: Color(0xFF0B2E3B),
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Tambahkan nomor HP',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(14),
              suffixIcon: _loadingProfile
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 10),

          // Alamat rumah.
          const Text(
            'Lokasi rumah',
            style: TextStyle(
              color: Color(0xFF0B2E3B),
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),
          TextField(
            controller: _homeController,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Masukkan alamat rumah',
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.all(14),
            ),
          ),

          if (_homeCoordinates != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: AppColors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Koordinat rumah: $_homeCoordinates',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 5),

          // Status lokasi perangkat.
          const Text(
            'Lokasi perangkat',
            style: TextStyle(
              color: Color(0xFF0B2E3B),
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_locationState),

                if (_coordinates case final coordinates?) ...[
                  const SizedBox(height: 4),
                  Text(
                    coordinates,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _gettingLocation
                        ? null
                        : () => _getLocation(showError: true),
                    icon: _gettingLocation
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: const Text('Periksa lokasi'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Anggota keluarga.
          const Text(
            'Anggota keluarga',
            style: TextStyle(
              color: Color(0xFF0B2E3B),
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 7),

          const _FamilyRow(label: 'Belum ada anggota keluarga'),

          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.familyAddPhone,
                  arguments: AppRouteArguments(
                    account: widget.account,
                    locationService: widget.locationService,
                  ),
                );
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Tambah Anggota'),
            ),
          ),

          const SizedBox(height: 16),

          // Tombol kembali dan simpan.
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Kembali'),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: FilledButton(
                  onPressed: _savingProfile || _loadingProfile
                      ? null
                      : _saveProfile,
                  child: _savingProfile
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Widget untuk menampilkan informasi profil yang tidak dapat diedit.
class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0B2E3B),
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 5),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(value, style: const TextStyle(color: AppColors.navy)),
        ),
      ],
    );
  }
}

// Widget untuk menampilkan daftar anggota keluarga.
class _FamilyRow extends StatelessWidget {
  const _FamilyRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(label, style: const TextStyle(color: AppColors.muted)),
    );
  }
}
