// lib/screens/attendance/attendance_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
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
  bool _isSaving = false;

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
      final companyCode = authProvider.getCompanyCode().trim();
      if (companyCode.isNotEmpty) {
        await SessionStorage.saveCompanyCode(companyCode);
      }
      await authProvider.syncSelectedCompanyContext();
      final response = await _apiService.get('/entities');

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
        }
      }
    } catch (e) {
      _showMessage('Gagal memuat data lokasi: $e');
    } finally {
      setState(() {
        _isLoadingEntities = false;
      });
    }
  }

  Future<bool> _saveEntity({
    required Map<String, dynamic>? editingEntity,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    required double radius,
    required bool isActive,
  }) async {
    final companyCode = context.read<AuthProvider>().getCompanyCode().trim();
    if (name.trim().isEmpty) {
      _showMessage('Nama entity harus diisi');
      return false;
    }
    if (radius <= 0) {
      _showMessage('Radius absensi harus lebih dari 0 meter');
      return false;
    }
    if (companyCode.isEmpty) {
      _showMessage('Company code tidak ditemukan');
      return false;
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'name': name.trim(),
        'address': address.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'is_active': isActive,
        'c_code': companyCode,
      };

      if (editingEntity == null) {
        await _apiService.post('/entities', payload);
        _showMessage('Entity berhasil ditambahkan');
      } else {
        final id = _entityId(editingEntity);
        await _apiService.put('/entities/$id', payload);
        _showMessage('Entity berhasil diupdate');
      }

      await _fetchEntities();
      if (mounted) {
        await context.read<AttendanceProvider>().loadLocations(
          forceRefresh: true,
        );
      }
      return true;
    } catch (error) {
      _showMessage('Gagal menyimpan data: $error');
      return false;
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteEntity(Map<String, dynamic> entity) async {
    final id = _entityId(entity);
    final name = _readString(entity, 'name', fallback: 'lokasi ini');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Lokasi'),
        content: Text('Apakah Anda yakin ingin menghapus "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _apiService.delete('/entities/$id');
      _showMessage('Entity berhasil dihapus');
      await _fetchEntities();
      if (mounted) {
        await context.read<AttendanceProvider>().loadLocations(
          forceRefresh: true,
        );
      }
    } catch (error) {
      _showMessage('Gagal menghapus data: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _toggleEntityActive(Map<String, dynamic> entity) async {
    final id = _entityId(entity);
    final isActive = _isEntityActive(entity);
    setState(() => _isSaving = true);
    try {
      await _apiService.patch('/entities/$id/toggle-active');
      _showMessage(isActive ? 'Entity dinonaktifkan' : 'Entity diaktifkan');
      await _fetchEntities();
      if (mounted) {
        await context.read<AttendanceProvider>().loadLocations(
          forceRefresh: true,
        );
      }
    } catch (error) {
      _showMessage('Gagal mengubah status: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  String _entityId(Map<String, dynamic> entity) {
    return _readString(entity, 'id', fallback: '');
  }

  String _readString(
    Map<String, dynamic> data,
    String key, {
    String fallback = '-',
  }) {
    final value = data[key];
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  double _readDouble(
    Map<String, dynamic> data,
    String key, {
    required double fallback,
  }) {
    final value = data[key];
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final canCreateLocation = authProvider.hasAnyPermission([
      'create-default-location',
      'create-settings',
    ]);

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
          if (canCreateLocation)
            IconButton(
              icon: const Icon(Icons.add_location_alt, color: Colors.black),
              onPressed: _isSaving ? null : () => _openEntityForm(),
            ),
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
          if ((provider.isLoading && _isLoadingEntities) || _isSaving) {
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
                              'Semua lokasi entity yang aktif bisa dipakai untuk absensi. Karyawan dapat absen di bisnis unit mana pun selama berada dalam radius lokasi aktif yang diinput.',
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
                  SizedBox(
                    width: double.infinity,
                    child: canCreateLocation
                        ? ElevatedButton.icon(
                            onPressed: _isSaving
                                ? null
                                : () => _openEntityForm(),
                            icon: const Icon(Icons.add_location_alt),
                            label: const Text('Add New Location'),
                          )
                        : const SizedBox.shrink(),
                  ),
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
                    ...allEntities.map((entity) => _buildLocationCard(entity)),

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

  Future<void> _openEntityForm([Map<String, dynamic>? entity]) async {
    final isEditing = entity != null;
    final nameController = TextEditingController(
      text: entity == null ? '' : _readString(entity, 'name', fallback: ''),
    );
    final addressController = TextEditingController(
      text: entity == null ? '' : _readString(entity, 'address', fallback: ''),
    );
    final radiusController = TextEditingController(
      text: entity == null
          ? '100'
          : _readDouble(entity, 'radius', fallback: 100).toStringAsFixed(0),
    );
    var latitude = entity == null
        ? -6.2088
        : _readDouble(entity, 'latitude', fallback: -6.2088);
    var longitude = entity == null
        ? 106.8456
        : _readDouble(entity, 'longitude', fallback: 106.8456);
    var isActive = entity != null && _isEntityActive(entity);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final selectedPoint = LatLng(latitude, longitude);

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isEditing ? 'Edit Location' : 'Add New Location',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildReadonlyCoordinateField(
                            'Latitude',
                            latitude,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildReadonlyCoordinateField(
                            'Longitude',
                            longitude,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: radiusController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Radius Absensi (meter) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isActive,
                      onChanged: (value) {
                        setSheetState(() => isActive = value);
                      },
                      title: const Text('Aktifkan lokasi absensi'),
                      subtitle: const Text(
                        'Bisa mengaktifkan lebih dari satu lokasi untuk bisnis unit berbeda.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click on map to set location',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 260,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: selectedPoint,
                            initialZoom: 13,
                            onTap: (_, point) {
                              setSheetState(() {
                                latitude = point.latitude;
                                longitude = point.longitude;
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.hris_mobile',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: selectedPoint,
                                  width: 44,
                                  height: 44,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap pada peta untuk menentukan koordinat lokasi absensi.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    final saved = await _saveEntity(
                                      editingEntity: entity,
                                      name: nameController.text,
                                      address: addressController.text,
                                      latitude: latitude,
                                      longitude: longitude,
                                      radius:
                                          double.tryParse(
                                            radiusController.text,
                                          ) ??
                                          0,
                                      isActive: isActive,
                                    );
                                    if (saved && sheetContext.mounted) {
                                      Navigator.pop(sheetContext);
                                    }
                                  },
                            child: Text(isEditing ? 'Update' : 'Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    addressController.dispose();
    radiusController.dispose();
  }

  Widget _buildReadonlyCoordinateField(String label, double value) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      child: Text(
        value.toStringAsFixed(6),
        style: GoogleFonts.poppins(color: Colors.grey[700]),
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
    final entityMap = Map<String, dynamic>.from(entity as Map);
    // Extract data dari Map
    final String name = _readString(entityMap, 'name');
    final String address = _readString(entityMap, 'address', fallback: '');
    final double? latitude = entityMap['latitude'] == null
        ? null
        : _readDouble(entityMap, 'latitude', fallback: 0);
    final double? longitude = entityMap['longitude'] == null
        ? null
        : _readDouble(entityMap, 'longitude', fallback: 0);
    final bool isActive = _isEntityActive(entityMap);
    final double radius = _readDouble(entityMap, 'radius', fallback: 100);
    final authProvider = context.read<AuthProvider>();
    final canEditLocation = authProvider.hasAnyPermission([
      'edit-default-location',
      'edit-settings',
    ]);
    final canDeleteLocation = authProvider.hasAnyPermission([
      'delete-default-location',
      'delete-settings',
    ]);

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
                    color: AppColors.primary.withValues(alpha: 0.1),
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
                      if (address.isNotEmpty) ...[
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
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
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
            if (canEditLocation || canDeleteLocation) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (canEditLocation) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _openEntityForm(entityMap),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _toggleEntityActive(entityMap),
                        icon: Icon(
                          isActive ? Icons.close : Icons.check,
                          size: 16,
                        ),
                        label: Text(isActive ? 'Nonaktif' : 'Aktifkan'),
                      ),
                    ),
                  ],
                  if (canDeleteLocation) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isSaving
                          ? null
                          : () => _deleteEntity(entityMap),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete',
                    ),
                  ],
                ],
              ),
            ],
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
