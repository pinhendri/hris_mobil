class ClaimModel {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String status; // 'pending', 'approved', 'rejected'
  final String type; // 'medical', 'transport', 'meals', 'other'
  final String description;
  final String? attachmentUrl;

  ClaimModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.status,
    required this.type,
    required this.description,
    this.attachmentUrl,
  });

  factory ClaimModel.fromJson(Map<String, dynamic> json) {
    return ClaimModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      date: DateTime.parse(json['date']),
      status: json['status'] ?? 'pending',
      type: json['type'] ?? 'other',
      description: json['description'] ?? '',
      attachmentUrl: json['attachment_url'],
    );
  }
}
