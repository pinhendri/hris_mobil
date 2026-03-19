import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/api_constants.dart';

class MyLocationScreen extends StatefulWidget {
  const MyLocationScreen({super.key});

  @override
  State<MyLocationScreen> createState() => _MyLocationScreenState();
}

class _MyLocationScreenState extends State<MyLocationScreen> {
  static const LatLng _fallbackLatLng = LatLng(-6.2088, 106.8456);
  static const LatLng _defaultEmulatorLatLng = LatLng(37.4219983, -122.084);
  static const String _tileUrlTemplate =
      '${ApiConstants.baseUrl}${ApiConstants.mapTilesEndpoint}';
  static const String _tileFallbackUrlTemplate =
      '${ApiConstants.baseUrl}${ApiConstants.mapTilesProxyEndpoint}';

  final MapController _mapController = MapController();

  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  bool _isMapReady = false;
  bool _isLoading = true;
  bool _hasMapLoadIssue = false;
  bool _hasShownMapError = false;
  int _mapReloadToken = 0;
  String _statusMessage = 'Initializing...';
  String _address = '-';

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _positionStream = null;
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _setError('GPS tidak aktif');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setError('Izin lokasi ditolak');
        return;
      }

      await _getCurrentLocation();
      _startLocationStream();
    } catch (e) {
      _setError('Init error: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    _safeSetState(() {
      _isLoading = true;
      _statusMessage = 'Mencari lokasi...';
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _applyPosition(position, moveMap: true);
    } catch (e) {
      _setError('Gagal mengambil lokasi: $e');
    }
  }

  void _startLocationStream() {
    _positionStream?.cancel();
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen(
          (position) {
            unawaited(_applyPosition(position, moveMap: false));
          },
          onError: (Object error) {
            _setError('Update lokasi gagal: $error');
          },
        );
  }

  Future<void> _applyPosition(
    Position position, {
    required bool moveMap,
  }) async {
    if (!mounted) {
      return;
    }

    final latLng = LatLng(position.latitude, position.longitude);

    _safeSetState(() {
      _currentPosition = position;
      _isLoading = false;
      _statusMessage = 'Lokasi ditemukan';
    });

    if (_isMapReady && mounted) {
      final zoom = moveMap ? 16.0 : _mapController.camera.zoom;
      _mapController.move(latLng, zoom);
    }

    await _getAddress(latLng.latitude, latLng.longitude);
  }

  Future<void> _getAddress(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (!mounted) {
        return;
      }

      final place = placemarks.isNotEmpty ? placemarks.first : null;
      _safeSetState(() {
        _address = [
          place?.street,
          place?.subLocality,
          place?.locality,
          place?.administrativeArea,
        ].where((part) => part != null && part!.trim().isNotEmpty).join(', ');

        if (_address.trim().isEmpty) {
          _address = 'Alamat tidak tersedia';
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      _safeSetState(() {
        _address = 'Alamat tidak tersedia';
      });
    }
  }

  void _setError(String message) {
    if (!mounted) {
      return;
    }

    _safeSetState(() {
      _statusMessage = message;
      _isLoading = false;
    });

    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleMapTileError(Object error) {
    if (!mounted) {
      return;
    }

    _safeSetState(() {
      _hasMapLoadIssue = true;
    });

    if (_hasShownMapError) {
      return;
    }

    _hasShownMapError = true;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      const SnackBar(
        content: Text(
          'Map gagal dimuat dari proxy backend. Coba lagi sebentar.',
        ),
      ),
    );
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) {
      return;
    }

    setState(fn);
  }

  LatLng get _currentLatLng {
    final position = _currentPosition;
    if (position == null) {
      return _fallbackLatLng;
    }

    return LatLng(position.latitude, position.longitude);
  }

  String get _coordinateLabel {
    final position = _currentPosition;
    if (position == null) {
      return '-6.2088, 106.8456';
    }

    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }

  bool get _isLikelyDefaultEmulatorLocation {
    final position = _currentPosition;
    if (position == null) {
      return false;
    }

    return (position.latitude - _defaultEmulatorLatLng.latitude).abs() <
            0.001 &&
        (position.longitude - _defaultEmulatorLatLng.longitude).abs() < 0.001;
  }

  @override
  Widget build(BuildContext context) {
    final currentLatLng = _currentLatLng;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lokasi Saya',
          style: GoogleFonts.poppins(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              key: ValueKey(_mapReloadToken),
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentLatLng,
                initialZoom: 16,
                onMapReady: () {
                  _isMapReady = true;
                  if (_currentPosition != null) {
                    _mapController.move(_currentLatLng, 16);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _tileUrlTemplate,
                  fallbackUrl: _tileFallbackUrlTemplate,
                  userAgentPackageName: 'com.example.hris_mobile',
                  evictErrorTileStrategy: EvictErrorTileStrategy.none,
                  errorTileCallback: (tile, error, stackTrace) {
                    _handleMapTileError(error);
                  },
                ),
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 50,
                        height: 50,
                        point: currentLatLng,
                        child: const Icon(
                          Icons.location_on,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Positioned(top: 16, left: 16, right: 16, child: _buildInfoCard()),
          if (_hasMapLoadIssue)
            Positioned(
              top: 92,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Tile utama bermasalah. Jika peta masih blank, tekan "Retry Map".',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ),
            ),
          if (_isLikelyDefaultEmulatorLocation)
            Positioned(
              top: _hasMapLoadIssue ? 164 : 92,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Koordinat saat ini adalah lokasi default emulator Android. Ubah lokasi emulator jika ingin melihat titik lain.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildBottomCard(),
          ),
          Positioned(
            bottom: 160,
            right: 16,
            child: FloatingActionButton(
              onPressed: _isLoading ? null : _getCurrentLocation,
              backgroundColor: Colors.white,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: Colors.black),
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentPosition != null ? _address : _statusMessage,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              'Koordinat: $_coordinateLabel',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Lokasi',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(_statusMessage, style: GoogleFonts.poppins(fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _safeSetState(() {
                        _hasMapLoadIssue = false;
                        _hasShownMapError = false;
                        _isMapReady = false;
                        _mapReloadToken++;
                      });
                    },
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Retry Map'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapFallback(LatLng latLng) {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.location_searching,
                  size: 48,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Peta tidak bisa dimuat',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lokasi tetap berhasil dibaca. Koordinat saat ini:\n${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
