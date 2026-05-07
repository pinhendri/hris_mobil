enum BotMode {
  askSystem('ask-system'),
  askDocs('ask-docs'),
  takeAction('take-action');

  const BotMode(this.apiValue);

  final String apiValue;
}

extension BotModeX on BotMode {
  String get label {
    switch (this) {
      case BotMode.askSystem:
        return 'Tanya Sistem';
      case BotMode.askDocs:
        return 'Tanya Dokumen';
      case BotMode.takeAction:
        return 'Buat Aksi';
    }
  }

  String get description {
    switch (this) {
      case BotMode.askSystem:
        return 'Profil, claim, cuti, dan data HR pribadi.';
      case BotMode.askDocs:
        return 'Cari jawaban dari dokumen OCR perusahaan.';
      case BotMode.takeAction:
        return 'Siapkan draft claim, lembur, dan cuti.';
    }
  }
}

BotMode botModeFromRaw(dynamic value) {
  final normalized = value?.toString().trim().toLowerCase();

  switch (normalized) {
    case 'ask-docs':
      return BotMode.askDocs;
    case 'take-action':
      return BotMode.takeAction;
    case 'ask-system':
    default:
      return BotMode.askSystem;
  }
}

class BotQuickAction {
  const BotQuickAction({
    required this.id,
    required this.label,
    required this.mode,
  });

  final String id;
  final String label;
  final BotMode mode;

  factory BotQuickAction.fromJson(Map<String, dynamic> json) {
    return BotQuickAction(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      mode: botModeFromRaw(json['mode']),
    );
  }
}

class BotCapabilities {
  const BotCapabilities({
    required this.modes,
    required this.quickActions,
    required this.tools,
    required this.permissions,
    required this.docsConfigured,
    required this.docsEngine,
  });

  final List<BotMode> modes;
  final List<BotQuickAction> quickActions;
  final List<String> tools;
  final List<String> permissions;
  final bool docsConfigured;
  final String docsEngine;

  factory BotCapabilities.fromJson(Map<String, dynamic> json) {
    final ai = json['ai'] is Map
        ? Map<String, dynamic>.from(json['ai'] as Map)
        : <String, dynamic>{};

    final parsedModes = (json['modes'] as List? ?? const [])
        .map(botModeFromRaw)
        .toSet()
        .toList(growable: false);

    return BotCapabilities(
      modes: parsedModes.isEmpty ? const [BotMode.askSystem] : parsedModes,
      quickActions: (json['quick_actions'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => BotQuickAction.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false),
      tools: _parseStringList(json['tools']),
      permissions: _parseStringList(json['permissions']),
      docsConfigured: ai['docs_configured'] == true,
      docsEngine: ai['docs_engine']?.toString() ?? '',
    );
  }
}

class BotSession {
  const BotSession({
    required this.uuid,
    required this.title,
    required this.mode,
    required this.status,
    required this.context,
    required this.lastMessageAt,
    required this.updatedAt,
  });

  final String uuid;
  final String title;
  final BotMode mode;
  final String status;
  final Map<String, dynamic> context;
  final DateTime? lastMessageAt;
  final DateTime? updatedAt;

  factory BotSession.fromJson(Map<String, dynamic> json) {
    return BotSession(
      uuid: json['uuid']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Session BOT',
      mode: botModeFromRaw(json['mode']),
      status: json['status']?.toString() ?? 'pending',
      context: json['context'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['context'] as Map<String, dynamic>)
          : <String, dynamic>{},
      lastMessageAt: _parseDateTime(json['last_message_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  BotSession copyWith({
    String? uuid,
    String? title,
    BotMode? mode,
    String? status,
    Map<String, dynamic>? context,
    DateTime? lastMessageAt,
    DateTime? updatedAt,
  }) {
    return BotSession(
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      context: context ?? this.context,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BotSource {
  const BotSource({
    required this.type,
    required this.label,
    required this.ref,
    required this.documentId,
    required this.fileId,
    required this.metadata,
  });

  final String type;
  final String label;
  final String? ref;
  final int? documentId;
  final String? fileId;
  final Map<String, dynamic> metadata;

  factory BotSource.fromJson(Map<String, dynamic> json) {
    return BotSource(
      type: json['type']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Sumber',
      ref: json['ref']?.toString(),
      documentId: _parseNullableInt(json['document_id']),
      fileId: json['file_id']?.toString(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['metadata'] as Map<String, dynamic>)
          : <String, dynamic>{},
    );
  }
}

class BotMessage {
  const BotMessage({
    required this.uuid,
    required this.role,
    required this.mode,
    required this.content,
    required this.contentFormat,
    required this.status,
    required this.requiredFields,
    required this.warnings,
    required this.capabilitiesUsed,
    required this.actionPreviewUuid,
    required this.sources,
    required this.createdAt,
  });

  final String uuid;
  final String role;
  final BotMode mode;
  final String content;
  final String contentFormat;
  final String status;
  final List<String> requiredFields;
  final List<dynamic> warnings;
  final List<String> capabilitiesUsed;
  final String? actionPreviewUuid;
  final List<BotSource> sources;
  final DateTime? createdAt;

  bool get isAssistant => role.trim().toLowerCase() == 'assistant';

  factory BotMessage.fromJson(Map<String, dynamic> json) {
    return BotMessage(
      uuid: json['uuid']?.toString() ?? '',
      role: json['role']?.toString() ?? 'assistant',
      mode: botModeFromRaw(json['mode']),
      content: json['content']?.toString() ?? '',
      contentFormat: json['content_format']?.toString() ?? 'text',
      status: json['status']?.toString() ?? 'completed',
      requiredFields: _parseStringList(json['required_fields']),
      warnings: json['warnings'] is List
          ? List<dynamic>.from(json['warnings'] as List)
          : const [],
      capabilitiesUsed: _parseStringList(json['capabilities_used']),
      actionPreviewUuid: json['action_preview_uuid']?.toString(),
      sources: (json['sources'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => BotSource.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

class BotActionPreview {
  const BotActionPreview({
    required this.uuid,
    required this.action,
    required this.status,
    required this.summary,
    required this.payload,
    required this.normalizedPayload,
    required this.warnings,
    required this.requiresConfirmation,
    required this.expiresAt,
    required this.confirmedAt,
    required this.executedAt,
    required this.resultType,
    required this.resultId,
    required this.errorMessage,
  });

  final String uuid;
  final String action;
  final String status;
  final String? summary;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> normalizedPayload;
  final List<dynamic> warnings;
  final bool requiresConfirmation;
  final DateTime? expiresAt;
  final DateTime? confirmedAt;
  final DateTime? executedAt;
  final String? resultType;
  final String? resultId;
  final String? errorMessage;

  factory BotActionPreview.fromJson(Map<String, dynamic> json) {
    return BotActionPreview(
      uuid: json['uuid']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      summary: json['summary']?.toString(),
      payload: json['payload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['payload'] as Map<String, dynamic>)
          : <String, dynamic>{},
      normalizedPayload: json['normalized_payload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(
              json['normalized_payload'] as Map<String, dynamic>,
            )
          : <String, dynamic>{},
      warnings: json['warnings'] is List
          ? List<dynamic>.from(json['warnings'] as List)
          : const [],
      requiresConfirmation: json['requires_confirmation'] == true,
      expiresAt: _parseDateTime(json['expires_at']),
      confirmedAt: _parseDateTime(json['confirmed_at']),
      executedAt: _parseDateTime(json['executed_at']),
      resultType: json['result_type']?.toString(),
      resultId: json['result_id']?.toString(),
      errorMessage: json['error_message']?.toString(),
    );
  }
}

enum BotActionFieldType { text, number, date, time, textarea, select }

class BotActionFieldOption {
  const BotActionFieldOption({required this.value, required this.label});

  final String value;
  final String label;
}

class BotActionFieldConfig {
  const BotActionFieldConfig({
    required this.name,
    required this.label,
    required this.type,
    this.placeholder,
    this.required = false,
    this.defaultValue,
    this.options,
  });

  final String name;
  final String label;
  final BotActionFieldType type;
  final String? placeholder;
  final bool required;
  final String? defaultValue;
  final List<BotActionFieldOption>? options;
}

const Map<String, String> botQuickActionPrompts = {
  'my-profile': 'Tampilkan profil saya.',
  'ask-policy': 'Jelaskan kebijakan atau SOP dari dokumen yang saya pilih.',
  'my-claims-status': 'Bagaimana status claim saya saat ini?',
  'create-claim-draft': 'Bantu saya buat draft claim.',
  'my-overtime-status': 'Bagaimana status lembur saya saat ini?',
  'create-overtime-draft': 'Bantu saya buat draft lembur.',
  'my-leave-balance': 'Berapa sisa cuti saya saat ini?',
  'create-leave-draft': 'Bantu saya buat draft cuti.',
};

const Map<String, List<BotActionFieldConfig>> botActionFieldConfigs = {
  'create-claim-draft': [
    BotActionFieldConfig(
      name: 'claim_type',
      label: 'Jenis claim',
      type: BotActionFieldType.select,
      required: true,
      defaultValue: 'reimbursement',
      options: [
        BotActionFieldOption(value: 'reimbursement', label: 'Reimbursement'),
        BotActionFieldOption(value: 'expense', label: 'Expense'),
        BotActionFieldOption(value: 'travel', label: 'Travel'),
      ],
    ),
    BotActionFieldConfig(
      name: 'category',
      label: 'Kategori',
      type: BotActionFieldType.text,
      required: true,
      placeholder: 'Contoh: Transportasi',
    ),
    BotActionFieldConfig(
      name: 'title',
      label: 'Judul claim',
      type: BotActionFieldType.text,
      required: true,
      placeholder: 'Contoh: Taksi kunjungan klien',
    ),
    BotActionFieldConfig(
      name: 'amount',
      label: 'Nominal',
      type: BotActionFieldType.number,
      required: true,
      placeholder: '0',
    ),
    BotActionFieldConfig(
      name: 'currency',
      label: 'Mata uang',
      type: BotActionFieldType.text,
      defaultValue: 'IDR',
      placeholder: 'IDR',
    ),
    BotActionFieldConfig(
      name: 'expense_date',
      label: 'Tanggal pengeluaran',
      type: BotActionFieldType.date,
      required: true,
    ),
    BotActionFieldConfig(
      name: 'notes',
      label: 'Catatan',
      type: BotActionFieldType.textarea,
      placeholder: 'Tambahkan detail bila perlu',
    ),
  ],
  'create-overtime-draft': [
    BotActionFieldConfig(
      name: 'request_date',
      label: 'Tanggal lembur',
      type: BotActionFieldType.date,
      required: true,
    ),
    BotActionFieldConfig(
      name: 'start_time',
      label: 'Jam mulai',
      type: BotActionFieldType.time,
      required: true,
    ),
    BotActionFieldConfig(
      name: 'end_time',
      label: 'Jam selesai',
      type: BotActionFieldType.time,
      required: true,
    ),
    BotActionFieldConfig(
      name: 'project_code',
      label: 'Kode proyek',
      type: BotActionFieldType.text,
      placeholder: 'Opsional',
    ),
    BotActionFieldConfig(
      name: 'reason',
      label: 'Alasan lembur',
      type: BotActionFieldType.textarea,
      required: true,
      placeholder: 'Jelaskan alasan lembur',
    ),
    BotActionFieldConfig(
      name: 'notes',
      label: 'Catatan',
      type: BotActionFieldType.textarea,
      placeholder: 'Opsional',
    ),
  ],
  'create-leave-draft': [
    BotActionFieldConfig(
      name: 'type',
      label: 'Jenis cuti',
      type: BotActionFieldType.select,
      required: true,
      defaultValue: 'Annual',
      options: [
        BotActionFieldOption(value: 'Annual', label: 'Annual'),
        BotActionFieldOption(value: 'Sick', label: 'Sick'),
        BotActionFieldOption(value: 'Personal', label: 'Personal'),
      ],
    ),
    BotActionFieldConfig(
      name: 'start_date',
      label: 'Tanggal mulai',
      type: BotActionFieldType.date,
      required: true,
    ),
    BotActionFieldConfig(
      name: 'end_date',
      label: 'Tanggal selesai',
      type: BotActionFieldType.date,
      required: true,
    ),
    BotActionFieldConfig(
      name: 'reason',
      label: 'Alasan',
      type: BotActionFieldType.textarea,
      placeholder: 'Opsional',
    ),
  ],
};

Map<String, String> getBotActionDefaultValues(String? toolName) {
  final fields = botActionFieldConfigs[toolName];
  if (fields == null || fields.isEmpty) {
    return <String, String>{};
  }

  final today = _todayValue();

  return fields.fold<Map<String, String>>(<String, String>{}, (
    accumulator,
    field,
  ) {
    if (field.defaultValue != null) {
      accumulator[field.name] = field.defaultValue!;
    } else if (field.type == BotActionFieldType.date) {
      accumulator[field.name] = today;
    }

    return accumulator;
  });
}

String humanizeBotFieldName(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.trim().isNotEmpty)
      .map((part) {
        final normalized = part.trim();
        return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
      })
      .join(' ');
}

String formatBotWarning(dynamic warning) {
  if (warning is String) {
    return warning;
  }

  if (warning is Map) {
    return warning.entries
        .map((entry) {
          final value = entry.value;
          if (value is List) {
            return '${entry.key}: ${value.join(", ")}';
          }

          return '${entry.key}: ${value ?? "-"}';
        })
        .join(' | ');
  }

  return warning?.toString() ?? '-';
}

String _todayValue() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}

List<String> _parseStringList(dynamic value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
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
