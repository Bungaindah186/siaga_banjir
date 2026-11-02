import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_client.dart';
import '../services/location_service.dart';
import '../widgets/feature_page_shell.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({
    super.key,
    required this.account,
    required this.locationService,
  });

  final AuthenticatedUser account;
  final LocationService locationService;
  Future<void> _callContact(BuildContext context, String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      final opened = await launchUrl(uri);

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka aplikasi Telepon.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka aplikasi Telepon.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => FeaturePageShell(
    title: 'Kontak Darurat',
    account: account,
    locationService: locationService,
    activeTab: 'Kontak',
    child: ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 22, 100),
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 6, bottom: 13),
          child: Text(
            'Layanan Resmi',
            style: TextStyle(color: Color(0xFF355C69)),
          ),
        ),
        _ContactCard(
          title: 'BPBD Kota Padang',
          subtitle: 'Bencana',
          onTap: () => _callContact(context, '0751778775'),
        ),
        const SizedBox(height: 10),
        _ContactCard(
          title: 'Damkar',
          subtitle: 'Pemadam',
          onTap: () => _callContact(context, '08116606113'),
        ),
        const SizedBox(height: 10),
        _ContactCard(
          title: 'PMI',
          subtitle: 'P3K',
          onTap: () => _callContact(context, '08126040801'),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(6, 18, 6, 13),
          child: Text(
            'Posko Terdekat • contoh',
            style: TextStyle(color: Color(0xFF355C69)),
          ),
        ),
        _ContactCard(
          title: 'Posko Tunggul Hitam',
          subtitle: 'Jarak belum diverifikasi',
          onTap: () {},
          isAvailable: false,
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8, right: 95),
          child: Text(
            'Daftar layanan dan jarak hanya contoh. Pastikan nomor resmi tersedia sebelum digunakan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF71808D),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isAvailable = true,
  });
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isAvailable;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(17),
    elevation: 2,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF1585A0), Color(0xFF0B2E3B)],
                ),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(subtitle),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: isAvailable ? onTap : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2EA361),
                disabledBackgroundColor: Colors.grey.shade400,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              icon: Icon(
                isAvailable
                    ? Icons.phone_in_talk_rounded
                    : Icons.phone_disabled_rounded,
                size: 17,
              ),
              label: Text(isAvailable ? 'Call' : 'Belum tersedia'),
            ),
          ],
        ),
      ),
    ),
  );
}
