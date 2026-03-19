class TrainingModel {
  final String id;
  final String title;
  final String instructor;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final double progress;
  final String type;
  final String location;
  final String category;
  final int durationHours;

  TrainingModel({
    required this.id,
    required this.title,
    required this.instructor,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.progress,
    required this.type,
    required this.location,
    required this.category,
    required this.durationHours,
  });

  factory TrainingModel.fromJson(Map<String, dynamic> json) {
    final startDate = _parseDate(
      json['starts_at'] ?? json['start_date'] ?? json['created_at'],
    );
    final parsedEndDate = _parseDate(
      json['ends_at'] ?? json['end_date'] ?? json['starts_at'],
    );
    final endDate = parsedEndDate.isBefore(startDate)
        ? startDate
        : parsedEndDate;
    final rawMode =
        json['delivery_mode']?.toString() ??
        json['type']?.toString() ??
        'online';
    final normalizedStatus = _normalizeStatus(
      json['status']?.toString(),
      startDate,
      endDate,
    );

    return TrainingModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      instructor:
          json['provider']?.toString() ??
          json['instructor']?.toString() ??
          'Internal Team',
      description: json['description']?.toString() ?? '',
      startDate: startDate,
      endDate: endDate,
      status: normalizedStatus,
      progress: _deriveProgress(
        normalizedStatus,
        startDate,
        endDate,
        json['progress'],
      ),
      type: _normalizeType(rawMode),
      location: _resolveLocation(rawMode),
      category: json['category']?.toString() ?? 'General',
      durationHours: _parseInt(json['duration_hours']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) {
      return DateTime.now();
    }

    return DateTime.tryParse(raw) ?? DateTime.now();
  }

  static String _normalizeStatus(
    String? rawStatus,
    DateTime startDate,
    DateTime endDate,
  ) {
    final status = rawStatus?.toLowerCase() ?? '';

    if (status == 'completed' || status == 'done') {
      return 'completed';
    }

    if (status == 'ongoing' || status == 'in_progress' || status == 'active') {
      return 'ongoing';
    }

    final now = DateTime.now();
    if (now.isAfter(endDate)) {
      return 'completed';
    }

    if (!now.isBefore(startDate) && !now.isAfter(endDate)) {
      return 'ongoing';
    }

    return 'upcoming';
  }

  static double _deriveProgress(
    String status,
    DateTime startDate,
    DateTime endDate,
    dynamic rawProgress,
  ) {
    if (rawProgress is num) {
      final parsed = rawProgress.toDouble();
      return parsed.clamp(0.0, 1.0);
    }

    if (status == 'completed') {
      return 1.0;
    }

    if (status == 'upcoming') {
      return 0.0;
    }

    final totalSeconds = endDate.difference(startDate).inSeconds;
    if (totalSeconds <= 0) {
      return 0.5;
    }

    final elapsedSeconds = DateTime.now().difference(startDate).inSeconds;
    return (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  static String _normalizeType(String rawMode) {
    final mode = rawMode.toLowerCase();
    if (mode.contains('offline') || mode.contains('onsite')) {
      return 'offline';
    }

    if (mode.contains('hybrid')) {
      return 'hybrid';
    }

    return 'online';
  }

  static String _resolveLocation(String rawMode) {
    final mode = rawMode.toLowerCase();
    if (mode.contains('offline') || mode.contains('onsite')) {
      return 'On site';
    }

    if (mode.contains('hybrid')) {
      return 'Hybrid session';
    }

    return 'Online session';
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
