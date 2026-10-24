import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../widgets/field_label.dart';
import '../widgets/flood_house_mark.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.account});

  final AuthenticatedUser account;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _homeLocationController = TextEditingController();
  bool _continued = false;

  @override
  void dispose() {
    _homeLocationController.dispose();
    super.dispose();
  }

  void _continue({required bool requestSetup}) {
    FocusScope.of(context).unfocus();
    setState(() => _continued = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          requestSetup
              ? 'Pilihan dicatat. Permintaan izin perangkat belum dihubungkan.'
              : 'Kamu dapat mengatur izin nanti di pengaturan perangkat.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      colors: [AppColors.navy, AppColors.navyLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const FloodHouseMark(size: 66, light: true),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selamat datang,',
                              style: TextStyle(color: Color(0xFFCAE3EA)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.account.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Atur kesiapan awal',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pengaturan ini membantu menyesuaikan informasi untuk rumahmu. Semua langkah bisa dilewati.',
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 20),
                const _SetupCard(
                  icon: Icons.location_on_outlined,
                  title: 'Izin lokasi',
                  detail: 'Lokasi perangkat dapat membantu menampilkan informasi sekitar.',
                ),
                const SizedBox(height: 12),
                const _SetupCard(
                  icon: Icons.notifications_none_rounded,
                  title: 'Izin notifikasi',
                  detail: 'Notifikasi dapat memberi tahu saat ada informasi kesiapsiagaan.',
                ),
                const SizedBox(height: 20),
                const FieldLabel('Lokasi rumah (opsional)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _homeLocationController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Kecamatan Padang Barat',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                _PrimaryButton(
                  label: _continued
                      ? 'Pengaturan awal selesai'
                      : 'Izinkan dan lanjut',
                  onPressed: _continued
                      ? null
                      : () => _continue(requestSetup: true),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _continued
                      ? null
                      : () => _continue(requestSetup: false),
                  child: const Text(
                    'Nanti saja',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_continued)
                  const _SessionNotice()
                else
                  const Text(
                    'Izin lokasi dan notifikasi belum dihubungkan ke permintaan izin Android.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.4,
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

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EDF0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.tealPale,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.teal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppColors.muted,
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 54,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFABC9C8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
      child: Text(label),
    ),
  );
}

class _SessionNotice extends StatelessWidget {
  const _SessionNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF6E5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFF2E1BC)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF8A641C)),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            'Mode UI: akun hanya tersedia selama aplikasi terbuka. Backend belum terhubung.',
            style: TextStyle(
              color: Color(0xFF75591F),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}
