class Metric {
  final String title;
  final String value;
  final String change;
  final String trend;

  Metric({
    required this.title,
    required this.value,
    required this.change,
    required this.trend,
  });
}

class DepartmentStat {
  final String name;
  final int employees;

  DepartmentStat({required this.name, required this.employees});
}

class RecentActivity {
  final String name;
  final String description;
  final DateTime createdAt;

  RecentActivity({
    required this.name,
    required this.description,
    required this.createdAt,
  });
}

class DashboardModel {
  final int totalEmployees;
  final int attendanceToday;
  final int leaveBalance;

  final List<Metric> metrics;
  final List<RecentActivity> recentActivities;
  final List<DepartmentStat> departmentStats;

  DashboardModel({
    required this.totalEmployees,
    required this.attendanceToday,
    required this.leaveBalance,
    this.metrics = const [],
    this.recentActivities = const [],
    this.departmentStats = const [],
  });
}