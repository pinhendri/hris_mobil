class DashboardData {
  final int totalEmployees;
  final int attendanceToday;
  final int leaveBalance;

  DashboardData({
    required this.totalEmployees,
    required this.attendanceToday,
    required this.leaveBalance,
  });

  /// 🔥 INI YANG KEMARIN MERAH
  factory DashboardData.fromMultipleApi({
    required dynamic totalEmployees,
    required dynamic attendance,
    required dynamic leaveBalance,
  }) {
    return DashboardData(
      totalEmployees: totalEmployees?['total'] ?? 0,
      attendanceToday: attendance?['present'] ?? 0,
      leaveBalance: leaveBalance?['remaining'] ?? 0,
    );
  }
}
