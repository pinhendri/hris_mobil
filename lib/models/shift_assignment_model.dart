class ShiftAssignment {
  final String id;
  final String shiftId;
  final List<String> employeeIds;
  final List<String> departmentIds;
  final String startDate;
  final String? endDate;
  final bool active;
  final String createdAt;

  ShiftAssignment({
    required this.id,
    required this.shiftId,
    required this.employeeIds,
    required this.departmentIds,
    required this.startDate,
    this.endDate,
    this.active = true,
    required this.createdAt,
  });

  ShiftAssignment copyWith({
    String? id,
    String? shiftId,
    List<String>? employeeIds,
    List<String>? departmentIds,
    String? startDate,
    String? endDate,
    bool? active,
    String? createdAt,
  }) {
    return ShiftAssignment(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      employeeIds: employeeIds ?? this.employeeIds,
      departmentIds: departmentIds ?? this.departmentIds,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
