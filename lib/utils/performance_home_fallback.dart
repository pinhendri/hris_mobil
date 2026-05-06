import '../models/performance_model.dart';

PerformanceHistoryModel? selectDisplayHistoryEntry(
  List<PerformanceHistoryModel> history, {
  required String selectedPeriod,
}) {
  if (history.isEmpty) {
    return null;
  }

  for (final item in history) {
    if (item.period == selectedPeriod) {
      return item;
    }
  }

  final sorted = [...history];
  sorted.sort((left, right) => right.period.compareTo(left.period));
  return sorted.first;
}

List<PerformanceHistoryModel> extractEmployeeHistoryFromEvaluationList(
  dynamic response, {
  required int employeeId,
}) {
  final items = _extractList(response);
  final history = <PerformanceHistoryModel>[];

  for (final rawItem in items.whereType<Map>()) {
    final item = Map<String, dynamic>.from(rawItem);
    if (!_matchesEmployee(item, employeeId)) {
      continue;
    }

    final period = _readString(item, const ['period']);
    final score = _readDouble(item['final_score'] ?? item['finalScore']);
    if (period.isEmpty) {
      continue;
    }

    history.add(
      PerformanceHistoryModel(
        period: period,
        finalScore: score,
        grade: _readString(item, const ['grade']),
        isLocked: _readBool(item['is_locked'] ?? item['isLocked']),
      ),
    );
  }

  final unique = <String, PerformanceHistoryModel>{};
  for (final item in history) {
    final existing = unique[item.period];
    if (existing == null || item.finalScore != 0) {
      unique[item.period] = item;
    }
  }

  final sorted = unique.values.toList(growable: false);
  sorted.sort((left, right) => right.period.compareTo(left.period));
  return sorted;
}

List<dynamic> _extractList(dynamic response) {
  if (response is List) {
    return response;
  }

  if (response is! Map) {
    return const <dynamic>[];
  }

  final map = Map<String, dynamic>.from(response);
  for (final key in const ['data', 'evaluations', 'history', 'items']) {
    final value = map[key];
    if (value is List) {
      return value;
    }

    if (value is Map) {
      final nested = Map<String, dynamic>.from(value);
      final nestedData = nested['data'];
      if (nestedData is List) {
        return nestedData;
      }
    }
  }

  return const <dynamic>[];
}

bool _matchesEmployee(Map<String, dynamic> item, int employeeId) {
  final ids = <dynamic>[
    item['employee_id'],
    item['employeeId'],
    item['id_employee'],
  ];

  final employee = item['employee'];
  if (employee is Map) {
    ids.addAll([
      employee['id'],
      employee['employee_id'],
      employee['employeeId'],
    ]);
  }

  return ids.any((value) => _readInt(value) == employeeId);
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    final normalized = value?.toString().trim() ?? '';
    if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
      return normalized;
    }
  }

  return '';
}

double _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

int _readInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.round();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _readBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  final normalized = value?.toString().trim().toLowerCase() ?? '';
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}
