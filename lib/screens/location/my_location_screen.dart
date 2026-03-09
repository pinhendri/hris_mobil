import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';

class MyLocationScreen extends StatefulWidget {
  const MyLocationScreen({super.key});

  @override
  State<MyLocationScreen> createState() => _MyLocationScreenState();
}

class _MyLocationScreenState extends State<MyLocationScreen> {
  final MapController _mapController = MapController();

  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;

  LatLng? _lockedLatLng; // 🔒 lokasi awal (anti loncat)
  bool _isLoading = true;
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
    super.dispose();
  }

  // ===============================
  // INIT LOCATION
  // ===============================
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

  // ===============================
  // GET FIRST LOCATION
  // ===============================
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Mencari lokasi...';
    });

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    await _applyPosition(position, moveMap: true);
  }

  // ===============================
  // LOCATION STREAM
  // ===============================
  void _startLocationStream() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      _applyPosition(position, moveMap: false);
    });
  }

  // ===============================
  // APPLY POSITION (ANTI LONCAT)
  // ===============================
  Future<void> _applyPosition(
    Position position, {
    required bool moveMap,
  }) async {
    if (!mounted) return;

    final latLng = LatLng(position.latitude, position.longitude);

    // 🔒 set lokasi awal hanya sekali
    _lockedLatLng ??= latLng;

    // ⛔ tolak lonjakan ekstrem (>30 km)
    final distanceKm = const Distance().as(
      LengthUnit.Kilometer,
      _lockedLatLng!,
      latLng,
    );

    if (distanceKm > 30) {
      debugPrint('⛔ Lonjakan lokasi ditolak: $distanceKm km');
      return;
    }

    setState(() {
      _currentPosition = position;
      _isLoading = false;
      _statusMessage = 'Lokasi ditemukan';
    });

    if (moveMap) {
      _mapController.move(
        latLng,
        _mapController.camera.zoom,
      );
    }

    await _getAddress(latLng.latitude, latLng.longitude);
  }

  // ===============================
  // GET ADDRESS
  // ===============================
  Future<void> _getAddress(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      final p = placemarks.first;

      setState(() {
        _address =
            '${p.street ?? ''}, ${p.subLocality ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''}';
      });
    } catch (_) {
      setState(() {
        _address = 'Alamat tidak tersedia';
      });
    }
  }

  // ===============================
  // SET ERROR
  // ===============================
  void _setError(String message) {
    if (!mounted) return;

    setState(() {
      _statusMessage = message;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ===============================
  // BUILD UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    final LatLng fallback = const LatLng(-6.2088, 106.8456);

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
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition != null
                  ? LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    )
                  : fallback,
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.hris_mobile',
              ),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 50,
                      height: 50,
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
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

          // Card alamat / status
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _currentPosition != null ? _address : _statusMessage,
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
            ),
          ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}