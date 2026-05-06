import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/attendance_location.dart';
import '../../providers/attendance_provider.dart';

class MyLocationScreen extends StatefulWidget {
  const MyLocationScreen({super.key});

  @override
  State<MyLocationScreen> createState() => _MyLocationScreenState();
}

class _MyLocationScreenState extends State<MyLocationScreen> {
  static const LatLng _fallbackLatLng = LatLng(-6.2088, 106.8456);
  static const LatLng _defaultEmulatorLatLng = LatLng(37.4219983, -122.084);
  static const String _tileUrlTemplate =
      ApiConstants.openStreetMapTilesEndpoint;
  static const String _tileFallbackUrlTemplate =
      '${ApiConstants.baseUrl}${ApiConstants.mapTilesProxyEndpoint}';

  final MapController _mapController = MapController();

  Position? _currentPosition;
  AttendanceLocation? _attendanceLocationHint;
  StreamSubscription<Position>? _positionStream;

  bool _isMapReady = false;
  bool _isLoading = true;
  bool _hasMapLoadIssue = false;
  bool _hasShownMapError = false;
  int _mapReloadToken = 0;
  String _statusMessage = 'Initializing...';
  String _address = '-';

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get _screenBackgroundColor =>
      _isDarkMode ? const Color(0xFF0F1115) : const Color(0xFFF6F7FB);
  Color get _surfaceColor =>
      _isDarkMode ? const Color(0xFF1B1D20) : Colors.white;
  Color get _mutedSurfaceColor =>
      _isDarkMode ? const Color(0xFF25272B) : const Color(0xFFF3F4F6);
  Color get _borderColor =>
      _isDarkMode ? const Color(0xFF2F3338) : const Color(0xFFE5E7EB);
  Color get _primaryTextColor =>
      _isDarkMode ? const Color(0xFFF5F7FA) : const Color(0xFF111827);
  Color get _secondaryTextColor =>
      _isDarkMode ? const Color(0xFFA8ADB7) : const Color(0xFF64748B);
  Color get _accentColor =>
      _isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

  BoxDecoration _cardDecoration({Color? color, Color? borderColor}) {
    return BoxDecoration(
      color: color ?? _surfaceColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? _borderColor),
      boxShadow: _isDarkMode
          ? const []
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
    );
  }

  @override
  void initState() {
    super.initState();
    _initLocation();
    unawaited(_loadAttendanceLocationHint());
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

  Future<void> _loadAttendanceLocationHint() async {
    try {
      final provider = Provider.of<AttendanceProvider>(context, listen: false);
      await provider.loadLocations();
      if (!mounted) {
        return;
      }

      _safeSetState(() {
        _attendanceLocationHint = provider.defaultLocation;
      });

      if (_shouldUseAttendanceLocationHint) {
        _safeSetState(() {
          _statusMessage = 'Lokasi emulator disesuaikan dengan lokasi absensi';
          _address = _attendanceLocationHintLabel;
        });
      }

      if (_isMapReady && _shouldUseAttendanceLocationHint) {
        _mapController.move(_currentLatLng, 16);
      }
    } catch (_) {
      // Lokasi saya tetap bisa berjalan walau lokasi absensi belum tersedia.
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

    _safeSetState(() {
      _currentPosition = position;
      _isLoading = false;
      _statusMessage = _adjustedEmulatorLocationMessage ?? 'Lokasi ditemukan';
    });

    if (_isMapReady && mounted) {
      final zoom = moveMap ? 16.0 : _mapController.camera.zoom;
      _mapController.move(_currentLatLng, zoom);
    }

    final displayLatLng = _currentLatLng;
    if (_shouldUseAttendanceLocationHint) {
      _safeSetState(() {
        _address = _attendanceLocationHintLabel;
      });
      return;
    }

    await _getAddress(displayLatLng.latitude, displayLatLng.longitude);
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
        ].where((part) => part != null && part.trim().isNotEmpty).join(', ');

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
        content: Text('Map gagal dimuat. Periksa koneksi lalu coba lagi.'),
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
    final hint = _attendanceLocationHint;
    if (_shouldUseAttendanceLocationHint && hint != null) {
      return LatLng(hint.latitude, hint.longitude);
    }

    if (_shouldUseFallbackForDefaultEmulator) {
      return _fallbackLatLng;
    }

    final position = _currentPosition;
    if (position == null) {
      return _fallbackLatLng;
    }

    return LatLng(position.latitude, position.longitude);
  }

  String get _coordinateLabel {
    final hint = _attendanceLocationHint;
    if (_shouldUseAttendanceLocationHint && hint != null) {
      return '${hint.latitude.toStringAsFixed(6)}, ${hint.longitude.toStringAsFixed(6)}';
    }

    if (_shouldUseFallbackForDefaultEmulator) {
      return '${_fallbackLatLng.latitude.toStringAsFixed(6)}, ${_fallbackLatLng.longitude.toStringAsFixed(6)}';
    }

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

  bool get _shouldUseAttendanceLocationHint {
    return _isDebugAndroidDefaultEmulatorLocation &&
        _attendanceLocationHint != null;
  }

  bool get _shouldUseFallbackForDefaultEmulator {
    return _isDebugAndroidDefaultEmulatorLocation &&
        _attendanceLocationHint == null;
  }

  bool get _isDebugAndroidDefaultEmulatorLocation {
    if (!_isLikelyDefaultEmulatorLocation ||
        !Platform.isAndroid ||
        kReleaseMode) {
      return false;
    }

    return true;
  }

  String? get _adjustedEmulatorLocationMessage {
    if (_shouldUseAttendanceLocationHint) {
      return 'Lokasi emulator disesuaikan dengan lokasi absensi';
    }

    if (_shouldUseFallbackForDefaultEmulator) {
      return 'Lokasi default emulator diabaikan';
    }

    return null;
  }

  String get _attendanceLocationHintLabel {
    final hintAddress = _attendanceLocationHint?.address;
    final label = [
      _attendanceLocationHint?.name,
      if (hintAddress != null && hintAddress.trim().isNotEmpty) hintAddress,
    ].where((part) => part != null && part.trim().isNotEmpty).join(', ');

    return label.trim().isEmpty ? 'Lokasi absensi' : label;
  }

  @override
  Widget build(BuildContext context) {
    final currentLatLng = _currentLatLng;

    return Scaffold(
      backgroundColor: _screenBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Lokasi Saya',
          style: GoogleFonts.poppins(
            color: _primaryTextColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: _screenBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _primaryTextColor),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _hasMapLoadIssue
                ? _buildMapFallback(currentLatLng)
                : FlutterMap(
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
                      RichAttributionWidget(
                        attributions: const [
                          TextSourceAttribution('OpenStreetMap contributors'),
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
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: _cardDecoration(
                  color: _isDarkMode
                      ? const Color(0xFF3A2508)
                      : Colors.orange.shade50,
                  borderColor: Colors.orange.withValues(alpha: 0.28),
                ),
                child: Text(
                  'Tile utama bermasalah. Jika peta masih blank, tekan "Retry Map".',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _isDarkMode
                        ? const Color(0xFFFCD34D)
                        : Colors.orange.shade900,
                  ),
                ),
              ),
            ),
          if (_isDebugAndroidDefaultEmulatorLocation)
            Positioned(
              top: _hasMapLoadIssue ? 164 : 92,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: _cardDecoration(
                  color: _isDarkMode
                      ? const Color(0xFF0B2542)
                      : Colors.blue.shade50,
                  borderColor: _accentColor.withValues(alpha: 0.28),
                ),
                child: Text(
                  _shouldUseAttendanceLocationHint
                      ? 'Emulator mengirim lokasi default Android. Peta disesuaikan ke lokasi absensi agar pengujian tetap relevan.'
                      : 'Emulator mengirim lokasi default Android. Peta diarahkan ke fallback sampai lokasi emulator diatur manual.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _isDarkMode
                        ? const Color(0xFFBFDBFE)
                        : Colors.blue.shade900,
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
              backgroundColor: _surfaceColor,
              foregroundColor: _primaryTextColor,
              child: _isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _accentColor,
                      ),
                    )
                  : Icon(Icons.my_location, color: _primaryTextColor),
            ),
          ),
          if (_isLoading)
            Center(child: CircularProgressIndicator(color: _accentColor)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentPosition != null ? _address : _statusMessage,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: _primaryTextColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Koordinat: $_coordinateLabel',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCard() {
    return Container(
      decoration: _cardDecoration(),
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
                color: _primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: _secondaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _getCurrentLocation,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accentColor,
                      side: BorderSide(
                        color: _accentColor.withValues(alpha: 0.7),
                      ),
                    ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                    ),
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
      color: _mutedSurfaceColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _borderColor),
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
                  color: _primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lokasi tetap berhasil dibaca. Koordinat saat ini:\n${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: _secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
