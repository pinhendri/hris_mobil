// lib/screens/attendance/attendance_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../services/api_service.dart';
import '../../services/session_storage.dart';

class AttendanceSettingsScreen extends StatefulWidget {
  const AttendanceSettingsScreen({super.key});

  @override
  State<AttendanceSettingsScreen> createState() =>
      _AttendanceSettingsScreenState();
}

class _AttendanceSettingsScreenState extends State<AttendanceSettingsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _entities = [];
  bool _isLoadingEntities = false;

  bool _isTruthy(dynamic value) {
    if (value == null) {
      return false;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = value.toString().trim().toLowerCase();
    return normalized == '1' ||
        normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'active' ||
        normalized == 'enabled' ||
        normalized == 'aktif' ||
        normalized == 'on';
  }

  bool _isEntityActive(Map<String, dynamic> entity) {
    return _isTruthy(entity['is_active']) ||
        _isTruthy(entity['active']) ||
        _isTruthy(entity['status']) ||
        _isTruthy(entity['status_active']);
  }

  @override
  void initState() {
    super.initState();
    _fetchEntities();
  }

  Future<void> _fetchEntities() async {
    setState(() {
      _isLoadingEntities = true;
    });

    final authProvider = context.read<AuthProvider>();

    try {
      print('🔄 Fetching entities...');
      final companyCode = authProvider.getCompanyCode().trim();
      if (companyCode.isNotEmpty) {
        await SessionStorage.saveCompanyCode(companyCode);
      }
      await authProvider.syncSelectedCompanyContext();
      final response = await _apiService.get('/entities');

      print('📥 Response: $response');

      if (response is Map<String, dynamic>) {
        final success = response['success'] ?? false;
        final data = response['data'];
        final entities = data is List
            ? data
            : (data is Map<String, dynamic> && data['data'] is List)
            ? List<dynamic>.from(data['data'] as List)
            : <dynamic>[];

        if (success == true) {
          setState(() {
            _entities = entities;
          });
          print('✅ Loaded ${_entities.length} entities');
          print('📊 Entity data: $_entities');
        }
      }
    } catch (e) {
      print('❌ Error fetching entities: $e');
    } finally {
      setState(() {
        _isLoadingEntities = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Konfigurasi Absensi',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              context.read<AttendanceProvider>().fetchSettings();
              _fetchEntities();
            },
          ),
        ],
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && _isLoadingEntities) {
            return const Center(child: CircularProgressIndicator());
          }

          // PERBAIKAN: Tampilkan semua entities, bukan hanya yang aktif
          // final activeEntities = _entities.where((e) {
          //   if (e is Map) {
          //     return e['is_active'] == true;
          //   }
          //   return false;
          // }).toList();

          // Gunakan semua entities
          final allEntities = _entities;

          final settings = provider.settings;

          return RefreshIndicator(
            onRefresh: () async {
              await provider.fetchSettings();
              await _fetchEntities();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Card(
                    color: Colors.blue[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Lokasi absensi akan memakai client/vendor assignment terlebih dahulu. Jika tidak ada, sistem mengambil default entity aktif. Jika entity aktif juga tidak ada, baru memakai koordinat dari setting.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Company Settings Section
                  if (settings != null) ...[
                    _buildSectionHeader('Pengaturan Perusahaan'),
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              'Nama Perusahaan',
                              settings.companyName ?? '-',
                              Icons.business,
                            ),
                            _buildInfoRow(
                              'Timezone',
                              settings.timezone ?? '-',
                              Icons.access_time,
                            ),
                            _buildInfoRow(
                              'Format Tanggal',
                              settings.dateFormat ?? '-',
                              Icons.calendar_today,
                            ),
                            _buildInfoRow(
                              'Mata Uang',
                              settings.currency ?? '-',
                              Icons.attach_money,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Location Section
                  _buildSectionHeader('Lokasi Absensi'),
                  const SizedBox(height: 12),
                  if (allEntities.isEmpty)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada lokasi yang dikonfigurasi',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hubungi administrator untuk menambahkan lokasi absensi',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...allEntities
                        .map((entity) => _buildLocationCard(entity))
                        .toList(),

                  const SizedBox(height: 20),

                  // Default Location Info
                  if (allEntities.isNotEmpty)
                    Card(
                      color: Colors.green[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info,
                              size: 16,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Lokasi default untuk absensi adalah entitas yang aktif. Pastikan Anda berada dalam radius lokasi saat melakukan absensi.',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.green[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(dynamic entity) {
    // Extract data dari Map
    final String name = entity['name'] ?? '-';
    final String? address = entity['address'];
    final double? latitude = entity['latitude'] != null
        ? (entity['latitude'] is int
              ? (entity['latitude'] as int).toDouble()
              : entity['latitude'] as double)
        : null;
    final double? longitude = entity['longitude'] != null
        ? (entity['longitude'] is int
              ? (entity['longitude'] as int).toDouble()
              : entity['longitude'] as double)
        : null;
    final bool isActive = _isEntityActive(Map<String, dynamic>.from(entity));
    final double radius = entity['radius'] != null
        ? (entity['radius'] is int
              ? (entity['radius'] as int).toDouble()
              : (entity['radius'] as num).toDouble())
        : 100.0;

    print('📊 Building card for: $name, isActive: $isActive');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (address != null && address.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          address,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Tampilkan status active/inactive
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? Icons.check_circle : Icons.cancel,
                        size: 12,
                        color: isActive ? Colors.green[700] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'Active' : 'Inactive',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: isActive
                              ? Colors.green[700]
                              : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildLocationDetail(
                    'Latitude',
                    latitude?.toStringAsFixed(6) ?? '-',
                  ),
                ),
                Expanded(
                  child: _buildLocationDetail(
                    'Longitude',
                    longitude?.toStringAsFixed(6) ?? '-',
                  ),
                ),
                Expanded(
                  child: _buildLocationDetail(
                    'Radius',
                    '${radius.toStringAsFixed(radius == radius.roundToDouble() ? 0 : 1)} m',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[500]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
