import 'package:flutter/material.dart';

import '../models/bot_assistant_model.dart';
import '../models/discovery_model.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class BotAssistantProvider extends ChangeNotifier {
  BotAssistantProvider(this._authProvider);

  final AuthProvider _authProvider;
  final ApiService _apiService = ApiService();

  BotCapabilities? _capabilities;
  List<BotSession> _sessions = [];
  List<BotMessage> _messages = [];
  BotSession? _activeSession;
  BotMode _botMode = BotMode.askSystem;
  List<DiscoveryDocument> _documents = [];
  List<int> _selectedDocumentIds = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingSession = false;
  bool _isSending = false;
  bool _isPreviewLoading = false;
  bool _isConfirming = false;
  String? _pendingActionTool;
  BotActionPreview? _actionPreview;
  Map<String, String> _actionValues = <String, String>{};
  String? _error;

  BotCapabilities? get capabilities => _capabilities;
  List<BotSession> get sessions => _sessions;
  List<BotMessage> get messages => _messages;
  BotSession? get activeSession => _activeSession;
  BotMode get botMode => _botMode;
  List<DiscoveryDocument> get documents => _documents;
  List<int> get selectedDocumentIds => _selectedDocumentIds;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingSession => _isLoadingSession;
  bool get isSending => _isSending;
  bool get isPreviewLoading => _isPreviewLoading;
  bool get isConfirming => _isConfirming;
  String? get pendingActionTool => _pendingActionTool;
  BotActionPreview? get actionPreview => _actionPreview;
  Map<String, String> get actionValues => _actionValues;
  String? get error => _error;

  List<BotMode> get modeOptions => _capabilities?.modes.isNotEmpty == true
      ? _capabilities!.modes
      : const [BotMode.askSystem];

  bool get canAskDocs => modeOptions.contains(BotMode.askDocs);

  bool get docsConfigured => _capabilities?.docsConfigured ?? false;

  List<DiscoveryDocument> get selectedDocuments => _documents
      .where((document) => _selectedDocumentIds.contains(document.id))
      .toList(growable: false);

  List<BotActionFieldConfig> get currentActionFields =>
      botActionFieldConfigs[_pendingActionTool] ?? const [];

  bool get actionFormReady => currentActionFields.every((field) {
    if (!field.required) {
      return true;
    }

    final value = _actionValues[field.name];
    return value != null && value.trim().isNotEmpty;
  });

  BotMessage? get lastAssistantMessage {
    for (final message in _messages.reversed) {
      if (message.isAssistant) {
        return message;
      }
    }

    return null;
  }

  Future<bool> bootstrap({bool refresh = false}) async {
    if (refresh) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }

    _error = null;
    notifyListeners();

    try {
      await _fetchCapabilitiesInternal();
      await _fetchSessionsInternal();

      if (canAskDocs) {
        await _fetchDocumentsInternal();
      } else {
        _documents = [];
        _selectedDocumentIds = [];
      }

      if (_sessions.isNotEmpty) {
        final targetUuid = _activeSession?.uuid ?? _sessions.first.uuid;
        await _loadSessionInternal(targetUuid, showLoading: false);
      } else {
        resetComposer(notify: false);
      }

      return true;
    } catch (error) {
      _error = _normalizeError(error);
      return false;
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<bool> refresh() => bootstrap(refresh: true);

  void setBotMode(BotMode mode) {
    if (!modeOptions.contains(mode)) {
      return;
    }

    _botMode = mode;
    notifyListeners();
  }

  void resetComposer({bool notify = true}) {
    _activeSession = null;
    _messages = [];
    _pendingActionTool = null;
    _actionPreview = null;
    _actionValues = <String, String>{};

    if (_selectedDocumentIds.isEmpty) {
      _selectedDocumentIds = _defaultDocumentIds;
    }

    if (notify) {
      notifyListeners();
    }
  }

  void toggleDocumentSelection(int documentId) {
    if (_selectedDocumentIds.contains(documentId)) {
      _selectedDocumentIds = _selectedDocumentIds
          .where((id) => id != documentId)
          .toList(growable: false);
    } else {
      _selectedDocumentIds = [..._selectedDocumentIds, documentId];
    }

    notifyListeners();
  }

  void updateActionValue(String name, String value) {
    _actionValues = {..._actionValues, name: value};
    notifyListeners();
  }

  void clearActionPreview() {
    _actionPreview = null;
    notifyListeners();
  }

  Future<bool> loadSession(String sessionUuid) async {
    _error = null;
    notifyListeners();

    try {
      await _loadSessionInternal(sessionUuid, showLoading: true);
      return true;
    } catch (error) {
      _error = _normalizeError(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendMessage(
    String prompt, {
    BotMode? overrideMode,
    String? quickActionId,
  }) async {
    final nextPrompt = prompt.trim();
    final nextMode = overrideMode ?? _botMode;

    if (nextPrompt.isEmpty || _isSending) {
      return false;
    }

    if (nextMode == BotMode.askDocs && _selectedDocumentIds.isEmpty) {
      _error = 'Pilih minimal satu dokumen untuk mode Tanya Dokumen.';
      notifyListeners();
      return false;
    }

    _isSending = true;
    _error = null;

    final optimisticMessage = BotMessage(
      uuid: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      mode: nextMode,
      content: nextPrompt,
      contentFormat: 'text',
      status: 'completed',
      requiredFields: const [],
      warnings: const [],
      capabilitiesUsed: const [],
      actionPreviewUuid: null,
      sources: const [],
      createdAt: DateTime.now(),
    );

    _messages = [..._messages, optimisticMessage];
    notifyListeners();

    try {
      final session = _activeSession != null && _activeSession!.mode == nextMode
          ? _activeSession!
          : await _createSessionInternal(
              nextMode,
              quickActionId: quickActionId,
            );

      final response = await _apiService.post(
        _withCompanyQuery('/bot/sessions/${session.uuid}/messages'),
        {
          'message': nextPrompt,
          'mode': nextMode.apiValue,
          if (nextMode == BotMode.askDocs)
            'selected_document_ids': _selectedDocumentIds,
          'context': {
            'route': '/bot',
            'active_module': nextMode.apiValue,
            if (quickActionId != null && quickActionId.isNotEmpty)
              'quick_action': quickActionId,
          },
        },
      );

      if (response is! Map<String, dynamic> || response['success'] != true) {
        throw Exception(
          response is Map<String, dynamic>
              ? response['message']?.toString() ??
                    'BOT belum bisa memproses pesan saat ini.'
              : 'BOT belum bisa memproses pesan saat ini.',
        );
      }

      final payload = Map<String, dynamic>.from(response['data'] as Map);
      final nextSession = BotSession.fromJson(
        Map<String, dynamic>.from(payload['session'] as Map),
      );
      final assistantMessage = BotMessage.fromJson(
        Map<String, dynamic>.from(payload['message'] as Map),
      );

      _activeSession = nextSession;
      _botMode = nextSession.mode;
      _messages = [
        ..._messages.where((message) => message.uuid != optimisticMessage.uuid),
        optimisticMessage,
        assistantMessage,
      ];

      if (assistantMessage.status == 'requires-input') {
        openActionComposer(
          assistantMessage.capabilitiesUsed.isNotEmpty
              ? assistantMessage.capabilitiesUsed.first
              : null,
        );
      } else if (assistantMessage.mode != BotMode.takeAction) {
        openActionComposer(null);
      }

      await _fetchSessionsInternal();
      return true;
    } catch (error) {
      _messages = _messages
          .where((message) => message.uuid != optimisticMessage.uuid)
          .toList(growable: false);
      _error = _normalizeError(error);
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<bool> previewAction() async {
    if (_activeSession == null || _pendingActionTool == null) {
      return false;
    }

    _isPreviewLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService
          .post(_withCompanyQuery('/bot/actions/preview'), {
            'session_uuid': _activeSession!.uuid,
            'action': _pendingActionTool,
            'payload': _actionValues,
          });

      if (response is! Map<String, dynamic> || response['success'] != true) {
        throw Exception(
          response is Map<String, dynamic>
              ? response['message']?.toString() ??
                    'Preview aksi BOT belum bisa dibuat.'
              : 'Preview aksi BOT belum bisa dibuat.',
        );
      }

      final payload = Map<String, dynamic>.from(response['data'] as Map);
      _actionPreview = BotActionPreview.fromJson(
        Map<String, dynamic>.from(payload['action_preview'] as Map),
      );
      return true;
    } catch (error) {
      _error = _normalizeError(error);
      return false;
    } finally {
      _isPreviewLoading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmAction() async {
    if (_actionPreview == null) {
      return false;
    }

    _isConfirming = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        _withCompanyQuery('/bot/actions/confirm'),
        {'preview_uuid': _actionPreview!.uuid, 'confirm': true},
      );

      if (response is! Map<String, dynamic> || response['success'] != true) {
        throw Exception(
          response is Map<String, dynamic>
              ? response['message']?.toString() ??
                    'Konfirmasi aksi BOT gagal diproses.'
              : 'Konfirmasi aksi BOT gagal diproses.',
        );
      }

      final payload = Map<String, dynamic>.from(response['data'] as Map);
      final nextMessage = BotMessage.fromJson(
        Map<String, dynamic>.from(payload['message'] as Map),
      );

      _messages = [..._messages, nextMessage];
      _activeSession = _activeSession?.copyWith(
        lastMessageAt: nextMessage.createdAt,
      );
      _actionPreview = null;
      _pendingActionTool = null;
      _actionValues = <String, String>{};

      await _fetchSessionsInternal();
      return true;
    } catch (error) {
      _error = _normalizeError(error);
      return false;
    } finally {
      _isConfirming = false;
      notifyListeners();
    }
  }

  void openActionComposer(String? toolName) {
    if (toolName == null || !botActionFieldConfigs.containsKey(toolName)) {
      _pendingActionTool = null;
      _actionPreview = null;
      _actionValues = <String, String>{};
      notifyListeners();
      return;
    }

    _pendingActionTool = toolName;
    _actionPreview = null;
    _actionValues = getBotActionDefaultValues(toolName);
    notifyListeners();
  }

  Future<void> _fetchCapabilitiesInternal() async {
    final response = await _apiService.get(
      _withCompanyQuery('/bot/capabilities'),
    );

    if (response is! Map<String, dynamic> || response['success'] != true) {
      throw Exception(
        response is Map<String, dynamic>
            ? response['message']?.toString() ??
                  'Capability BOT belum bisa dimuat.'
            : 'Capability BOT belum bisa dimuat.',
      );
    }

    _capabilities = BotCapabilities.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );

    if (!modeOptions.contains(_botMode)) {
      _botMode = modeOptions.first;
    }
  }

  Future<void> _fetchSessionsInternal() async {
    final response = await _apiService.get(_withCompanyQuery('/bot/sessions'));

    if (response is! Map<String, dynamic> || response['success'] != true) {
      throw Exception(
        response is Map<String, dynamic>
            ? response['message']?.toString() ?? 'Riwayat BOT gagal dimuat.'
            : 'Riwayat BOT gagal dimuat.',
      );
    }

    final payload = response['data'];
    final data = payload is Map<String, dynamic>
        ? payload
        : <String, dynamic>{};

    _sessions = (data['sessions'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => BotSession.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.uuid.isNotEmpty)
        .toList(growable: false);

    if (_activeSession == null) {
      return;
    }

    final activeItems = _sessions.where(
      (session) => session.uuid == _activeSession!.uuid,
    );
    _activeSession = activeItems.isEmpty ? null : activeItems.first;
  }

  Future<void> _fetchDocumentsInternal() async {
    final response = await _apiService.get(
      _withCompanyQuery('/discovery/documents'),
    );

    if (response is! Map<String, dynamic> || response['success'] != true) {
      throw Exception(
        response is Map<String, dynamic>
            ? response['message']?.toString() ??
                  'Dokumen Discovery belum bisa dimuat.'
            : 'Dokumen Discovery belum bisa dimuat.',
      );
    }

    _documents = (response['data'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => DiscoveryDocument.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);

    if (_selectedDocumentIds.isEmpty) {
      _selectedDocumentIds = _defaultDocumentIds;
      return;
    }

    _selectedDocumentIds = _selectedDocumentIds
        .where((id) => _documents.any((document) => document.id == id))
        .toList(growable: false);
  }

  Future<void> _loadSessionInternal(
    String sessionUuid, {
    required bool showLoading,
  }) async {
    if (showLoading) {
      _isLoadingSession = true;
      notifyListeners();
    }

    try {
      final response = await _apiService.get(
        _withCompanyQuery('/bot/sessions/$sessionUuid'),
      );

      if (response is! Map<String, dynamic> || response['success'] != true) {
        throw Exception(
          response is Map<String, dynamic>
              ? response['message']?.toString() ??
                    'Session BOT belum bisa dimuat.'
              : 'Session BOT belum bisa dimuat.',
        );
      }

      final payload = Map<String, dynamic>.from(response['data'] as Map);
      final nextSession = BotSession.fromJson(
        Map<String, dynamic>.from(payload['session'] as Map),
      );
      final nextMessages = (payload['messages'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => BotMessage.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);

      _activeSession = nextSession;
      _messages = nextMessages;
      _botMode = nextSession.mode;
      _syncActionStateFromMessages(nextMessages);
    } finally {
      if (showLoading) {
        _isLoadingSession = false;
        notifyListeners();
      }
    }
  }

  Future<BotSession> _createSessionInternal(
    BotMode mode, {
    String? quickActionId,
  }) async {
    final response = await _apiService.post(
      _withCompanyQuery('/bot/sessions'),
      {
        'mode': mode.apiValue,
        'context': {
          'route': '/bot',
          if (quickActionId != null && quickActionId.isNotEmpty)
            'quick_action': quickActionId,
        },
      },
    );

    if (response is! Map<String, dynamic> || response['success'] != true) {
      throw Exception(
        response is Map<String, dynamic>
            ? response['message']?.toString() ?? 'Session BOT gagal dibuat.'
            : 'Session BOT gagal dibuat.',
      );
    }

    final payload = Map<String, dynamic>.from(response['data'] as Map);
    final session = BotSession.fromJson(
      Map<String, dynamic>.from(payload['session'] as Map),
    );

    _activeSession = session;
    _messages = [];
    _botMode = session.mode;
    await _fetchSessionsInternal();
    return session;
  }

  void _syncActionStateFromMessages(List<BotMessage> nextMessages) {
    BotMessage? latestAssistant;

    for (final message in nextMessages.reversed) {
      if (message.isAssistant) {
        latestAssistant = message;
        break;
      }
    }

    final nextTool =
        latestAssistant?.status == 'requires-input' &&
            latestAssistant!.capabilitiesUsed.isNotEmpty
        ? latestAssistant.capabilitiesUsed.first
        : null;

    if (nextTool == null) {
      _pendingActionTool = null;
      _actionPreview = null;
      _actionValues = <String, String>{};
      return;
    }

    _pendingActionTool = nextTool;
    _actionPreview = null;
    _actionValues = getBotActionDefaultValues(nextTool);
  }

  List<int> get _defaultDocumentIds => _documents
      .where(
        (document) =>
            document.discoveryEnabled &&
            document.discoverySyncStatus.toLowerCase() != 'failed',
      )
      .map((document) => document.id)
      .toList(growable: false);

  String _withCompanyQuery(String endpoint) {
    final companyCode = _authProvider.getCompanyCode().trim();
    if (companyCode.isEmpty) {
      return endpoint;
    }

    final separator = endpoint.contains('?') ? '&' : '?';
    return '$endpoint${separator}c_code=${Uri.encodeComponent(companyCode)}';
  }

  String _normalizeError(Object error) {
    var message = error.toString();

    const prefixes = ['Exception: ', 'Network error: '];
    var changed = true;

    while (changed) {
      changed = false;
      for (final prefix in prefixes) {
        if (message.startsWith(prefix)) {
          message = message.substring(prefix.length);
          changed = true;
        }
      }
    }

    return message.trim();
  }
}
