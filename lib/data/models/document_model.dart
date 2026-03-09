class DocumentItem {
  final String id;
  final String title;
  final String type; // 'pdf', 'doc', 'image', 'other'
  final String category; // 'Policy', 'Form', 'Handbook', 'Contract'
  final String url;
  final String size;
  final DateTime updatedAt;

  DocumentItem({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.url,
    required this.size,
    required this.updatedAt,
  });

  factory DocumentItem.fromJson(Map<String, dynamic> json) {
    return DocumentItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'other',
      category: json['category'] ?? 'General',
      url: json['url'] ?? '',
      size: json['size'] ?? '0 KB',
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
