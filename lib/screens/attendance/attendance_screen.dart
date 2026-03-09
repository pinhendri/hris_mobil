import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../data/models/attendance_model.dart';
import '../../widgets/loading_widget.dart';
import 'clock_in_screen.dart';
import '../../utils/debounce.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String? _employeeUuid;
  bool _isLoading = false;
  final Debouncer _debouncer = Debouncer(duration: const Duration(milliseconds: 500));
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(_handleTabChange);
    _scrollController.addListener(_handleScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debouncer.run(() {
        _loadInitialData();
      });
    });
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      // Reset scroll position when tab changes
      _scrollController.jumpTo(0);
    }
  }

  void _handleScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<AttendanceProvider>(context, listen: false);
      if (_tabController.index == 1 && !provider.isLoading && provider.currentPage < provider.lastPage) {
        provider.loadNextPage();
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _debouncer.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);

      _employeeUuid = authProvider.user?.employeeUuid ??
          authProvider.user?.uuid ??
          null;

      if (_employeeUuid != null) {
        if (mounted) {
          setState(() => _isLoading = true);
        }

        // Load data secara parallel
        await Future.wait([
          attendanceProvider.fetchAttendances(),
          attendanceProvider.getAttendanceSummary(),
        ]);

        if (mounted) {
          setState(() => _isLoading = false);
        }
      } else {
        print('Employee UUID not found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data karyawan tidak ditemukan'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('Error loading initial data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final todayAttendance = attendanceProvider.todayAttendance;
    final canClockIn = todayAttendance == null || !todayAttendance.hasClockIn;
    final canClockOut = todayAttendance != null && todayAttendance.hasClockIn && !todayAttendance.hasClockOut;

    // Loading state
    if (_isLoading || attendanceProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Attendance',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
        ),
        body: const LoadingWidget(message: 'Loading attendance data...'),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Attendance',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isDark ? Colors.blue.shade300 : Colors.blue,
          labelColor: isDark ? Colors.blue.shade300 : Colors.blue,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.grey.shade600,
          tabs: const [
            Tab(text: 'Today', icon: Icon(Icons.today)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Today Tab
          _buildTodayTab(context, isDark, attendanceProvider, authProvider, canClockIn, canClockOut),

          // History Tab
          _buildHistoryTab(context, isDark, attendanceProvider),
        ],
      ),
    );
  }

  // MARK: - Today Tab
  Widget _buildTodayTab(
      BuildContext context,
      bool isDark,
      AttendanceProvider provider,
      AuthProvider authProvider,
      bool canClockIn,
      bool canClockOut,
      ) {
    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Data',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.error!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.red.shade400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  provider.clearError();
                  _loadInitialData();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final todayAttendance = provider.todayAttendance;
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id').format(now);
    final formattedTime = DateFormat('HH:mm').format(now);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date & Time Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1A237E), const Color(0xFF311B92)]
                    : [Colors.blue.shade400, Colors.blue.shade700],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.access_time,
                  size: 48,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(height: 12),
                Text(
                  formattedTime,
                  style: GoogleFonts.poppins(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Status Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Status',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatusItem(
                        'Clock In',
                        todayAttendance?.clockInTimeFormatted ?? '-',
                        Icons.login,
                        todayAttendance?.hasClockIn ?? false ? Colors.green : Colors.grey,
                        isDark,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                    Expanded(
                      child: _buildStatusItem(
                        'Clock Out',
                        todayAttendance?.clockOutTimeFormatted ?? '-',
                        Icons.logout,
                        todayAttendance?.hasClockOut ?? false ? Colors.green : Colors.grey,
                        isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          if (canClockIn)
            _buildClockInButton(context, isDark, provider, authProvider),

          if (canClockOut)
            _buildClockOutButton(context, isDark, provider, authProvider),

          if (!canClockIn && !canClockOut)
            _buildCompletedCard(isDark),

          const SizedBox(height: 24),

          // Location Info (if available)
          if (todayAttendance != null && todayAttendance.clockInLocation != null)
            _buildLocationCard(isDark, todayAttendance!),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildClockInButton(
      BuildContext context,
      bool isDark,
      AttendanceProvider provider,
      AuthProvider authProvider,
      ) {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: provider.isClockingIn ? null : () => _handleClockIn(context, provider, authProvider),
        icon: provider.isClockingIn
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.login),
        label: Text(
          provider.isClockingIn ? 'Processing...' : 'Clock In',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildClockOutButton(
      BuildContext context,
      bool isDark,
      AttendanceProvider provider,
      AuthProvider authProvider,
      ) {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: provider.isClockingOut ? null : () => _handleClockOut(context, provider, authProvider),
        icon: provider.isClockingOut
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Icon(Icons.logout),
        label: Text(
          provider.isClockingOut ? 'Processing...' : 'Clock Out',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildCompletedCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Completed',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You have completed your attendance for today',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(bool isDark, Attendance attendance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: isDark ? Colors.blue.shade300 : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                'Location',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            attendance.clockInLocation ?? 'No location recorded',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - History Tab
  Widget _buildHistoryTab(BuildContext context, bool isDark, AttendanceProvider provider) {
    if (provider.attendances.isEmpty && !provider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No Attendance History',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your attendance records will appear here',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!provider.isLoading &&
            provider.currentPage < provider.lastPage &&
            scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.8) {
          provider.loadNextPage();
        }
        return true;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: provider.attendances.length + (provider.isLoading ? 1 : 0),
        cacheExtent: 500,
        itemBuilder: (context, index) {
          if (index == provider.attendances.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final attendance = provider.attendances[index];
          return _buildHistoryItem(attendance, isDark);
        },
      ),
    );
  }

  Widget _buildHistoryItem(Attendance attendance, bool isDark) {
    final date = DateTime.parse(attendance.date);
    final formattedDate = DateFormat('dd MMM yyyy', 'id').format(date);
    final dayName = DateFormat('EEEE', 'id').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date indicator
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: attendance.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  date.day.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: attendance.statusColor,
                  ),
                ),
                Text(
                  DateFormat('MMM', 'id').format(date),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: attendance.statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.login,
                      size: 12,
                      color: attendance.hasClockIn ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      attendance.clockInTimeFormatted,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.logout,
                      size: 12,
                      color: attendance.hasClockOut ? Colors.orange : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      attendance.clockOutTimeFormatted,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: attendance.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              attendance.statusBadge,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: attendance.statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Handlers
  Future<void> _handleClockIn(
      BuildContext context,
      AttendanceProvider provider,
      AuthProvider authProvider,
      ) async {
    if (_employeeUuid == null) {
      _showErrorSnackBar('Data karyawan tidak ditemukan');
      return;
    }

    // Navigasi ke ClockInScreen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClockInScreen(),
      ),
    );

    // Setelah kembali dari ClockInScreen, refresh data
    if (result == true && mounted) {
      await provider.refreshData();
      _showSuccessSnackBar('Clock in berhasil');
    }
  }

  Future<void> _handleClockOut(
      BuildContext context,
      AttendanceProvider provider,
      AuthProvider authProvider,
      ) async {
    if (_employeeUuid == null) {
      _showErrorSnackBar('Data karyawan tidak ditemukan');
      return;
    }

    final success = await provider.clockOut(
      employeeUuid: _employeeUuid!,
    );

    if (success && mounted) {
      _showSuccessSnackBar('Clock out berhasil');
    } else if (mounted && provider.error != null) {
      _showErrorSnackBar(provider.error!);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}