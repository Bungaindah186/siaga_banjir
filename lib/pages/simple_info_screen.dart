import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/location_service.dart';
import '../widgets/feature_page_shell.dart';
import '../widgets/reference_components.dart';

class SimpleInfoScreen extends StatelessWidget {
  const SimpleInfoScreen({
    super.key,
    required this.title,
    required this.detail,
    required this.account,
    required this.locationService,
  });

  final String title;
  final String detail;
  final AuthenticatedUser account;
  final LocationService locationService;

  @override
  Widget build(BuildContext context) => FeaturePageShell(
    title: title,
    account: account,
    locationService: locationService,
    activeTab: 'Home',
    child: ListView(
      padding: const EdgeInsets.all(22),
      children: [
        ReferenceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0B2E3B),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(detail, style: const TextStyle(height: 1.45)),
            ],
          ),
        ),
      ],
    ),
  );
}
