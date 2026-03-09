import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/correction_provider.dart';
import '../../providers/employee_provider.dart';
import '../../data/models/correction_model.dart';
import '../../data/models/employee_model.dart';

class CorrectionScreen extends StatefulWidget {
  const CorrectionScreen({super.key});

  @override
  State<CorrectionScreen> createState() => _CorrectionScreenState();
}

class _CorrectionScreenState extends State<CorrectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedEmployeeUuid;
  DateTime? _selectedDate;
  AttendanceData? _attendanceData;
  bool _isSearching = false;
  bool _isSubmitting = false;

  // Form koreksi
  final TextEditingController _checkInController = TextEditingController();
  final TextEditingController _checkOutController = TextEditingController();
  String _selectedStatus = 'Present';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load employees saat screen pertama dibuka
      Provider.of<EmployeeProvider>(context, listen: false).fetchEmployees();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    super.dispose();
  }

  // Format waktu dari database untuk input time
  String _formatTimeFromDatabase(String? timeStr) {
    print("🔄 Processing time from database: $timeStr");
    
    if (timeStr == null || timeStr.isEmpty || timeStr == "null" || timeStr == "00:00:00") {
      return "";
    }
    
    // Handle berbagai format waktu dari database
    final timeParts = timeStr.split(':');
    
    if (timeParts.length >= 2) {
      final hours = timeParts[0].padLeft(2, '0');
      final minutes = timeParts[1].padLeft(2, '0');
      final formattedTime = "$hours:$minutes";
      
      print("✅ Formatted time for input: $formattedTime");
      return formattedTime;
    }
    
    print("❌ Could not format time: $timeStr");
    return "";
  }

  // Format waktu untuk dikirim ke database
  String? _formatTimeForDatabase(String timeStr) {
    if (timeStr.isEmpty) {
      return null;
    }
    
    final timeParts = timeStr.split(':');
    if (timeParts.length >= 2) {
      final hours = timeParts[0].padLeft(2, '0');
      final minutes = timeParts[1].padLeft(2, '0');
      return "$hours:$minutes:00";
    }
    
    return null;
  }

  // Search attendance
  Future<void> _searchAttendance() async {
    if (_selectedEmployeeUuid == null || _selectedDate == null) {
      _showErrorSnackBar('Pilih karyawan dan tanggal terlebih dahulu');
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final provider = Provider.of<CorrectionProvider>(context, listen: false);
      
      print('🔍 Searching attendance for employee UUID: $_selectedEmployeeUuid');
      print('📅 Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}');
      
      final data = await provider.getAttendanceForCorrection(
        employeeUuid: _selectedEmployeeUuid!,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      );

      setState(() {
        _attendanceData = data;
        
        // Format waktu untuk input
        _checkInController.text = _formatTimeFromDatabase(data.clockIn);
        _checkOutController.text = _formatTimeFromDatabase(data.clockOut);
        _selectedStatus = data.status ?? 'Present';
      });

      // Tampilkan pesan sukses
      if (data.exists) {
        _showSuccessSnackBar('Data absensi ditemukan');
      } else {
        _showInfoSnackBar('Tidak ada data absensi. Silakan buat data baru.');
      }

    } catch (e) {
      print('❌ Error searching attendance: $e');
      _showErrorSnackBar('Gagal mengambil data: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  // Submit correction
  Future<void> _submitCorrection() async {
    if (_attendanceData == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final provider = Provider.of<CorrectionProvider>(context, listen: false);
      
      final Map<String, dynamic> payload = {
        'status': _selectedStatus,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
      };

      // Hanya tambahkan clock_in jika ada nilai
      final clockInFormatted = _formatTimeForDatabase(_checkInController.text);
      if (clockInFormatted != null) {
        payload['clock_in'] = clockInFormatted;
      }

      // Hanya tambahkan clock_out jika ada nilai
      final clockOutFormatted = _formatTimeForDatabase(_checkOutController.text);
      if (clockOutFormatted != null) {
        payload['clock_out'] = clockOutFormatted;
      }

      // Hanya tambahkan employee_uuid jika diperlukan dan tidak null
      if (_attendanceData?.id == null && _selectedEmployeeUuid != null) {
        payload['employee_uuid'] = _selectedEmployeeUuid!;
      }

      print('📤 Submitting correction with payload: $payload');
      print('📤 Using identifier: ${_attendanceData?.id?.toString() ?? _selectedEmployeeUuid!}');

      final success = await provider.updateAttendanceCorrection(
        identifier: _attendanceData?.id?.toString() ?? _selectedEmployeeUuid!,
        data: payload,
      );

      if (success) {
        // Tampilkan snackbar sukses
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Koreksi absensi berhasil disimpan'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        // Tunggu sebentar lalu close screen
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true);
        }
        
      } else {
        setState(() {
          _isSubmitting = false;
        });
        _showErrorSnackBar('Gagal menyimpan koreksi');
      }

    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      print('❌ Error submitting correction: $e');
      _showErrorSnackBar('Error: $e');
    }
  }

  // Reset form
  void _resetForm() {
    setState(() {
      _selectedEmployeeUuid = null;
      _selectedDate = null;
      _attendanceData = null;
      _checkInController.clear();
      _checkOutController.clear();
      _selectedStatus = 'Present';
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Koreksi Absensi',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Koreksi'),
            Tab(text: 'Riwayat'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCorrectionTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildCorrectionTab() {
    return Consumer2<CorrectionProvider, EmployeeProvider>(
      builder: (context, correctionProvider, employeeProvider, child) {
        // Debug: print employees data
        print('📋 EmployeeProvider has ${employeeProvider.employees.length} employees');
        for (var emp in employeeProvider.employees) {
          print('   - ${emp.name}: UUID=${emp.uuid}');
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Form Koreksi',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pilih karyawan dan tanggal untuk melihat atau memperbaiki absensi',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Selection Form
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Employee Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedEmployeeUuid,
                        hint: const Text('Pilih karyawan'),
                        decoration: InputDecoration(
                          labelText: 'Karyawan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: employeeProvider.employees.map((employee) {
                          return DropdownMenuItem(
                            value: employee.uuid,
                            child: Text(
                              employee.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _isSubmitting ? null : (value) {
                          print('✅ Selected employee UUID: $value');
                          setState(() {
                            _selectedEmployeeUuid = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date Picker
                      InkWell(
                        onTap: _isSubmitting ? null : () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Tanggal',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _selectedDate != null
                                ? DateFormat('dd MMMM yyyy').format(_selectedDate!)
                                : 'Pilih tanggal',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (_selectedEmployeeUuid == null || 
                                       _selectedDate == null || 
                                       _isSearching ||
                                       _isSubmitting)
                                  ? null
                                  : _searchAttendance,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSearching
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Cari Absensi',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _isSubmitting ? null : _resetForm,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Reset'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Attendance Detail (if available)
              if (_attendanceData != null) ...[
                const SizedBox(height: 16),
                _buildAttendanceDetail(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceDetail() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Detail Absensi',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _attendanceData!.exists ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _attendanceData!.exists ? 'Data Ditemukan' : 'Data Baru',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Saat Ini:',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_attendanceData!.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(_attendanceData!.status),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _getStatusColor(_attendanceData!.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Original Data
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data dari Database:',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.login, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Clock In: ',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _attendanceData!.clockIn != null && 
                          _attendanceData!.clockIn != "00:00:00"
                              ? _attendanceData!.clockIn!
                              : 'Belum diisi',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _attendanceData!.clockIn != null && 
                                   _attendanceData!.clockIn != "00:00:00"
                                   ? Colors.green
                                   : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.logout, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Clock Out: ',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _attendanceData!.clockOut != null && 
                          _attendanceData!.clockOut != "00:00:00"
                              ? _attendanceData!.clockOut!
                              : 'Belum diisi',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _attendanceData!.clockOut != null && 
                                   _attendanceData!.clockOut != "00:00:00"
                                   ? Colors.green
                                   : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Correction Form
            Text(
              'Form Koreksi',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Clock In
            TextField(
              controller: _checkInController,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: 'Jam Masuk',
                hintText: 'HH:MM',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.login),
              ),
            ),
            const SizedBox(height: 12),

            // Clock Out
            TextField(
              controller: _checkOutController,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: 'Jam Keluar',
                hintText: 'HH:MM',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.logout),
              ),
            ),
            const SizedBox(height: 12),

            // Status Dropdown
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.info),
              ),
              items: const [
                DropdownMenuItem(value: 'Present', child: Text('Hadir')),
                DropdownMenuItem(value: 'Late', child: Text('Terlambat')),
                DropdownMenuItem(value: 'Absent', child: Text('Tidak Hadir')),
                DropdownMenuItem(value: 'Leave', child: Text('Cuti')),
                DropdownMenuItem(value: 'Sick', child: Text('Sakit')),
              ],
              onChanged: _isSubmitting ? null : (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitCorrection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Simpan Koreksi',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Fitur riwayat absensi akan segera tersedia',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Late':
        return Colors.orange;
      case 'Absent':
        return Colors.red;
      case 'Leave':
        return Colors.blue;
      case 'Sick':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'Present':
        return 'Hadir';
      case 'Late':
        return 'Terlambat';
      case 'Absent':
        return 'Tidak Hadir';
      case 'Leave':
        return 'Cuti';
      case 'Sick':
        return 'Sakit';
      default:
        return status ?? '-';
    }
  }
}