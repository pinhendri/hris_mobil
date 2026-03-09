class TrainingModel {
  final String id;
  final String title;
  final String instructor;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'upcoming', 'ongoing', 'completed'
  final double progress; // 0.0 to 1.0
  final String type; // 'online', 'offline'
  final String location;

  TrainingModel({
    required this.id,
    required this.title,
    required this.instructor,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.progress,
    required this.type,
    required this.location,
  });

  factory TrainingModel.fromJson(Map<String, dynamic> json) {
    return TrainingModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      instructor: json['instructor'] ?? '',
      description: json['description'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'] ?? 'upcoming',
      progress: (json['progress'] ?? 0).toDouble(),
      type: json['type'] ?? 'online',
      location: json['location'] ?? '',
    );
  }
}
