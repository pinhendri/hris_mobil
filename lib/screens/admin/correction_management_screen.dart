import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/correction_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../data/models/correction_model.dart';
import 'admin_palette.dart';

class CorrectionManagementScreen extends StatefulWidget {
  const CorrectionManagementScreen({super.key});

  @override
  State<CorrectionManagementScreen> createState() =>
      _CorrectionManagementScreenState();
}

class _CorrectionManagementScreenState
    extends State<CorrectionManagementScreen> {
  Color get _screenBackgroundColor => AdminPalette.page(context);

  Color get _surfaceColor => AdminPalette.surface(context);

  Color get _primaryTextColor => AdminPalette.text(context);

  Color get _secondaryTextColor => AdminPalette.mutedText(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CorrectionProvider>(context, listen: false).fetchRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _screenBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Correction Management',
          style: TextStyle(
            color: _primaryTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _surfaceColor,
        surfaceTintColor: _surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _primaryTextColor),
      ),
      body: Consumer<CorrectionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = provider.requests
              .where((r) => r.type == 'Attendance')
              .toList();

          if (requests.isEmpty) {
            return Center(
              child: Text(
                'No attendance correction requests found',
                style: TextStyle(color: _secondaryTextColor),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _CorrectionRequestCard(request: request);
            },
          );
        },
      ),
    );
  }
}

class _CorrectionRequestCard extends StatelessWidget {
  final CorrectionRequest request;

  const _CorrectionRequestCard({required this.request});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? const Color(0xFF111827) : Colors.white;
    final surfaceBorderColor = isDarkMode
        ? const Color(0xFF253041)
        : AppColors.border;
    final primaryTextColor = isDarkMode
        ? const Color(0xFFF8FAFC)
        : AppColors.textPrimary;
    final secondaryTextColor = isDarkMode
        ? const Color(0xFFCBD5E1)
        : AppColors.textSecondary;
    final correctionProvider = Provider.of<CorrectionProvider>(
      context,
      listen: false,
    );
    final statusColor = _statusColor(request.status);
    final canApprove = request.status == 'Pending';
    final canReject = request.status == 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: surfaceBorderColor),
        boxShadow: isDarkMode
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Correction',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              if (request.targetDate != null)
                Text(
                  'For: ${request.targetDate!.toLocal().toIso8601String().split('T').first}',
                  style: TextStyle(fontSize: 13, color: secondaryTextColor),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.description,
            style: TextStyle(
              fontSize: 14,
              color: primaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (canReject)
                OutlinedButton(
                  onPressed: () async {
                    final ok = await correctionProvider.rejectRequest(
                      request.id,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Correction rejected'
                                : 'Cannot reject in current status',
                          ),
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: surfaceBorderColor),
                  ),
                  child: const Text('Reject'),
                ),
              if (canApprove) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final ok = await correctionProvider.approveRequest(
                      request.id,
                    );

                    if (ok && request.targetDate != null && context.mounted) {
                      final attendanceProvider =
                          Provider.of<AttendanceProvider>(
                            context,
                            listen: false,
                          );

                      // Gunakan employeeId dari request
                      final employeeId = request.employeeId;

                      // Ambil data dari details jika ada
                      final details = request.details ?? {};
                      final clockIn =
                          details['clock_in']?.toString() ?? '08:00:00';
                      final clockOut =
                          details['clock_out']?.toString() ?? '17:00:00';

                      if (employeeId.isNotEmpty) {
                        await attendanceProvider.applyCorrectionForDate(
                          employeeUuid: employeeId,
                          date: request.targetDate!,
                          clockIn: clockIn,
                          clockOut: clockOut,
                          reason: request.description,
                        );
                      }
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Correction approved and attendance updated'
                                : 'Cannot approve in current status',
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
