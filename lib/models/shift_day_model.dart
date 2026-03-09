// lib/models/shift_day_model.dart

class ShiftDay {
  final String id;
  final String shiftId;
  final int dayOfWeek; // 1: Monday, 2: Tuesday, ..., 7: Sunday
  final String dayOfWeekString; // 'Mon', 'Tue', etc.
  final String clockIn;
  final String clockOut;
  final int breakMinutes;

  ShiftDay({
    required this.id,
    required this.shiftId,
    required this.dayOfWeek,
    required this.dayOfWeekString,
    required this.clockIn,
    required this.clockOut,
    required this.breakMinutes,
  });

  factory ShiftDay.fromJson(Map<String, dynamic> json) {
    return ShiftDay(
      id: json['id']?.toString() ?? '',
      shiftId: json['shift_id']?.toString() ?? '',
      dayOfWeek: json['day_of_week'] ?? 1,
      dayOfWeekString: json['day_of_week'] ?? 'Mon',
      clockIn: json['clock_in'] ?? '08:00',
      clockOut: json['clock_out'] ?? '17:00',
      breakMinutes: json['break_minutes'] ?? 60,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shift_id': shiftId,
      'day_of_week': dayOfWeekString, // Kirim string ke API
      'clock_in': clockIn,
      'clock_out': clockOut,
      'break_minutes': breakMinutes,
    };
  }

  ShiftDay copyWith({
    String? id,
    String? shiftId,
    int? dayOfWeek,
    String? dayOfWeekString,
    String? clockIn,
    String? clockOut,
    int? breakMinutes,
  }) {
    return ShiftDay(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayOfWeekString: dayOfWeekString ?? this.dayOfWeekString,
      clockIn: clockIn ?? this.clockIn,
      clockOut: clockOut ?? this.clockOut,
      breakMinutes: breakMinutes ?? this.breakMinutes,
    );
  }
}