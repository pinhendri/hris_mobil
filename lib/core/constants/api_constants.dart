class ApiConstants {
  // ===============================
  // 🌐 BASE URL
  // ===============================

  /// Android Emulator
  static const String baseUrl = 'http://10.0.2.2:8000';

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
  static const String getUserInfoEndpoint = '/me';

      static const String attendanceTodayEndpoint = '/attendances?today=true';
        static const String leaveTodayEndpoint = '/leave-requests?status=approved&today=true';

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

  static const String attendanceEndpoint = '/api/attendances';          // UNTUK MENDAPATKAN DATA ABSENSI
  static const String clockInEndpoint = '/api/attendances/clock-in';     // UNTUK CLOCK IN
  static const String clockOutEndpoint = '/api/attendances/clock-out';   // UNTUK CLOCK OUT
  static const String dailyReportEndpoint = '/api/attendances/daily-report'; // UNTUK LAPORAN HARIAN
  static const String attendanceSummaryEndpoint = '/api/attendances/summary'; // UNTUK RINGKASAN
  static const String attendanceHistoryEndpoint = '/api/attendances/history'; // UNTUK RIWAYAT
  static const String attendanceCorrectionEndpoint = '/api/attendances/correction'; // UNTUK KOREKSI


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

  // ===============================
  // 📄 DOCUMENTS
  // ===============================

  static const String documentsEndpoint = '/api/documents';

  // ===============================
  // 🧩 RECRUITMENT
  // ===============================

  static const String recruitmentEndpoint = '/api/recruitment';

  // ===============================
  // 📦 INVENTORY
  // ===============================

  static const String inventoriesEndpoint = '/api/inventories';
}
