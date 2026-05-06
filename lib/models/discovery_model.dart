class DiscoveryDocument {
  final int id;
  final String name;
  final String type;
  final String category;
  final String format;
  final int sizeBytes;
  final String version;
  final String access;
  final String fileUrl;
  final int downloads;
  final bool discoveryEnabled;
  final String discoverySyncStatus;
  final DateTime? uploadDate;
  final DateTime? discoverySyncedAt;
  final String discoveryLastError;
  final String ocrStatus;
  final String ocrEngine;
  final DateTime? ocrProcessedAt;
  final String ocrLastError;

  const DiscoveryDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.format,
    required this.sizeBytes,
    required this.version,
    required this.access,
    required this.fileUrl,
    required this.downloads,
    required this.discoveryEnabled,
    required this.discoverySyncStatus,
    required this.uploadDate,
    required this.discoverySyncedAt,
    required this.discoveryLastError,
    required this.ocrStatus,
    required this.ocrEngine,
    required this.ocrProcessedAt,
    required this.ocrLastError,
  });

  factory DiscoveryDocument.fromJson(Map<String, dynamic> json) {
    return DiscoveryDocument(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Discovery',
      format: json['format']?.toString() ?? 'other',
      sizeBytes: _parseInt(json['size']),
      version: json['version']?.toString() ?? '',
      access: json['access']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      downloads: _parseInt(json['downloads']),
      discoveryEnabled: json['discovery_enabled'] == true,
      discoverySyncStatus:
          json['discovery_sync_status']?.toString() ?? 'pending',
      uploadDate: _parseDateTime(json['upload_date']),
      discoverySyncedAt: _parseDateTime(json['discovery_synced_at']),
      discoveryLastError: json['discovery_last_error']?.toString() ?? '',
      ocrStatus: json['ocr_status']?.toString() ?? 'pending',
      ocrEngine: json['ocr_engine']?.toString() ?? '',
      ocrProcessedAt: _parseDateTime(json['ocr_processed_at']),
      ocrLastError: json['ocr_last_error']?.toString() ?? '',
    );
  }

  bool get isReady => discoverySyncStatus.toLowerCase() == 'ready';

  bool get isOcrReady => ocrStatus.toLowerCase() == 'ready';

  bool get canUseForBot {
    final status = ocrStatus.toLowerCase();
    return discoveryEnabled && status != 'failed';
  }

  String get ocrStatusLabel {
    switch (ocrStatus.toLowerCase()) {
      case 'ready':
        return 'OCR Ready';
      case 'processing':
        return 'OCR Processing';
      case 'failed':
        return 'OCR Failed';
      case 'pending':
      default:
        return 'OCR Pending';
    }
  }

  String get sizeLabel {
    if (sizeBytes <= 0) {
      return '0 B';
    }

    if (sizeBytes >= 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }

    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    if (sizeBytes >= 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }

    return '$sizeBytes B';
  }
}

class DiscoveryConversation {
  final int id;
  final String uuid;
  final String title;
  final List<int> selectedDocumentIds;
  final DateTime? lastMessageAt;
  final DateTime? updatedAt;

  const DiscoveryConversation({
    required this.id,
    required this.uuid,
    required this.title,
    required this.selectedDocumentIds,
    required this.lastMessageAt,
    required this.updatedAt,
  });

  factory DiscoveryConversation.fromJson(Map<String, dynamic> json) {
    return DiscoveryConversation(
      id: _parseInt(json['id']),
      uuid: json['uuid']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Percakapan Discovery',
      selectedDocumentIds: _parseIntList(json['selected_document_ids']),
      lastMessageAt: _parseDateTime(json['last_message_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }
}

class DiscoveryCitation {
  final String fileId;
  final String filename;
  final int? documentId;
  final String documentName;

  const DiscoveryCitation({
    required this.fileId,
    required this.filename,
    required this.documentId,
    required this.documentName,
  });

  factory DiscoveryCitation.fromJson(Map<String, dynamic> json) {
    return DiscoveryCitation(
      fileId: json['file_id']?.toString() ?? '',
      filename: json['filename']?.toString() ?? '',
      documentId: _parseNullableInt(json['document_id']),
      documentName: json['document_name']?.toString() ?? '',
    );
  }

  String get label {
    if (documentName.isNotEmpty) {
      return documentName;
    }

    if (filename.isNotEmpty) {
      return filename;
    }

    return 'Dokumen sumber';
  }
}

class DiscoveryMessage {
  final int id;
  final String role;
  final String content;
  final List<DiscoveryCitation> citations;
  final DateTime? createdAt;

  const DiscoveryMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.citations,
    required this.createdAt,
  });

  factory DiscoveryMessage.fromJson(Map<String, dynamic> json) {
    final rawCitations = json['citations'];

    return DiscoveryMessage(
      id: _parseInt(json['id']),
      role: json['role']?.toString() ?? 'assistant',
      content: json['content']?.toString() ?? '',
      citations: rawCitations is List
          ? rawCitations
                .whereType<Map>()
                .map(
                  (item) => DiscoveryCitation.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const [],
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  bool get isAssistant => role.toLowerCase() == 'assistant';
}

int _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _parseNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  return int.tryParse(value.toString());
}

DateTime? _parseDateTime(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) {
    return null;
  }

  return DateTime.tryParse(raw);
}

List<int> _parseIntList(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((item) => _parseInt(item))
      .where((item) => item > 0)
      .toSet()
      .toList(growable: false);
}
