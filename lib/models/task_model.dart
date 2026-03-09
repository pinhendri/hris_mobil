class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  bool isCompleted;
  final String priority; // 'high', 'medium', 'low'
  final String type; // 'onboarding', 'offboarding', 'regular'

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    required this.priority,
    required this.type,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: DateTime.parse(json['due_date']),
      isCompleted: json['is_completed'] ?? false,
      priority: json['priority'] ?? 'medium',
      type: json['type'] ?? 'regular',
    );
  }
}
