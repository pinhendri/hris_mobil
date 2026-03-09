// lib/models/shift_model.dart

import 'shift_day_model.dart';

class Shift {
  final String id;
  final String name;
  final String? description;
  final String startTime;
  final String endTime;
  final int breakMinutes;
  final int graceClockIn;
  final int graceClockOut;
  final bool isNightShift;
  final bool isFlexible;
  final bool isActive;
  final List<ShiftDay> shiftDays; // Tambahkan ini

  Shift({
    required this.id,
    required this.name,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.breakMinutes,
    required this.graceClockIn,
    required this.graceClockOut,
    required this.isNightShift,
    required this.isFlexible,
    required this.isActive,
    this.shiftDays = const [], // Default empty list
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    // Parse shift days if available
    List<ShiftDay> shiftDays = [];
    if (json['shift_days'] != null && json['shift_days'] is List) {
      shiftDays = (json['shift_days'] as List)
          .map((dayJson) => ShiftDay.fromJson(dayJson))
          .toList();
    }

    return Shift(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      startTime: json['clock_in']?.toString() ?? '',
      endTime: json['clock_out']?.toString() ?? '',
      breakMinutes: json['break_minutes'] ?? 60,
      graceClockIn: json['grace_clock_in'] ?? 0,
      graceClockOut: json['grace_clock_out'] ?? 0,
      isNightShift: json['is_night_shift'] ?? false,
      isFlexible: json['is_flexible'] ?? false,
      isActive: json['is_active'] ?? true,
      shiftDays: shiftDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'clock_in': startTime,
      'clock_out': endTime,
      'break_minutes': breakMinutes,
      'grace_clock_in': graceClockIn,
      'grace_clock_out': graceClockOut,
      'is_night_shift': isNightShift,
      'is_flexible': isFlexible,
      'is_active': isActive,
      'shift_days': shiftDays.map((day) => day.toJson()).toList(),
    };
  }

  Shift copyWith({
    String? id,
    String? name,
    String? description,
    String? startTime,
    String? endTime,
    int? breakMinutes,
    int? graceClockIn,
    int? graceClockOut,
    bool? isNightShift,
    bool? isFlexible,
    bool? isActive,
    List<ShiftDay>? shiftDays,
  }) {
    return Shift(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      graceClockIn: graceClockIn ?? this.graceClockIn,
      graceClockOut: graceClockOut ?? this.graceClockOut,
      isNightShift: isNightShift ?? this.isNightShift,
      isFlexible: isFlexible ?? this.isFlexible,
      isActive: isActive ?? this.isActive,
      shiftDays: shiftDays ?? this.shiftDays,
    );
  }
}