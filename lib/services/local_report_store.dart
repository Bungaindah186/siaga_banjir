import 'package:flutter/foundation.dart';

/// Session-only report drafts. These are not transmitted or officially received.
class LocalReportStore extends ChangeNotifier {
  LocalReportStore._();

  static final LocalReportStore instance = LocalReportStore._();
  final List<LocalIncidentReport> _reports = [];
  List<LocalIncidentReport> get reports => List.unmodifiable(_reports);

  void add(LocalIncidentReport report) {
    _reports.insert(0, report);
    notifyListeners();
  }
}

class LocalIncidentReport {
  const LocalIncidentReport({
    required this.type,
    required this.location,
    required this.description,
    required this.createdAt,
    this.eventTime,
    this.waterLevel,
  });

  final String type;
  final String location;
  final String description;
  final DateTime createdAt;
  final String? eventTime;
  final String? waterLevel;
}
