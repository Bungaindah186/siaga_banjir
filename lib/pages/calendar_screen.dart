import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/location_service.dart';
import '../widgets/feature_page_shell.dart';
import '../widgets/reference_components.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({
    super.key,
    required this.account,
    required this.locationService,
  });

  final AuthenticatedUser account;
  final LocationService locationService;

  @override
  Widget build(BuildContext context) => FeaturePageShell(
    title: 'Kalender',
    account: account,
    locationService: locationService,
    activeTab: 'Home',
    child: ListView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 100),
      children: [
        const ReferenceCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.chevron_left_rounded),
                  Expanded(
                    child: Text(
                      'Kalender kesiapsiagaan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF0B2E3B),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
              SizedBox(height: 16),
              _WeekdayRow(),
              SizedBox(height: 8),
              _CalendarGrid(),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const ReferenceSectionHeading('Agenda'),
        const SizedBox(height: 8),
        const ReferenceCard(
          child: Text(
            'Belum ada agenda. Kalender belum terhubung ke jadwal peringatan.',
            style: TextStyle(color: Color(0xFF71808D), height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final day in const ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'])
        Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                color: Color(0xFF71808D),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
    ],
  );
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstWeekday = DateTime(now.year, now.month, 1).weekday % 7;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return Column(
      children: [
        for (var week = 0; week < 6; week++)
          Row(
            children: [
              for (var day = 0; day < 7; day++)
                Expanded(
                  child: SizedBox(
                    height: 43,
                    child: Center(
                      child: Builder(
                        builder: (context) {
                          final number = week * 7 + day - firstWeekday + 1;
                          if (number < 1 || number > daysInMonth) {
                            return const SizedBox.shrink();
                          }
                          final today = number == now.day;
                          return Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: today
                                ? const BoxDecoration(
                                    color: Color(0xFF12809A),
                                    shape: BoxShape.circle,
                                  )
                                : null,
                            child: Text(
                              '$number',
                              style: TextStyle(
                                color: today
                                    ? Colors.white
                                    : const Color(0xFF0B2E3B),
                                fontWeight: today
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
