class ApiConstants {
  // ===============================
  // 🌐 BASE URL
  // ===============================

  /// Set with:
  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
  /// flutter run --dart-define=API_BASE_URL=http://113.11.129.46
  /// flutter build apk --dart-define=API_BASE_URL=https://api.example.com
  static const bool _isReleaseBuild = bool.fromEnvironment('dart.vm.product');
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String baseUrl = _configuredBaseUrl == ''
      ? (_isReleaseBuild ? 'http://113.11.129.46' : 'http://10.0.2.2:8000')
      : _configuredBaseUrl;

  /// Kalau pakai HP asli:
  /// ganti dengan IP laptop kamu
  /// contoh:
  /// static const String baseUrl = 'http://192.168.1.10:8000';

  // ===============================
  // 🔐 AUTH
  // ===============================

  static const String loginEndpoint = '/api/login';
  static const String meEndpoint = '/api/me';
  static const String meEmployeeEndpoint = '/api/me/employee';
  static const String setSelectedCompanyEndpoint = '/api/set-selected-company';
  static const String updateProfileEndpoint = '/api/me/update';
  static const String changePasswordEndpoint = '/api/change-password';
  static const String logoutEndpoint = '/api/logout';
  static const String getUserInfoEndpoint = meEndpoint;
  static const String saasContextEndpoint = '/api/saas/context';
  static const String saasTrialStatusEndpoint = '/api/saas/trial-status';
  static const String saasCompaniesEndpoint = '/api/saas/companies';
  static const String saasInvitationsEndpoint = '/api/saas/invitations';
  static const String saasAdminOverviewEndpoint = '/api/saas/admin/overview';
  static const String settingsEndpoint = '/api/settings';
  static const String entitiesEndpoint = '/api/entities';
  static const String activeDefaultEntityEndpoint =
      '/api/entities/default/active';
  static const String openStreetMapTilesEndpoint =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String mapTilesEndpoint = '/map-tile-cache/{z}/{x}/{y}.png';
  static const String mapTilesProxyEndpoint = '/map-tile.php?z={z}&x={x}&y={y}';

  static const String attendanceTodayEndpoint = '/api/attendances?today=true';
  static const String leaveTodayEndpoint =
      '/api/leave-requests?status=approved&today=true';

  // ===============================
  // 🔔 NOTIFICATIONS
  // ===============================

  static const String notificationsEndpoint = '/api/notifications';
  static const String notificationReadEndpoint =
      '/api/notifications'; // + /{id}/read

  // ===============================
  // 📊 DASHBOARD (yang akan kita pakai)
  // ===============================

  static const String totalEmployeesEndpoint = '/api/employees/total';
  static const String attendanceDailyEndpoint = '/api/attendances/daily-report';
  static const String leaveBalanceEndpoint = '/api/leave-balance';

  // ===============================
  // 👥 EMPLOYEES
  // ===============================

  static const String employeesEndpoint = '/api/employees';
  static const String employeesListEndpoint = '/api/employees/list';

  // ===============================
  // 📝 ATTENDANCE - TAMBAHKAN INI
  // ===============================

  static const String attendanceEndpoint =
      '/api/attendances'; // UNTUK MENDAPATKAN DATA ABSENSI
  static const String clockInEndpoint =
      '/api/attendances/clock-in'; // UNTUK CLOCK IN
  static const String clockOutEndpoint =
      '/api/attendances/clock-out'; // UNTUK CLOCK OUT
  static const String dailyReportEndpoint =
      '/api/attendances/daily-report'; // UNTUK LAPORAN HARIAN
  static const String attendanceSummaryEndpoint =
      '/api/attendances/summary'; // UNTUK RINGKASAN
  static const String attendanceHistoryEndpoint =
      '/api/attendances/history'; // UNTUK RIWAYAT
  static const String attendanceCorrectionEndpoint =
      '/api/attendances/correction'; // UNTUK KOREKSI

  // ===============================
  // 🏝️ LEAVE
  // ===============================

  static const String leaveRequestsEndpoint = '/api/leave-requests';
  static const String leaveCalendarEndpoint = '/api/calendar';

  // ===============================
  // 💰 PAYROLL
  // ===============================

  static const String payrollEndpoint = '/api/payroll';
  static const String payslipEndpoint = '/api/payroll';
  static const String performanceKpiAssignmentsEndpoint =
      '/api/kpi/evaluation/employee'; // + /{employeeId}/kpi
  static const String performanceEmployeeAssignmentsEndpoint =
      '/api/kpi/employee-kpi'; // + /{employeeId}
  static const String performanceEvaluationCheckEndpoint =
      '/api/kpi/evaluation/check-existing';
  static const String legacyPerformanceEvaluationCheckEndpoint =
      '/api/kpi/kpi/evaluation/check-existing';
  static const String performanceEvaluationDetailEndpoint =
      '/api/kpi/evaluation/get-detail';
  static const String legacyPerformanceEvaluationDetailEndpoint =
      '/api/kpi/kpi/evaluation/get-detail';
  static const String performanceEvaluationHistoryEndpoint =
      '/api/kpi/evaluation/employee'; // + /{employeeId}/history
  static const String legacyPerformanceEvaluationHistoryEndpoint =
      '/api/kpi/evaluation/history'; // + /{employeeId}
  static const String performanceEvaluationListEndpoint =
      '/api/kpi/evaluation/list';

  // ===============================
  // 📄 DOCUMENTS
  // ===============================

  static const String documentsEndpoint = '/api/documents';
  static const String tasksEndpoint = '/api/tasks';
  static const String taskStatusEndpoint = '/api/tasks'; // + /{id}/status

  // ===============================
  // 🧩 RECRUITMENT
  // ===============================

  static const String recruitmentEndpoint = '/api/recruitment';

  // ===============================
  // 📦 INVENTORY
  // ===============================

  static const String inventoriesEndpoint = '/api/inventories';
}
