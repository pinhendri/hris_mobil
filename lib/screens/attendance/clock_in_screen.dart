// lib/screens/attendance/clock_in_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show Distance, LatLng;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/attendance_location.dart';
import '../../services/session_storage.dart';
import 'selfie_camera_screen.dart';

enum _AttendanceCaptureStep { location, photo }

class _LocationValidationState {
  const _LocationValidationState({
    required this.isWithinRange,
    required this.minDistance,
    required this.nearestLocation,
    required this.displayedLocation,
    required this.emulatorTestLocation,
    required this.isUsingEmulatorTestLocation,
  });

  final bool isWithinRange;
  final double minDistance;
  final AttendanceLocation? nearestLocation;
  final AttendanceLocation? displayedLocation;
  final AttendanceLocation? emulatorTestLocation;
  final bool isUsingEmulatorTestLocation;
}

class _PhotoGuidePainter extends CustomPainter {
  const _PhotoGuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final guideWidth = size.width * 0.54;
    final guideHeight = size.height * 0.72;
    final guideLeft = (size.width - guideWidth) / 2;
    final guideTop = size.height * 0.08;
    final guideRect = Rect.fromLTWH(
      guideLeft,
      guideTop,
      guideWidth,
      guideHeight,
    );
    final guideFrame = RRect.fromRectAndRadius(
      guideRect,
      Radius.circular(guideWidth * 0.28),
    );

    canvas.drawRRect(guideFrame, guidePaint);

    final headRadius = guideWidth * 0.16;
    final headCenter = Offset(size.width / 2, guideTop + guideHeight * 0.22);
    canvas.drawCircle(headCenter, headRadius, guidePaint);

    final shoulderWidth = guideWidth * 0.7;
    final shoulderHeight = guideHeight * 0.26;
    final shoulderRect = Rect.fromCenter(
      center: Offset(size.width / 2, guideTop + guideHeight * 0.6),
      width: shoulderWidth,
      height: shoulderHeight,
    );
    final shoulderPath = Path()
      ..moveTo(shoulderRect.left, shoulderRect.bottom)
      ..quadraticBezierTo(
        shoulderRect.left,
        shoulderRect.top,
        size.width / 2,
        shoulderRect.top,
      )
      ..quadraticBezierTo(
        shoulderRect.right,
        shoulderRect.top,
        shoulderRect.right,
        shoulderRect.bottom,
      );
    canvas.drawPath(shoulderPath, guidePaint);

    canvas.drawLine(
      Offset(size.width / 2, shoulderRect.top + 8),
      Offset(size.width / 2, guideRect.bottom - 18),
      guidePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ClockInScreen extends StatefulWidget {
  const ClockInScreen({super.key, this.isClockOut = false});

  final bool isClockOut;

  @override
  State<ClockInScreen> createState() => _ClockInScreenState();
}

class _ClockInScreenState extends State<ClockInScreen> {
  static const LatLng _fallbackLatLng = LatLng(-6.2088, 106.8456);
  static const LatLng _defaultEmulatorLatLng = LatLng(37.4219983, -122.084);
  static const String _tileUrlTemplate =
      ApiConstants.openStreetMapTilesEndpoint;
  static const String _tileFallbackUrlTemplate =
      '${ApiConstants.baseUrl}${ApiConstants.mapTilesProxyEndpoint}';

  File? _photo;
  String? _photoBase64;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _isMockLocation = false;
  String _locationError = '';
  StreamSubscription<Position>? _positionStream;
  bool _isPhotoTaken = false;
  bool _isOpeningCamera = false;
  bool _isMapReady = false;
  bool _isLoadingAttendanceArea = true;
  String _employeeUuid = '';
  String _activeCompanyCode = '';
  _AttendanceCaptureStep _captureStep = _AttendanceCaptureStep.location;

  final MapController _mapController = MapController();

  bool get _isClockOutMode => widget.isClockOut;
  String get _actionLabel => _isClockOutMode ? 'Clock Out' : 'Clock In';
  String get _actionLabelLower => _isClockOutMode ? 'clock out' : 'clock in';
  bool get _hasEmployeeContext => _employeeUuid.isNotEmpty;
  bool get _hasCompanyContext => _activeCompanyCode.isNotEmpty;
  bool get _isPhotoStep => _captureStep == _AttendanceCaptureStep.photo;
  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;
  Color get _screenBackgroundColor =>
      _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF6F7FB);
  Color get _surfaceColor =>
      _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _surfaceBorderColor =>
      _isDarkMode ? const Color(0xFF303030) : Colors.grey.shade200;
  Color get _primaryTextColor => _isDarkMode ? Colors.white : Colors.black87;
  Color get _secondaryTextColor =>
      _isDarkMode ? Colors.white70 : Colors.grey.shade700;
  Color get _disabledButtonColor =>
      _isDarkMode ? const Color(0xFF3A3A3A) : Colors.grey.shade300;
  Color get _mapOverlayColor => _isDarkMode
      ? const Color(0xEE1F1F1F)
      : Colors.white.withValues(alpha: 0.96);
  List<BoxShadow> get _cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: _isDarkMode ? 0.22 : 0.06),
      blurRadius: _isDarkMode ? 14 : 16,
      offset: const Offset(0, 6),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _prepareAttendanceAction();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _prepareAttendanceAction() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final employeeUuid =
        (await provider.resolveCurrentEmployeeUuid())?.trim() ?? '';
    final companyCode = authProvider.getCompanyCode().trim();

    setState(() {
      _employeeUuid = employeeUuid;
      _activeCompanyCode = companyCode;
      _captureStep = _AttendanceCaptureStep.location;
      _isLoadingAttendanceArea = true;
      _isLoadingLocation = true;
      _locationError = '';
    });

    if (employeeUuid.isEmpty) {
      setState(() {
        _locationError =
            'Employee ID tidak ditemukan. Attendance tidak bisa dilakukan.';
        _isLoadingLocation = false;
        _isLoadingAttendanceArea = false;
      });
      return;
    }

    if (companyCode.isEmpty) {
      setState(() {
        _locationError =
            'C_CODE aktif tidak ditemukan. Pilih company aktif terlebih dahulu.';
        _isLoadingLocation = false;
        _isLoadingAttendanceArea = false;
      });
      return;
    }

    try {
      await SessionStorage.saveCompanyCode(companyCode);
      await authProvider.syncSelectedCompanyContext();
      unawaited(_startLocationStream());
      await provider.loadLocations(forceRefresh: true);
      _updateMapViewport(provider.allowedLocations);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAttendanceArea = false;
        });
      }
    }
  }

  Future<void> _startLocationStream() async {
    await _positionStream?.cancel();
    _positionStream = null;

    if (!_hasEmployeeContext || !_hasCompanyContext) {
      setState(() {
        _isLoadingLocation = false;
      });
      return;
    }

    setState(() {
      _isLoadingLocation = true;
      _locationError = '';
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

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      );

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              if (mounted) _updatePosition(position);
            },
            onError: (Object error) {
              if (!mounted) return;

              setState(() {
                _locationError = 'Gagal memperbarui lokasi: $error';
                _isLoadingLocation = false;
              });
            },
          );

      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null && mounted) {
        _updatePosition(lastKnownPosition);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      ).timeout(const Duration(seconds: 12));

      if (mounted) _updatePosition(position);
    } on TimeoutException {
      print('Location timeout while getting current position');
      if (mounted) {
        setState(() {
          _locationError =
              'Lokasi belum berhasil didapatkan. Peta tetap ditampilkan, lalu tekan refresh jika perlu.';
          _isLoadingLocation = false;
        });
      }
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

    final isDefaultEmulatorLocation =
        (position.latitude - _defaultEmulatorLatLng.latitude).abs() < 0.001 &&
        (position.longitude - _defaultEmulatorLatLng.longitude).abs() < 0.001;

    setState(() {
      _currentPosition = position;
      _isLoadingLocation = false;
      _isMockLocation = position.isMocked;
      _locationError = position.isMocked
          ? 'Mock GPS terdeteksi. Nonaktifkan mock location untuk melanjutkan.'
          : isDefaultEmulatorLocation
          ? 'Lokasi yang terbaca masih lokasi default emulator. Atur lokasi device atau emulator, lalu refresh.'
          : '';
    });

    _updateMapViewport(
      Provider.of<AttendanceProvider>(context, listen: false).allowedLocations,
    );
  }

  Future<void> _takePhoto() async {
    if (_isOpeningCamera) {
      return;
    }

    try {
      _isOpeningCamera = true;

      final String? imagePath = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => SelfieCameraScreen(title: 'Ambil Foto $_actionLabel'),
        ),
      );

      if (!mounted) {
        return;
      }

      if (imagePath != null) {
        final file = File(imagePath);
        final bytes = await file.readAsBytes();
        final base64Image = base64Encode(bytes);

        if (!mounted) {
          return;
        }

        setState(() {
          _photo = file;
          _photoBase64 = base64Image;
          _isPhotoTaken = true;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isOpeningCamera = false;
    }
  }

  double _calculateDistance(AttendanceLocation location) {
    if (_currentPosition == null) return double.infinity;

    const distanceCalculator = Distance();
    return distanceCalculator(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      LatLng(location.latitude, location.longitude),
    );
  }

  AttendanceLocation? _nearestAllowedLocation(
    List<AttendanceLocation> allowedLocations,
  ) {
    if (allowedLocations.isEmpty) {
      return null;
    }

    if (_currentPosition == null) {
      return allowedLocations.first;
    }

    AttendanceLocation? nearestLocation;
    double minDistance = double.infinity;

    for (final location in allowedLocations) {
      final distance = _calculateDistance(location);
      if (distance < minDistance) {
        minDistance = distance;
        nearestLocation = location;
      }
    }

    return nearestLocation ?? allowedLocations.first;
  }

  void _updateMapViewport(List<AttendanceLocation> allowedLocations) {
    if (!_isMapReady) {
      return;
    }

    final focusLocation = _nearestAllowedLocation(allowedLocations);
    final userPoint = _hasValidCurrentLocation ? _currentLatLng : null;
    final officePoint = focusLocation == null
        ? null
        : LatLng(focusLocation.latitude, focusLocation.longitude);

    try {
      if (userPoint != null && officePoint != null) {
        final samePoint =
            (userPoint.latitude - officePoint.latitude).abs() < 0.00005 &&
            (userPoint.longitude - officePoint.longitude).abs() < 0.00005;

        if (samePoint) {
          _mapController.move(userPoint, 16.5);
          return;
        }

        _mapController.fitCamera(
          CameraFit.coordinates(
            coordinates: [userPoint, officePoint],
            padding: const EdgeInsets.all(48),
            maxZoom: 16.5,
          ),
        );
        return;
      }

      if (userPoint != null) {
        _mapController.move(userPoint, 16.0);
        return;
      }

      if (officePoint != null) {
        _mapController.move(officePoint, 16.0);
      }
    } catch (e) {
      print('Error updating map viewport: $e');
    }
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = '';
    });
    try {
      await Provider.of<AttendanceProvider>(
        context,
        listen: false,
      ).loadLocations(forceRefresh: true);

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

  LatLng get _currentLatLng {
    final position = _currentPosition;
    if (position == null || _isLikelyDefaultEmulatorLocation) {
      return _fallbackLatLng;
    }

    return LatLng(position.latitude, position.longitude);
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

  bool get _hasValidCurrentLocation =>
      _currentPosition != null && !_isLikelyDefaultEmulatorLocation;

  String _formatCoordinate(double value) => value.toStringAsFixed(6);

  AttendanceLocation? _emulatorTestLocation(
    List<AttendanceLocation> allowedLocations,
  ) {
    if (!Platform.isAndroid ||
        kReleaseMode ||
        !_isLikelyDefaultEmulatorLocation ||
        allowedLocations.isEmpty) {
      return null;
    }

    return allowedLocations.first;
  }

  _LocationValidationState _resolveLocationValidationState(
    List<AttendanceLocation> allowedLocations,
  ) {
    final emulatorTestLocation = _emulatorTestLocation(allowedLocations);
    final isUsingEmulatorTestLocation = emulatorTestLocation != null;

    bool isWithinRange = false;
    double minDistance = double.infinity;
    AttendanceLocation? nearestLocation;

    if (isUsingEmulatorTestLocation) {
      isWithinRange = true;
      minDistance = 0;
      nearestLocation = emulatorTestLocation;
    } else if (_currentPosition != null && allowedLocations.isNotEmpty) {
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

    return _LocationValidationState(
      isWithinRange: isWithinRange,
      minDistance: minDistance,
      nearestLocation: nearestLocation,
      displayedLocation:
          nearestLocation ??
          (allowedLocations.isNotEmpty ? allowedLocations.first : null),
      emulatorTestLocation: emulatorTestLocation,
      isUsingEmulatorTestLocation: isUsingEmulatorTestLocation,
    );
  }

  String? _locationValidationMessage(
    _LocationValidationState state, {
    required bool isPreparingAttendanceArea,
  }) {
    if (!_hasEmployeeContext) {
      return 'Employee ID tidak ditemukan.';
    }

    if (!_hasCompanyContext) {
      return 'C_CODE aktif tidak ditemukan.';
    }

    if (isPreparingAttendanceArea) {
      return 'Area absensi masih dimuat dari server.';
    }

    if (state.displayedLocation == null) {
      return 'Lokasi absensi belum tersedia.';
    }

    if (_isLikelyDefaultEmulatorLocation &&
        !state.isUsingEmulatorTestLocation) {
      return 'Lokasi device masih memakai koordinat default emulator.';
    }

    if (_currentPosition == null && !state.isUsingEmulatorTestLocation) {
      return 'Lokasi tidak tersedia.';
    }

    if (_isMockLocation) {
      return 'Mock GPS terdeteksi. Clock in/clock out tidak dapat dilanjutkan.';
    }

    if (!state.isWithinRange) {
      return 'Anda berada di luar area yang diizinkan untuk $_actionLabelLower.';
    }

    return null;
  }

  String? _photoStepValidationMessage(
    _LocationValidationState state, {
    required bool isPreparingAttendanceArea,
  }) {
    final locationMessage = _locationValidationMessage(
      state,
      isPreparingAttendanceArea: isPreparingAttendanceArea,
    );
    if (locationMessage != null) {
      return locationMessage;
    }

    if (!_isPhotoTaken || _photoBase64 == null) {
      return 'Ambil foto terlebih dahulu.';
    }

    return null;
  }

  void _showFeedback(String message, {Color color = Colors.orange}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _goToPhotoStep() {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final state = _resolveLocationValidationState(provider.allowedLocations);
    final isPreparingAttendanceArea =
        _isLoadingAttendanceArea && provider.allowedLocations.isEmpty;
    final validationMessage = _locationValidationMessage(
      state,
      isPreparingAttendanceArea: isPreparingAttendanceArea,
    );

    if (validationMessage != null) {
      _showFeedback(validationMessage);
      return;
    }

    setState(() {
      _captureStep = _AttendanceCaptureStep.photo;
    });

    if (!_isPhotoTaken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isPhotoStep && !_isPhotoTaken) {
          unawaited(_takePhoto());
        }
      });
    }
  }

  Future<void> _submitAttendance() async {
    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final locationState = _resolveLocationValidationState(
      provider.allowedLocations,
    );
    final emulatorTestLocation = locationState.emulatorTestLocation;
    final isPreparingAttendanceArea =
        _isLoadingAttendanceArea && provider.allowedLocations.isEmpty;
    final validationMessage = _photoStepValidationMessage(
      locationState,
      isPreparingAttendanceArea: isPreparingAttendanceArea,
    );

    if (validationMessage != null) {
      _showFeedback(
        validationMessage,
        color: validationMessage.contains('tidak ditemukan')
            ? Colors.red
            : Colors.orange,
      );
      if (!_hasEmployeeContext || !_hasCompanyContext) {
        setState(() {
          _captureStep = _AttendanceCaptureStep.location;
        });
      }
      return;
    }

    if (!_isPhotoTaken || _photoBase64 == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Foto wajib diambil'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isLikelyDefaultEmulatorLocation && emulatorTestLocation == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Lokasi device masih memakai koordinat default emulator. Atur lokasi device atau emulator dulu.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentPosition == null && emulatorTestLocation == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Lokasi tidak tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isMockLocation) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Mock GPS terdeteksi. Nonaktifkan mock location untuk melanjutkan.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final submitLatitude =
        emulatorTestLocation?.latitude ?? _currentPosition!.latitude;
    final submitLongitude =
        emulatorTestLocation?.longitude ?? _currentPosition!.longitude;
    final success = _isClockOutMode
        ? await provider.clockOut(
            employeeUuid: _employeeUuid,
            latitude: submitLatitude,
            longitude: submitLongitude,
            location: '$submitLatitude, $submitLongitude',
            photo: _photoBase64,
          )
        : await provider.clockIn(
            employeeUuid: _employeeUuid,
            latitude: submitLatitude,
            longitude: submitLongitude,
            location: '$submitLatitude, $submitLongitude',
            photo: _photoBase64,
          );

    if (!mounted) return;

    navigator.pop();

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.lastActionMessage ??
                (_isClockOutMode ? 'Clock Out Berhasil' : 'Clock In Berhasil'),
          ),
          backgroundColor: provider.lastActionQueued
              ? Colors.orange
              : Colors.green,
        ),
      );
      navigator.pop(true);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.error ??
                (_isClockOutMode ? 'Clock Out Gagal' : 'Clock In Gagal'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    final allowedLocations = provider.allowedLocations;
    final locationState = _resolveLocationValidationState(allowedLocations);
    final isPreparingAttendanceArea =
        _isLoadingAttendanceArea && allowedLocations.isEmpty;
    final initialCenter = locationState.isUsingEmulatorTestLocation
        ? LatLng(
            locationState.emulatorTestLocation!.latitude,
            locationState.emulatorTestLocation!.longitude,
          )
        : _currentLatLng;
    final locationBlockingMessage = _locationValidationMessage(
      locationState,
      isPreparingAttendanceArea: isPreparingAttendanceArea,
    );
    final photoBlockingMessage = _photoStepValidationMessage(
      locationState,
      isPreparingAttendanceArea: isPreparingAttendanceArea,
    );
    final isSubmitting = _isClockOutMode
        ? provider.isClockingOut
        : provider.isClockingIn;

    final circles = allowedLocations
        .map(
          (loc) => CircleMarker(
            point: LatLng(loc.latitude, loc.longitude),
            color: Colors.green.withValues(alpha: 0.3),
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
      backgroundColor: _screenBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isPhotoStep
              ? 'Ambil Foto $_actionLabel'
              : 'Cek Lokasi $_actionLabel',
          style: GoogleFonts.poppins(color: _primaryTextColor),
        ),
        backgroundColor: _surfaceColor,
        foregroundColor: _primaryTextColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _primaryTextColor),
          onPressed: () {
            if (_isPhotoStep) {
              setState(() {
                _captureStep = _AttendanceCaptureStep.location;
              });
              return;
            }
            Navigator.pop(context);
          },
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _isPhotoStep
            ? _buildPhotoStep(
                key: const ValueKey('attendance-photo-step'),
                locationState: locationState,
                blockingMessage: photoBlockingMessage,
                isSubmitting: isSubmitting,
              )
            : _buildLocationStep(
                key: const ValueKey('attendance-location-step'),
                locationState: locationState,
                isPreparingAttendanceArea: isPreparingAttendanceArea,
                initialCenter: initialCenter,
                circles: circles,
                locationMarkers: locationMarkers,
                blockingMessage: locationBlockingMessage,
              ),
      ),
    );
  }

  Widget _buildLocationStep({
    required Key key,
    required _LocationValidationState locationState,
    required bool isPreparingAttendanceArea,
    required LatLng initialCenter,
    required List<CircleMarker> circles,
    required List<Marker> locationMarkers,
    required String? blockingMessage,
  }) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepCard(
            stepNumber: '1',
            title: 'Verifikasi Lokasi',
            description:
                'Pastikan Anda sudah berada di area absensi sebelum $_actionLabelLower.',
            icon: Icons.location_on_outlined,
            accentColor: Colors.blue,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Lokasi Anda',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primaryTextColor,
                ),
              ),
              const Spacer(),
              if (_isMockLocation)
                _buildBadge('Mock GPS Terdeteksi', Colors.red),
              if (_hasCompanyContext) ...[
                const SizedBox(width: 8),
                _buildBadge(_activeCompanyCode, Colors.blue),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (locationState.isUsingEmulatorTestLocation)
            _buildInfoCard(
              text:
                  'Mode testing emulator aktif. Koordinat absensi akan memakai lokasi "${locationState.emulatorTestLocation!.name}".',
              color: Colors.green,
            )
          else if (_isLikelyDefaultEmulatorLocation)
            _buildInfoCard(
              text:
                  'Koordinat yang terbaca masih lokasi default emulator. Perbarui lokasi device lalu refresh.',
              color: Colors.blue,
            ),
          if (locationState.isUsingEmulatorTestLocation ||
              _isLikelyDefaultEmulatorLocation)
            const SizedBox(height: 12),
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _surfaceBorderColor),
              boxShadow: _cardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 16.0,
                    onMapReady: () {
                      setState(() {
                        _isMapReady = true;
                      });
                      _updateMapViewport(
                        Provider.of<AttendanceProvider>(
                          context,
                          listen: false,
                        ).allowedLocations,
                      );
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _tileUrlTemplate,
                      fallbackUrl: _tileFallbackUrlTemplate,
                      userAgentPackageName: 'com.example.hris_mobile',
                    ),
                    if (circles.isNotEmpty) CircleLayer(circles: circles),
                    MarkerLayer(
                      markers: [
                        if (_hasValidCurrentLocation)
                          Marker(
                            point: _currentLatLng,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.red,
                              size: 40,
                            ),
                          )
                        else if (locationState.isUsingEmulatorTestLocation)
                          Marker(
                            point: LatLng(
                              locationState.emulatorTestLocation!.latitude,
                              locationState.emulatorTestLocation!.longitude,
                            ),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.orange,
                              size: 40,
                            ),
                          ),
                        ...locationMarkers,
                      ],
                    ),
                    RichAttributionWidget(
                      attributions: const [
                        TextSourceAttribution('OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
                if (isPreparingAttendanceArea)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: _buildMapOverlayCard(
                      message: 'Memuat area absensi dari server...',
                      color: Colors.orange,
                      showSpinner: true,
                    ),
                  )
                else if (_isLoadingLocation && _currentPosition == null)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: _buildMapOverlayCard(
                      message: 'Mencari lokasi Anda...',
                      color: Colors.blue,
                      showSpinner: true,
                    ),
                  ),
                if (_locationError.isNotEmpty && _currentPosition == null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: _buildMapOverlayCard(
                      message: _locationError,
                      color: Colors.red,
                      onRetry: _hasEmployeeContext && _hasCompanyContext
                          ? _startLocationStream
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          if (_currentPosition != null && !_isLoadingLocation)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: FloatingActionButton.small(
                  heroTag: 'attendance-refresh-location',
                  onPressed: _refreshLocation,
                  backgroundColor: _surfaceColor,
                  foregroundColor: _isDarkMode
                      ? Colors.blue.shade300
                      : Colors.blue,
                  child: const Icon(Icons.my_location),
                ),
              ),
            ),
          if (_currentPosition != null ||
              locationState.displayedLocation != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _buildLocationComparisonCard(locationState),
            ),
          const SizedBox(height: 14),
          _buildLocationStatusCard(
            locationState,
            isPreparingAttendanceArea: isPreparingAttendanceArea,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: blockingMessage == null ? _goToPhotoStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: _disabledButtonColor,
              ),
              child: Text(
                'Lanjut ke Foto',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (blockingMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                blockingMessage,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: blockingMessage.contains('tidak ditemukan')
                      ? (_isDarkMode ? Colors.red.shade300 : Colors.red)
                      : (_isDarkMode ? Colors.orange.shade300 : Colors.orange),
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoStep({
    required Key key,
    required _LocationValidationState locationState,
    required String? blockingMessage,
    required bool isSubmitting,
  }) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepCard(
            stepNumber: '2',
            title: 'Ambil Foto',
            description:
                'Setelah foto berhasil diambil, absensi baru akan dikirim dan data diperbarui.',
            icon: Icons.camera_alt_outlined,
            accentColor: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _surfaceBorderColor),
              boxShadow: _cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locationState.displayedLocation?.name ??
                      'Lokasi absensi belum tersedia',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _primaryTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentPosition != null
                      ? 'Lokasi Anda: ${_formatCoordinate(_currentPosition!.latitude)}, ${_formatCoordinate(_currentPosition!.longitude)}'
                      : 'Lokasi Anda belum tersedia',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _secondaryTextColor,
                  ),
                ),
                if (locationState.displayedLocation != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Lokasi absensi: ${_formatCoordinate(locationState.displayedLocation!.latitude)}, ${_formatCoordinate(locationState.displayedLocation!.longitude)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _secondaryTextColor,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _buildBadge(
                  _isMockLocation
                      ? 'Mock GPS Terdeteksi'
                      : locationState.isUsingEmulatorTestLocation
                      ? 'Mode Test Emulator'
                      : locationState.isWithinRange
                      ? 'Lokasi Sudah Sesuai'
                      : 'Lokasi Belum Sesuai',
                  _isMockLocation
                      ? Colors.red
                      : locationState.isUsingEmulatorTestLocation ||
                            locationState.isWithinRange
                      ? Colors.green
                      : Colors.red,
                ),
              ],
            ),
          ),
          if (blockingMessage != null &&
              !blockingMessage.contains('foto terlebih dahulu')) ...[
            const SizedBox(height: 12),
            _buildInfoCard(
              text: blockingMessage,
              color: _isMockLocation ? Colors.red : Colors.orange,
            ),
          ],
          const SizedBox(height: 16),
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? const Color(0xFF242424)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _surfaceBorderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildPhotoPreview(),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt),
            label: Text(_photo != null ? 'Ambil Ulang Foto' : 'Ambil Foto'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (_isPhotoTaken ? Colors.green : Colors.orange).withValues(
                alpha: _isDarkMode ? 0.16 : 0.1,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (_isPhotoTaken ? Colors.green : Colors.orange)
                    .withValues(alpha: _isDarkMode ? 0.3 : 0.18),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isPhotoTaken ? Icons.check_circle : Icons.camera_alt,
                  color: _isPhotoTaken
                      ? (_isDarkMode ? Colors.green.shade300 : Colors.green)
                      : (_isDarkMode ? Colors.orange.shade300 : Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isPhotoTaken
                        ? 'Foto sudah siap untuk dikirim.'
                        : 'Ambil foto untuk melanjutkan $_actionLabelLower.',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: _isPhotoTaken
                          ? (_isDarkMode ? Colors.green.shade300 : Colors.green)
                          : (_isDarkMode
                                ? Colors.orange.shade300
                                : Colors.orange),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: blockingMessage == null && !isSubmitting
                  ? _submitAttendance
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: _disabledButtonColor,
              ),
              child: Text(
                isSubmitting ? 'Memproses...' : _actionLabel,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _captureStep = _AttendanceCaptureStep.location;
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: _isDarkMode
                  ? Colors.blue.shade300
                  : AppColors.primary,
            ),
            icon: const Icon(Icons.chevron_left),
            label: const Text('Kembali cek lokasi'),
          ),
          if (blockingMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                blockingMessage,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: blockingMessage.contains('foto')
                      ? (_isDarkMode ? Colors.orange.shade300 : Colors.orange)
                      : (_isDarkMode ? Colors.red.shade300 : Colors.red),
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationComparisonCard(_LocationValidationState locationState) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceBorderColor),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perbandingan Lokasi',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: _primaryTextColor,
            ),
          ),
          const SizedBox(height: 10),
          if (_currentPosition != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.person_pin_circle,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lokasi Anda\n${_formatCoordinate(_currentPosition!.latitude)}, ${_formatCoordinate(_currentPosition!.longitude)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          if (_currentPosition != null &&
              locationState.displayedLocation != null)
            const SizedBox(height: 10),
          if (locationState.displayedLocation != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.business, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lokasi Absensi${locationState.displayedLocation == locationState.nearestLocation ? " Terdekat" : ""}\n${locationState.displayedLocation!.name}\n${_formatCoordinate(locationState.displayedLocation!.latitude)}, ${_formatCoordinate(locationState.displayedLocation!.longitude)}\nRadius ${locationState.displayedLocation!.radius.toStringAsFixed(0)} m',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLocationStatusCard(
    _LocationValidationState locationState, {
    required bool isPreparingAttendanceArea,
  }) {
    final isLoading = _isLoadingLocation || isPreparingAttendanceArea;
    final isMockBlocked = _isMockLocation;
    final isSuccess =
        !isMockBlocked &&
        (locationState.isUsingEmulatorTestLocation ||
            locationState.isWithinRange);
    final isWarning = _isLikelyDefaultEmulatorLocation && !isSuccess;
    final icon = isLoading
        ? Icons.hourglass_empty
        : isMockBlocked
        ? Icons.gpp_bad_rounded
        : isSuccess
        ? Icons.check_circle
        : isWarning
        ? Icons.warning_amber_rounded
        : Icons.error;
    final accentColor = isLoading
        ? Colors.orange
        : isMockBlocked
        ? Colors.red
        : isSuccess
        ? Colors.green
        : isWarning
        ? Colors.orange
        : Colors.red;
    final backgroundColor = accentColor.withValues(
      alpha: _isDarkMode ? 0.16 : 0.1,
    );
    final title = isPreparingAttendanceArea
        ? 'Memuat Area Absensi'
        : _isLoadingLocation
        ? 'Mencari Lokasi Device'
        : isMockBlocked
        ? 'Mock GPS Terdeteksi'
        : locationState.isUsingEmulatorTestLocation
        ? 'Mode Test Emulator'
        : isWarning
        ? 'Lokasi Device Belum Valid'
        : locationState.isWithinRange
        ? 'Dalam Jangkauan'
        : 'Luar Jangkauan';
    final subtitle = isPreparingAttendanceArea
        ? 'Sedang memuat area absensi dari server...'
        : _isLoadingLocation
        ? 'Sedang mencari koordinat device Anda...'
        : isMockBlocked
        ? 'Clock in dan clock out diblokir saat lokasi palsu atau mock GPS terdeteksi.'
        : locationState.isUsingEmulatorTestLocation
        ? 'Koordinat absensi untuk testing diambil dari ${locationState.emulatorTestLocation?.name}.'
        : isWarning
        ? 'Lokasi masih membaca koordinat default emulator. Refresh setelah lokasi device diperbarui.'
        : _currentPosition != null
        ? '${locationState.minDistance == double.infinity ? "?" : locationState.minDistance.toStringAsFixed(0)}m dari ${locationState.nearestLocation?.name ?? "lokasi terdekat"}'
        : 'Lokasi Anda belum tersedia.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_photo != null)
          Image.file(_photo!, fit: BoxFit.cover)
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _isDarkMode
                    ? const [Color(0xFF2E2E2E), Color(0xFF232323)]
                    : [Colors.grey.shade300, Colors.grey.shade200],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 54,
                  color: _isDarkMode ? Colors.white54 : Colors.grey,
                ),
                const SizedBox(height: 10),
                Text(
                  'Foto belum diambil',
                  style: GoogleFonts.poppins(
                    color: _secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        Container(
          color: Colors.black.withValues(alpha: _photo != null ? 0.14 : 0.08),
        ),
        const IgnorePointer(
          child: CustomPaint(
            painter: _PhotoGuidePainter(),
            child: SizedBox.expand(),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Posisikan wajah dan bahu di dalam garis putih.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (_photo != null)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildMapOverlayCard({
    required String message,
    required Color color,
    bool showSpinner = false,
    Future<void> Function()? onRetry,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _mapOverlayColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: _cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSpinner)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else
            Icon(Icons.info_outline, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _primaryTextColor,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => unawaited(onRetry()),
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: _isDarkMode ? 0.28 : 0.18),
        ),
        boxShadow: _cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: _isDarkMode ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: accentColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: _isDarkMode ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: _isDarkMode ? 0.34 : 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _isDarkMode ? _primaryTextColor : color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
