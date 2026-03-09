class Attendance {
  final String uuid;
  final String date;
  final String? clockIn;
  final String? clockOut;
  final String? clockInLocation;
  final String? clockOutLocation;
  final String? status;
  final String? clockInPhoto;

  Attendance({
    required this.uuid,
    required this.date,
    this.clockIn,
    this.clockOut,
    this.clockInLocation,
    this.clockOutLocation,
    this.status,
    this.clockInPhoto,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      uuid: json['uuid'] ?? '',
      date: json['date'] ?? '',
      clockIn: json['clock_in'],
      clockOut: json['clock_out'],
      clockInLocation: json['clock_in_location'],
      clockOutLocation: json['clock_out_location'],
      status: json['status'] ?? 'Absent',
      clockInPhoto: json['clock_in_photo'],
    );
  }
}
