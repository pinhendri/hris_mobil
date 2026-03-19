import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/attendance_location.dart';

class LocationPickerScreen extends StatefulWidget {
  final AttendanceLocation? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const LatLng _fallbackLatLng = LatLng(-6.2088, 106.8456);
  static const LatLng _defaultEmulatorLatLng = LatLng(37.4219983, -122.084);
  static const String _tileUrlTemplate =
      '${ApiConstants.baseUrl}${ApiConstants.mapTilesEndpoint}';
  static const String _tileFallbackUrlTemplate =
      '${ApiConstants.baseUrl}${ApiConstants.mapTilesProxyEndpoint}';

  final _nameController = TextEditingController();
  final _radiusController = TextEditingController();
  final MapController _mapController = MapController();

  LatLng _selectedPoint = const LatLng(-6.175392, 106.827153); // Default Monas
  double _radius = 100.0;

  bool _isLocating = false;
  bool _isDefaultEmulatorLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _nameController.text = widget.initialLocation!.name;
      _radiusController.text = widget.initialLocation!.radius.toString();
      _selectedPoint = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _radius = widget.initialLocation!.radius;
    } else {
      _radiusController.text = '100.0';
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);

    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied'),
            ),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      if (mounted) {
        final isDefaultEmulatorLocation =
            (position.latitude - _defaultEmulatorLatLng.latitude).abs() <
                0.001 &&
            (position.longitude - _defaultEmulatorLatLng.longitude).abs() <
                0.001;

        if (isDefaultEmulatorLocation) {
          setState(() {
            _selectedPoint = _fallbackLatLng;
            _isLocating = false;
            _isDefaultEmulatorLocation = true;
          });
          _mapController.move(_fallbackLatLng, 15.0);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Koordinat yang terbaca masih lokasi default emulator. Atur lokasi device atau emulator lalu coba lagi.',
              ),
            ),
          );
          return;
        }

        final point = LatLng(position.latitude, position.longitude);
        setState(() {
          _selectedPoint = point;
          _isLocating = false;
          _isDefaultEmulatorLocation = false;
        });
        _mapController.move(point, 15.0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
      setState(() => _isLocating = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  void _handleTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedPoint = point;
      _isDefaultEmulatorLocation = false;
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    final radius = double.tryParse(_radiusController.text);

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location name')),
      );
      return;
    }

    if (radius == null || radius <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid radius')),
      );
      return;
    }

    final location = AttendanceLocation(
      id:
          widget.initialLocation?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      latitude: _selectedPoint.latitude,
      longitude: _selectedPoint.longitude,
      radius: radius,
    );

    Navigator.pop(context, location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialLocation == null ? 'Add Location' : 'Edit Location',
          style: GoogleFonts.poppins(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedPoint,
                    initialZoom: 15.0,
                    onTap: _handleTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _tileUrlTemplate,
                      fallbackUrl: _tileFallbackUrlTemplate,
                      userAgentPackageName: 'com.example.hris_mobile',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _selectedPoint,
                          color: Colors.green.withValues(alpha: 0.3),
                          borderStrokeWidth: 2,
                          borderColor: Colors.green,
                          useRadiusInMeter: true,
                          radius: _radius,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedPoint,
                          width: 40,
                          height: 40,
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
                if (_isDefaultEmulatorLocation)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        'Lokasi device masih membaca koordinat default emulator. Untuk testing di Jakarta, set lokasi emulator atau pilih titik secara manual di peta.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _isLocating ? null : _getCurrentLocation,
                    backgroundColor: Colors.white,
                    child: _isLocating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Location Details',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Location Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'e.g. Warehouse A',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _radiusController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Radius (meters)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixText: 'm',
                  ),
                  onChanged: (value) {
                    final r = double.tryParse(value);
                    if (r != null) {
                      setState(() {
                        _radius = r;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap on the map to change location',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
