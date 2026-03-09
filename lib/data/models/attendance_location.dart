// lib/data/models/attendance_location.dart
class AttendanceLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
    final String? address; // dalam meter

  AttendanceLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
     this.address,
  });

  factory AttendanceLocation.fromJson(Map<String, dynamic> json) {
    return AttendanceLocation(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      radius: (json['radius'] ?? 100).toDouble(),
         address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
       if (address != null) 'address': address,
    };
  }

  // Copy with method untuk update
  AttendanceLocation copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radius,
     String? address,
  }) {
    return AttendanceLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
            address: address ?? this.address,
    );
  }
}