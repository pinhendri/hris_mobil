import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../data/models/attendance_model.dart';
import '../../widgets/loading_widget.dart';
import 'clock_in_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  static const int _historyWindowDays = 30;
  late TabController _tabController;
  String? _employeeUuid;
  String _currentCompanyCode = '';
  bool _isInitialized = false; // Flag untuk menandai sudah diinisialisasi
  bool _isTodayTabLoading = false;
  bool _isHistoryTabLoading = false;
  bool _isHistoryLoadingMore = false;
  int _todayLoadSequence = 0;
  int _historyLoadSequence = 0;
  int _initialLoadSequence = 0;
  String? _todayError;
  String? _historyError;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _scrollController.addListener(_handleScroll);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _scrollController.jumpTo(0);
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _tabController.index != 1) {
      return;
    }

    if (_isHistoryTabLoading || _isHistoryLoadingMore) {
      return;
    }

    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) {
      return;
    }

    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (provider.currentPage < provider.lastPage) {
        unawaited(
          _loadHistoryData(attendanceProvider: provider, loadNextPage: true),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    final activeCompanyCode = authProvider.getCompanyCode().trim();

    // Load ulang saat company aktif berubah
    if (!_isInitialized || _currentCompanyCode != activeCompanyCode) {
      _currentCompanyCode = activeCompanyCode;
      _loadInitialData();
      _isInitialized = true;
    }
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    final loadSequence = ++_initialLoadSequence;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(
        context,
        listen: false,
      );

      attendanceProvider.clearError();
      if (mounted) {
        setState(() {
          _todayError = null;
          _historyError = null;
          _isTodayTabLoading = true;
          if (attendanceProvider.attendances.isEmpty) {
            _isHistoryTabLoading = true;
          }
        });
      }

      await attendanceProvider.ensureReady();
      if (!mounted || loadSequence != _initialLoadSequence) {
        return;
      }

      _employeeUuid = await attendanceProvider.resolveCurrentEmployeeUuid();
      if (!mounted || loadSequence != _initialLoadSequence) {
        return;
      }

      _currentCompanyCode = authProvider.getCompanyCode().trim();

      if (_employeeUuid != null && _employeeUuid!.isNotEmpty) {
        await _loadTodayData(attendanceProvider);
        if (mounted && loadSequence == _initialLoadSequence) {
          unawaited(_loadHistoryData(attendanceProvider: attendanceProvider));
        }
      } else {
        print('Employee UUID not found');
        if (mounted && loadSequence == _initialLoadSequence) {
          setState(() {
            _isTodayTabLoading = false;
            _isHistoryTabLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading initial data: $e');
      if (mounted && loadSequence == _initialLoadSequence) {
        setState(() {
          _todayError = 'Gagal memuat data attendance.';
          _historyError = 'Gagal memuat data attendance.';
          _isTodayTabLoading = false;
          _isHistoryTabLoading = false;
        });
      }
    }
  }

  Future<void> _loadTodayData(AttendanceProvider attendanceProvider) async {
    final loadSequence = ++_todayLoadSequence;

    if (mounted) {
      setState(() {
        _isTodayTabLoading = true;
        _todayError = null;
      });
    }

    try {
      await Future.wait([
        attendanceProvider.fetchTodayAttendance(),
        attendanceProvider.getAttendanceSummary(),
      ]);
    } catch (e) {
      if (mounted && loadSequence == _todayLoadSequence) {
        setState(() {
          _todayError = 'Gagal memuat status attendance hari ini.';
        });
      }
    } finally {
      if (mounted && loadSequence == _todayLoadSequence) {
        setState(() {
          _isTodayTabLoading = false;
        });
      }
    }
  }

  Future<void> _loadHistoryData({
    required AttendanceProvider attendanceProvider,
    bool loadNextPage = false,
  }) async {
    if (loadNextPage) {
      if (_isHistoryTabLoading ||
          _isHistoryLoadingMore ||
          attendanceProvider.currentPage >= attendanceProvider.lastPage) {
        return;
      }

      if (mounted) {
        setState(() {
          _isHistoryLoadingMore = true;
        });
      }

      try {
        await attendanceProvider.loadNextPage();
      } finally {
        if (mounted) {
          setState(() {
            _isHistoryLoadingMore = false;
          });
        }
      }
      return;
    }

    final loadSequence = ++_historyLoadSequence;

    if (mounted) {
      setState(() {
        _isHistoryTabLoading = true;
        _historyError = null;
      });
    }

    try {
      attendanceProvider.clearError();
      await attendanceProvider.fetchAttendances();
      final resolvedError = attendanceProvider.attendances.isEmpty
          ? attendanceProvider.error
          : null;
      if (mounted && loadSequence == _historyLoadSequence) {
        setState(() {
          _historyError = resolvedError;
        });
      }
    } catch (e) {
      if (mounted && loadSequence == _historyLoadSequence) {
        setState(() {
          _historyError = 'Gagal memuat riwayat attendance.';
        });
      }
    } finally {
      if (mounted && loadSequence == _historyLoadSequence) {
        setState(() {
          _isHistoryTabLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final hasEmployeeId = _employeeUuid?.isNotEmpty ?? false;

    final todayAttendance = attendanceProvider.todayAttendance;
    final canClockIn =
        hasEmployeeId &&
        (todayAttendance == null || !todayAttendance.hasClockIn);
    final canClockOut =
        hasEmployeeId &&
        todayAttendance != null &&
        todayAttendance.hasClockIn &&
        !todayAttendance.hasClockOut;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Attendance',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
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
          _buildTodayTab(
            context,
            isDark,
            attendanceProvider,
            hasEmployeeId,
            canClockIn,
            canClockOut,
          ),

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
    bool hasEmployeeId,
    bool canClockIn,
    bool canClockOut,
  ) {
    if (_isTodayTabLoading && provider.todayAttendance == null) {
      return const LoadingWidget(message: 'Loading attendance data...');
    }

    if (!_isTodayTabLoading &&
        _todayError != null &&
        provider.todayAttendance == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
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
                _todayError!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.red.shade400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _todayError = null;
                    _historyError = null;
                  });
                  provider.clearError();
                  _loadInitialData();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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

          if (provider.syncNotice != null) ...[
            _buildSyncNoticeCard(context, isDark, provider),
            const SizedBox(height: 24),
          ],

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
                        todayAttendance?.hasClockIn ?? false
                            ? Colors.green
                            : Colors.grey,
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
                        todayAttendance?.hasClockOut ?? false
                            ? Colors.green
                            : Colors.grey,
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
          if (!hasEmployeeId) _buildMissingEmployeeCard(isDark),

          if (canClockIn) _buildClockInButton(context, provider),

          if (canClockOut) _buildClockOutButton(context, provider),

          if (hasEmployeeId && !canClockIn && !canClockOut)
            _buildCompletedCard(isDark, todayAttendance),

          const SizedBox(height: 24),

          // Location Info (if available)
          if (todayAttendance != null &&
              todayAttendance.clockInLocation != null)
            _buildLocationCard(isDark, todayAttendance),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
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
    AttendanceProvider provider,
  ) {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: provider.isClockingIn ? null : () => _handleClockIn(context),
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
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildMissingEmployeeCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x33F59E0B) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined, color: Color(0xFFF59E0B)),
              const SizedBox(width: 10),
              Text(
                'Employee ID Belum Tersedia',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Clock in dan clock out tidak bisa dilakukan sampai akun ini memiliki employee ID.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockOutButton(
    BuildContext context,
    AttendanceProvider provider,
  ) {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: provider.isClockingOut
            ? null
            : () => _handleClockOut(context),
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
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildCompletedCard(bool isDark, Attendance? attendance) {
    final hasClockIn = attendance?.hasClockIn == true;
    final hasClockOut = attendance?.hasClockOut == true;
    final detailText = hasClockIn && hasClockOut
        ? 'Clock In ${attendance!.clockInTimeFormatted} • Clock Out ${attendance.clockOutTimeFormatted}'
        : hasClockIn
        ? 'Clock In ${attendance!.clockInTimeFormatted}'
        : 'You have completed your attendance for today';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
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
                  detailText,
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
  Widget _buildHistoryTab(
    BuildContext context,
    bool isDark,
    AttendanceProvider provider,
  ) {
    final historyItems = _buildHistoryWindow(provider.attendances);

    if (_isHistoryTabLoading && provider.attendances.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isHistoryTabLoading &&
        _historyError != null &&
        provider.attendances.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off, size: 56, color: Colors.red[300]),
              const SizedBox(height: 14),
              Text(
                'Riwayat attendance belum berhasil dimuat',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _historyError!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _historyError = null;
                  });
                  _loadHistoryData(attendanceProvider: provider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Muat Ulang History'),
              ),
            ],
          ),
        ),
      );
    }

    if (historyItems.isEmpty && !_isHistoryTabLoading) {
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

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: historyItems.length + (_isHistoryLoadingMore ? 1 : 0),
      cacheExtent: 500,
      itemBuilder: (context, index) {
        if (index == historyItems.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final attendance = historyItems[index];
        return _buildHistoryItem(attendance, isDark);
      },
    );
  }

  List<Attendance> _buildHistoryWindow(List<Attendance> sourceAttendances) {
    if ((_employeeUuid?.isNotEmpty ?? false) != true &&
        sourceAttendances.isEmpty) {
      return const <Attendance>[];
    }

    final attendancesByDate = <String, Attendance>{};
    for (final attendance in sourceAttendances) {
      final existing = attendancesByDate[attendance.date];
      attendancesByDate[attendance.date] = _preferHistoryAttendance(
        existing,
        attendance,
      );
    }

    final today = DateTime.now();
    final items = <Attendance>[];

    for (var offset = 0; offset < _historyWindowDays; offset++) {
      final date = today.subtract(Duration(days: offset));
      final normalizedDate = DateFormat('yyyy-MM-dd').format(date);
      final existingAttendance = attendancesByDate[normalizedDate];

      if (existingAttendance != null) {
        items.add(existingAttendance);
        continue;
      }

      items.add(
        Attendance(
          employeeUuid: _employeeUuid,
          date: normalizedDate,
          cCode: _currentCompanyCode,
        ),
      );
    }

    return items;
  }

  Attendance _preferHistoryAttendance(
    Attendance? current,
    Attendance candidate,
  ) {
    if (current == null) {
      return candidate;
    }

    final currentScore =
        (current.hasClockIn ? 2 : 0) +
        (current.hasClockOut ? 3 : 0) +
        ((current.isPendingSync) ? 1 : 0);
    final candidateScore =
        (candidate.hasClockIn ? 2 : 0) +
        (candidate.hasClockOut ? 3 : 0) +
        ((candidate.isPendingSync) ? 1 : 0);

    return candidateScore >= currentScore ? candidate : current;
  }

  Widget _buildHistoryItem(Attendance attendance, bool isDark) {
    final date = DateTime.parse(attendance.date);
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
                      color: attendance.hasClockOut
                          ? Colors.orange
                          : Colors.grey,
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildSyncNoticeCard(
    BuildContext context,
    bool isDark,
    AttendanceProvider provider,
  ) {
    final notice = provider.syncNotice;
    if (notice == null || notice.isEmpty) {
      return const SizedBox.shrink();
    }

    final cardColor = provider.pendingSyncCount > 0
        ? Colors.orange
        : Colors.blue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                provider.pendingSyncCount > 0
                    ? Icons.cloud_off_outlined
                    : Icons.info_outline,
                color: cardColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  provider.pendingSyncCount > 0
                      ? 'Sync Offline Pending'
                      : 'Attendance Notice',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (provider.pendingSyncCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${provider.pendingSyncCount} pending',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cardColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            notice,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          if (provider.pendingSyncCount > 0) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: provider.isSyncingOfflineQueue
                    ? null
                    : () async {
                        await provider.syncOfflineActions();
                      },
                icon: provider.isSyncingOfflineQueue
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(
                  provider.isSyncingOfflineQueue ? 'Syncing...' : 'Sync now',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // MARK: - Handlers
  Future<void> _handleClockIn(BuildContext context) async {
    if (_employeeUuid == null || _employeeUuid!.isEmpty) {
      _showErrorSnackBar('Data karyawan tidak ditemukan');
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const ClockInScreen()),
    );

    if (result == true && mounted) {
      final provider = Provider.of<AttendanceProvider>(context, listen: false);
      await _loadTodayData(provider);
      unawaited(_loadHistoryData(attendanceProvider: provider));
    }
  }

  Future<void> _handleClockOut(BuildContext context) async {
    if (_employeeUuid == null || _employeeUuid!.isEmpty) {
      _showErrorSnackBar('Data karyawan tidak ditemukan');
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const ClockInScreen(isClockOut: true),
      ),
    );

    if (result == true && mounted) {
      final provider = Provider.of<AttendanceProvider>(context, listen: false);
      await _loadTodayData(provider);
      unawaited(_loadHistoryData(attendanceProvider: provider));
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
