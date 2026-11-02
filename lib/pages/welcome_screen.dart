import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

import '../services/api_client.dart';
import '../services/browser_notification.dart';


class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.account,
    required this.onContinue,
  });

  final AuthenticatedUser account;
  final ValueChanged<BuildContext> onContinue;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final ApiClient _apiClient = ApiClient();

  bool _locationSelected = false;
  bool _notificationsSelected = false;
  String _homeLocation = '';
  bool _navigating = false;

  @override
  void initState() {
  super.initState();
  _refreshPermissions();
  }
  Future<void> _refreshPermissions() async {
    try {
      bool locationGranted = false;
      bool notificationGranted = false;

      if (kIsWeb) {
        final granted = await requestBrowserNotificationPermission();
        if (!mounted) return;

        setState(() {
          _notificationsSelected = granted;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              granted
                  ? 'Izin notifikasi browser berhasil diberikan.'
                  : 'Izin notifikasi belum diberikan. Periksa pengaturan situs di Chrome.',
            ),
          ),
        );

return;
      } else {
        final locationPermission = await Geolocator.checkPermission();
        final notificationStatus = await Permission.notification.status;

        locationGranted =
            locationPermission == LocationPermission.whileInUse ||
            locationPermission == LocationPermission.always;

        notificationGranted = notificationStatus.isGranted;
      }

      if (!mounted) return;

      setState(() {
        _locationSelected = locationGranted;
        _notificationsSelected = notificationGranted;
      });
    } catch (e) {
      debugPrint('Gagal memeriksa izin: $e');
    }
  }
  Future<void> _handleLocationChanged(bool enabled) async {
    if (!enabled) {
      setState(() => _locationSelected = false);
      return;
    }

    try {
      // Periksa apakah layanan lokasi perangkat/browser tersedia.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() => _locationSelected = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Layanan lokasi belum aktif. Aktifkan lokasi pada perangkat atau browser.',
            ),
          ),
        );
        return;
      }

      // Periksa izin lokasi saat ini.
      var permission = await Geolocator.checkPermission();

      // Minta izin jika belum diberikan.
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted) return;

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        setState(() => _locationSelected = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izin lokasi belum diberikan. Periksa pengaturan izin lokasi browser atau perangkat.',
            ),
          ),
        );
        return;
      }

      // Coba mengambil koordinat untuk memastikan lokasi benar-benar tersedia.
      final position = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      setState(() => _locationSelected = true);

      debugPrint(
        'Lokasi berhasil diperoleh: '
        '${position.latitude}, ${position.longitude}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akses lokasi berhasil diaktifkan.'),
        ),
      );
    } catch (e) {
      debugPrint('Gagal meminta atau mengambil lokasi: $e');

      if (!mounted) return;

      setState(() => _locationSelected = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lokasi belum dapat diaktifkan. Periksa izin browser dan koneksi.',
          ),
        ),
      );
    }
  }
  Future<void> _handleNotificationChanged(bool enabled) async {
    if (!enabled) {
      setState(() {
        _notificationsSelected = false;
      });

      return;
    }

    try {
      if (kIsWeb) {
        final granted = await requestBrowserNotificationPermission();

        if (!mounted) return;

        setState(() {
          _notificationsSelected = granted;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              granted
                  ? 'Izin notifikasi browser berhasil diberikan.'
                  : 'Izin notifikasi belum diberikan. Periksa pengaturan situs di Chrome.',
            ),
          ),
        );

        return;
      }

      final status = await Permission.notification.request();

      if (!mounted) return;

      if (status.isGranted) {
        setState(() {
          _notificationsSelected = true;
        });
      } else {
        setState(() {
          _notificationsSelected = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izin notifikasi belum diberikan. '
              'Periksa pengaturan notifikasi perangkat.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Gagal meminta izin notifikasi: $e');

      if (!mounted) return;

      setState(() {
        _notificationsSelected = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notifikasi belum dapat diaktifkan.',
          ),
        ),
      );
    }
  }
  Future<void> _editHomeLocation() async {
    final controller = TextEditingController(text: _homeLocation);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lokasi rumah'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Alamat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || value == null || value.isEmpty) return;
    setState(() => _homeLocation = value);
  }

Future<void> _continue() async {
  if (_navigating) return;

  setState(() => _navigating = true);
  FocusScope.of(context).unfocus();

  try {
    // Simpan alamat rumah ke database Laravel.
    await _apiClient.updateProfile(
      token: widget.account.token,
      homeAddress: _homeLocation.trim(),
    );

    if (!mounted) return;

    // Berpindah ke halaman berikutnya setelah alamat tersimpan.
    widget.onContinue(context);
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Alamat rumah gagal disimpan. Periksa koneksi server.',
        ),
      ),
    );

    setState(() => _navigating = false);
  }
}
  @override
  Widget build(BuildContext context) {
    final canContinue = _locationSelected && _notificationsSelected;
    final welcomeTheme = Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme
          .apply(fontFamily: 'AtkinsonHyperlegible'),
      primaryTextTheme: Theme.of(context).primaryTextTheme
          .apply(fontFamily: 'AtkinsonHyperlegible'),
    );
    return Theme(
      data: welcomeTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF0B2E3B),
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFFF1F6F8),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF1F6F8),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 124,
                  padding: EdgeInsets.fromLTRB(
                    22,
                    MediaQuery.paddingOf(context).top + 8,
                    22,
                    18,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0B2E3B),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Selamat Datang',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxHeight < 690;
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          33,
                          compact ? 12 : 11,
                          37,
                          22,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 5),
                                  child: Text(
                                    'Aktifkan agar peringatan tepat',
                                    maxLines: 2,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Color(0xFF0B2E3B),
                                      fontSize: 20,
                                      height: 1.45,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                SizedBox(height: compact ? 8 : 10),
                                _PermissionCard(
                                  title: 'Lokasi',
                                  detail: 'Untuk tahu air naik di dekat rumahmu dan rute evakuasi terdekat.',
                                  value: _locationSelected,

                                  onChanged: _handleLocationChanged,
                            
                                ),
                                const SizedBox(height: 14),
                                _PermissionCard(
                                  title: 'Notifikasi',
                                  detail: 'Untuk peringatan Waspada, Siaga, dan Awas, termasuk saat aplikasi tertutup.',
                                  value: _notificationsSelected,
                                  onChanged: _handleNotificationChanged,
                                ),
                                const SizedBox(height: 14),
                                _HomeLocationCard(
                                  address: _homeLocation.isNotEmpty
                                      ? _homeLocation
                                      : 'Masukkan alamat rumah Anda',
                                  onEdit: _editHomeLocation,
                                ),
                                SizedBox(height: compact ? 24 : 40),
                                DecoratedBox(
                                  key: const ValueKey(
                                    'welcome-continue-gradient',
                                  ),
                                  decoration: BoxDecoration(
                                    color: canContinue
                                        ? null
                                        : const Color(0xFFB9C8CC),
                                    gradient: canContinue
                                        ? const LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Color(0xFF0B2E3B),
                                              Color(0xFF2187A3),
                                            ],
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: SizedBox(
                                    height: 56,
                                    child: FilledButton(
                                      onPressed: canContinue && !_navigating
                                          ? _continue
                                          : null,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        disabledBackgroundColor:
                                            Colors.transparent,
                                        foregroundColor: Colors.white,
                                        disabledForegroundColor: Colors.white,
                                        shadowColor: Colors.transparent,
                                        shape: const StadiumBorder(),
                                        textStyle: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      child: const Text('Izinkan dan lanjut'),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed: _navigating ? null : _continue,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF0B2E3B),
                                      side: const BorderSide(
                                        color: Color(0xFF0B2E3B),
                                      ),
                                      shape: const StadiumBorder(),
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    child: const Text('Nanti saja'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 125,
    child: Container(
      padding: const EdgeInsets.fromLTRB(23, 12, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFE8ECEE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0B2E3B),
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: const Color(0xFF2EA361),
            onChanged: onChanged,
          ),
        ],
      ),
    ),
  );
}

class _HomeLocationCard extends StatelessWidget {
  const _HomeLocationCard({required this.address, required this.onEdit});

  final String address;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 124,
    child: Container(
      padding: const EdgeInsets.fromLTRB(23, 12, 18, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFE8ECEE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lokasi rumah',
            style: TextStyle(
              color: Color(0xFF0B2E3B),
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF808080), fontSize: 14.5),
          ),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.only(top: 1),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: const Color(0xFF0786A0),
            ),
            child: const Text(
              'Ubah',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
}
