class DocumentItem {
  final String id;
  final String title;
  final String type;
  final String category;
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
    final rawFormat =
        json['format']?.toString() ?? json['type']?.toString() ?? 'other';

    return DocumentItem(
      id: json['id']?.toString() ?? '',
      title: json['name']?.toString() ?? json['title']?.toString() ?? '',
      type: _normalizeType(rawFormat),
      category: json['category']?.toString() ?? 'General',
      url: json['file_url']?.toString() ?? json['url']?.toString() ?? '',
      size: _formatSize(json['size']),
      updatedAt: _parseDate(
        json['upload_date'] ?? json['updated_at'] ?? json['created_at'],
      ),
    );
  }

  static DateTime _parseDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) {
      return DateTime.now();
    }

    return DateTime.tryParse(raw) ?? DateTime.now();
  }

  static String _normalizeType(String raw) {
    final value = raw.toLowerCase();

    if (value.contains('pdf')) {
      return 'pdf';
    }

    if (value.contains('doc')) {
      return 'doc';
    }

    if (value.contains('xls')) {
      return 'xls';
    }

    if (value.contains('ppt')) {
      return 'ppt';
    }

    if (value.contains('jpg') ||
        value.contains('jpeg') ||
        value.contains('png') ||
        value.contains('image')) {
      return 'image';
    }

    if (value.contains('txt')) {
      return 'txt';
    }

    return 'other';
  }

  static String _formatSize(dynamic value) {
    if (value == null) {
      return '0 KB';
    }

    if (value is String && value.contains('B')) {
      return value;
    }

    final bytes = value is num ? value.toDouble() : double.tryParse('$value');
    if (bytes == null || bytes <= 0) {
      return '0 KB';
    }

    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}
