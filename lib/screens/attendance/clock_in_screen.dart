// lib/screens/attendance/clock_in_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/attendance_location.dart';

class ClockInScreen extends StatefulWidget {
  const ClockInScreen({super.key});

  @override
  State<ClockInScreen> createState() => _ClockInScreenState();
}

class _ClockInScreenState extends State<ClockInScreen> {
  File? _photo;
  String? _photoBase64;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isMockLocation = false;
  String _locationError = '';
  StreamSubscription<Position>? _positionStream;
  bool _isPhotoTaken = false;
  bool _isMapReady = false;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _startLocationStream();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startLocationStream() async {
    setState(() {
      _isLoadingLocation = true;
    });

    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Layanan lokasi tidak aktif. Nyalakan GPS Anda.';
          _isLoadingLocation = false;
        });
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Izin lokasi ditolak';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Izin lokasi ditolak permanen.';
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      if (mounted) _updatePosition(position);

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        if (mounted) _updatePosition(position);
      });

    } catch (e) {
      print('Location error: $e');
      if (mounted) {
        setState(() {
          _locationError = 'Error: $e';
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _updatePosition(Position position) {
    if (!mounted) return;

    setState(() {
      _currentPosition = position;
      _isLoadingLocation = false;
      _isMockLocation = position.isMocked;
    });

    if (_isMapReady) {
      try {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          16.0,
        );
      } catch (e) {
        print('Error moving map: $e');
      }
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Sumber Foto'),
        content: const Text('Ambil foto dari kamera atau galeri?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Kamera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Galeri'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Batal'),
          ),
        ],
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 50,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        final file = File(image.path);
        final bytes = await file.readAsBytes();
        final base64Image = base64Encode(bytes);

        setState(() {
          _photo = file;
          _photoBase64 = base64Image;
          _isPhotoTaken = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _calculateDistance(AttendanceLocation location) {
    if (_currentPosition == null) return double.infinity;

    const Distance distance = Distance();
    return distance.as(
      LengthUnit.Meter,
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      LatLng(location.latitude, location.longitude),
    );
  }

  Future<void> _refreshLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      if (mounted) _updatePosition(position);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing location: $e')),
        );
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _submitClockIn() async {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!_isPhotoTaken || _photoBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto wajib diambil'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi tidak tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isMockLocation) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Peringatan'),
          content: const Text('Anda menggunakan lokasi mock. Apakah Anda yakin ingin melanjutkan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    final employeeUuid = authProvider.user?.employeeUuid ?? authProvider.user?.uuid ?? '';

    if (employeeUuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data karyawan tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success = await provider.clockIn(
      employeeUuid: employeeUuid,
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      location: '${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      photo: _photoBase64,
    );

    if (!mounted) return;

    Navigator.pop(context);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clock In Berhasil'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Clock In Gagal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    final allowedLocations = provider.allowedLocations;

    bool isWithinRange = false;
    double minDistance = double.infinity;
    AttendanceLocation? nearestLocation;

    if (_currentPosition != null && allowedLocations.isNotEmpty) {
      for (final location in allowedLocations) {
        final distance = _calculateDistance(location);
        if (distance < minDistance) {
          minDistance = distance;
          nearestLocation = location;
        }
        if (distance <= location.radius) {
          isWithinRange = true;
        }
      }
    }

    LatLng initialCenter;
    if (_currentPosition != null) {
      initialCenter = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    } else if (allowedLocations.isNotEmpty) {
      initialCenter = LatLng(allowedLocations.first.latitude, allowedLocations.first.longitude);
    } else {
      initialCenter = const LatLng(-6.2088, 106.8456);
    }

    final circles = allowedLocations
        .map(
          (loc) => CircleMarker(
            point: LatLng(loc.latitude, loc.longitude),
            color: Colors.green.withOpacity(0.3),
            borderStrokeWidth: 2,
            borderColor: Colors.green,
            useRadiusInMeter: true,
            radius: loc.radius,
          ),
        )
        .toList();

    final locationMarkers = allowedLocations
        .map(
          (loc) => Marker(
            point: LatLng(loc.latitude, loc.longitude),
            width: 40,
            height: 40,
            child: const Icon(Icons.business, color: Colors.blue, size: 40),
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Clock In',
          style: GoogleFonts.poppins(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo Section
            Container(
              height: 250,
              color: Colors.grey[200],
              child: _photo != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_photo!, fit: BoxFit.cover),
                        if (_isPhotoTaken)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 16),
                            ),
                          ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text('Foto Belum Diambil',
                            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Ambil Foto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),

            if (_photo != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Ambil Ulang'),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Map Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Lokasi Anda',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (_isMockLocation)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Mock Location',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: Colors.orange[800], fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 250,
              child: _isLoadingLocation && _currentPosition == null
                  ? const Center(child: CircularProgressIndicator())
                  : _locationError.isNotEmpty && _currentPosition == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_off, size: 48, color: Colors.red[300]),
                              const SizedBox(height: 16),
                              Text(_locationError),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _startLocationStream,
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        )
                      : FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: initialCenter,
                            initialZoom: 16.0,
                            onMapReady: () {
                              setState(() {
                                _isMapReady = true;
                              });
                              if (_currentPosition != null) {
                                _mapController.move(
                                  LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                  16.0,
                                );
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.hris_mobile',
                            ),
                            if (circles.isNotEmpty) CircleLayer(circles: circles),
                            MarkerLayer(
                              markers: [
                                if (_currentPosition != null)
                                  Marker(
                                    point: LatLng(
                                        _currentPosition!.latitude, _currentPosition!.longitude),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.person_pin_circle,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ...locationMarkers,
                              ],
                            ),
                          ],
                        ),
            ),

            if (_currentPosition != null && !_isLoadingLocation)
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FloatingActionButton.small(
                    onPressed: _refreshLocation,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: Colors.blue),
                  ),
                ),
              ),

            // Status & Action
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Lokasi
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isLoadingLocation
                          ? Colors.orange.withOpacity(0.1)
                          : isWithinRange
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isLoadingLocation
                              ? Icons.hourglass_empty
                              : isWithinRange
                                  ? Icons.check_circle
                                  : Icons.error,
                          color: _isLoadingLocation
                              ? Colors.orange
                              : isWithinRange
                                  ? Colors.green
                                  : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isLoadingLocation
                                    ? 'Memuat Lokasi...'
                                    : isWithinRange
                                        ? 'Dalam Jangkauan'
                                        : 'Luar Jangkauan',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: _isLoadingLocation
                                      ? Colors.orange
                                      : isWithinRange
                                          ? Colors.green
                                          : Colors.red,
                                ),
                              ),
                              if (!_isLoadingLocation && _currentPosition != null)
                                Text(
                                  '${minDistance == double.infinity ? "?" : minDistance.toStringAsFixed(0)}m dari ${nearestLocation?.name ?? "lokasi terdekat"}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status Foto
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isPhotoTaken
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isPhotoTaken ? Icons.check_circle : Icons.camera_alt,
                          color: _isPhotoTaken ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isPhotoTaken ? 'Foto sudah diambil' : 'Foto belum diambil',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: _isPhotoTaken ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Button Clock In
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_photo != null &&
                              isWithinRange &&
                              !_isLoadingLocation &&
                              _currentPosition != null)
                          ? _submitClockIn
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: Text(
                        'Clock In',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  if (!isWithinRange && _currentPosition != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Anda berada di luar area yang diizinkan untuk clock in',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  if (!_isPhotoTaken)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Ambil foto terlebih dahulu',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}