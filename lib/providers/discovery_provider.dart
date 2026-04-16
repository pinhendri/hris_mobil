import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/discovery_model.dart';
import '../services/api_service.dart';
import '../services/session_storage.dart';
import 'auth_provider.dart';

class DiscoveryProvider extends ChangeNotifier {
  DiscoveryProvider(this._authProvider);

  final AuthProvider _authProvider;
  final ApiService _apiService = ApiService();

  List<DiscoveryDocument> _documents = [];
  List<DiscoveryConversation> _conversations = [];
  List<DiscoveryMessage> _messages = [];
  DiscoveryConversation? _activeConversation;
  List<int> _selectedDocumentIds = [];
  List<String> _supportedFormats = const [
    'pdf',
    'doc',
    'docx',
    'pptx',
    'txt',
    'md',
    'json',
    'html',
  ];
  bool _aiConfigured = false;
  bool _isLoading = false;
  bool _isLoadingConversation = false;
  bool _isUploading = false;
  bool _isSending = false;
  String? _error;
  String? _warningMessage;

  List<DiscoveryDocument> get documents => _documents;
  List<DiscoveryConversation> get conversations => _conversations;
  List<DiscoveryMessage> get messages => _messages;
  DiscoveryConversation? get activeConversation => _activeConversation;
  List<int> get selectedDocumentIds => _selectedDocumentIds;
  List<String> get supportedFormats => _supportedFormats;
  bool get aiConfigured => _aiConfigured;
  bool get isLoading => _isLoading;
  bool get isLoadingConversation => _isLoadingConversation;
  bool get isUploading => _isUploading;
  bool get isSending => _isSending;
  String? get error => _error;
  String? get warningMessage => _warningMessage;

  List<DiscoveryDocument> get selectedDocuments => _documents
      .where((document) => _selectedDocumentIds.contains(document.id))
      .toList(growable: false);

  Future<bool> bootstrap() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _fetchDocumentsInternal();
      await _fetchConversationsInternal();

      if (_conversations.isNotEmpty) {
        final targetUuid =
            _activeConversation?.uuid ?? _conversations.first.uuid;
        await _loadConversationInternal(targetUuid, showLoading: false);
      } else {
        _activeConversation = null;
        _messages = [];
        if (_selectedDocumentIds.isEmpty) {
          _selectedDocumentIds = _defaultDocumentIds;
        }
      }

      return true;
    } catch (error) {
      _error = _normalizeError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> refresh() async {
    return bootstrap();
  }

  void startNewConversation() {
    _activeConversation = null;
    _messages = [];
    if (_selectedDocumentIds.isEmpty) {
      _selectedDocumentIds = _defaultDocumentIds;
    }
    notifyListeners();
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

  Future<bool> loadConversation(String uuid) async {
    _error = null;
    _warningMessage = null;
    notifyListeners();

    try {
      await _loadConversationInternal(uuid, showLoading: true);
      return true;
    } catch (error) {
      _error = _normalizeError(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadDocuments(
    List<PlatformFile> files, {
    String category = 'Discovery',
  }) async {
    if (files.isEmpty) {
      _error = 'Tidak ada file yang dipilih.';
      notifyListeners();
      return false;
    }

    _isUploading = true;
    _error = null;
    _warningMessage = null;
    notifyListeners();

    try {
      final token = await SessionStorage.getToken();
      if (token.isEmpty) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '${ApiService.baseUrl}/api${_withCompanyQuery('/discovery/documents')}',
        ),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      request.fields['category'] = category.trim().isEmpty
          ? 'Discovery'
          : category.trim();

      final companyCode = _companyCode;
      if (companyCode.isNotEmpty) {
        request.fields['c_code'] = companyCode;
      }

      for (final file in files) {
        if (file.path != null && file.path!.isNotEmpty) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'documents[]',
              file.path!,
              filename: file.name,
            ),
          );
          continue;
        }

        if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'documents[]',
              file.bytes!,
              filename: file.name,
            ),
          );
        }
      }

      if (request.files.isEmpty) {
        throw Exception('File yang dipilih tidak valid untuk diupload.');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final payload = response.body.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(response.body) as Map);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          payload['success'] != true) {
        throw Exception(
          payload['message']?.toString() ?? 'Upload dokumen Discovery gagal.',
        );
      }

      _warningMessage = _extractWarningMessage(payload['warnings']);

      await _fetchDocumentsInternal();
      await _fetchConversationsInternal();

      final uploadedDocumentIds = (payload['data'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                DiscoveryDocument.fromJson(Map<String, dynamic>.from(item)).id,
          )
          .where((id) => id > 0)
          .toSet();

      _selectedDocumentIds = {..._selectedDocumentIds, ...uploadedDocumentIds}
          .where((id) => _documents.any((document) => document.id == id))
          .toList(growable: false);

      return true;
    } catch (error) {
      _error = _normalizeError(error);
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String message) async {
    final prompt = message.trim();
    if (prompt.isEmpty) {
      _error = 'Pertanyaan tidak boleh kosong.';
      notifyListeners();
      return false;
    }

    if (_selectedDocumentIds.isEmpty) {
      _error = 'Pilih minimal satu dokumen untuk Discovery.';
      notifyListeners();
      return false;
    }

    _isSending = true;
    _error = null;
    _warningMessage = null;

    final optimisticMessage = DiscoveryMessage(
      id: -DateTime.now().millisecondsSinceEpoch,
      role: 'user',
      content: prompt,
      citations: const [],
      createdAt: DateTime.now(),
    );

    _messages = [..._messages, optimisticMessage];
    notifyListeners();

    try {
      final conversation =
          _activeConversation ?? await _createConversationInternal();
      final response = await _apiService.post(
        _withCompanyQuery(
          '/discovery/conversations/${conversation.uuid}/messages',
        ),
        {
          'message': prompt,
          'document_ids': _selectedDocumentIds,
          if (_companyCode.isNotEmpty) 'c_code': _companyCode,
        },
      );

      if (response is! Map<String, dynamic> || response['success'] != true) {
        throw Exception(
          response is Map<String, dynamic>
              ? response['message']?.toString() ??
                    'Discovery belum bisa menjawab.'
              : 'Discovery belum bisa menjawab.',
        );
      }

      final payload = Map<String, dynamic>.from(response['data'] as Map);
      final nextConversation = DiscoveryConversation.fromJson(
        Map<String, dynamic>.from(payload['conversation'] as Map),
      );
      final userMessage = DiscoveryMessage.fromJson(
        Map<String, dynamic>.from(payload['user_message'] as Map),
      );
      final assistantMessage = DiscoveryMessage.fromJson(
        Map<String, dynamic>.from(payload['assistant_message'] as Map),
      );

      _activeConversation = nextConversation;
      _messages = [
        ..._messages.where((item) => item.id != optimisticMessage.id),
        userMessage,
        assistantMessage,
      ];
      _warningMessage = _extractWarningMessage(payload['warnings']);

      await _fetchConversationsInternal();
      await _fetchDocumentsInternal();
      return true;
    } catch (error) {
      _messages = _messages
          .where((item) => item.id != optimisticMessage.id)
          .toList(growable: false);
      _error = _normalizeError(error);
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> _fetchDocumentsInternal() async {
    final response = await _apiService.get(
      _withCompanyQuery('/discovery/documents'),
    );

    if (response is! Map<String, dynamic> || response['success'] != true) {
      throw Exception(
        response is Map<String, dynamic>
            ? response['message']?.toString() ??
                  'Gagal memuat dokumen Discovery.'
            : 'Gagal memuat dokumen Discovery.',
      );
    }

    _documents = (response['data'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => DiscoveryDocument.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
    _aiConfigured = response['ai_configured'] == true;
    _supportedFormats = ((response['supported_formats'] as List?) ?? const [])
        .map((item) => item.toString().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    if (_selectedDocumentIds.isEmpty) {
      _selectedDocumentIds = _defaultDocumentIds;
      return;
    }

    _selectedDocumentIds = _selectedDocumentIds
        .where((id) => _documents.any((document) => document.id == id))
        .toList(growable: false);
  }

  Future<void> _fetchConversationsInternal() async {
    final response = await _apiService.get(
      _withCompanyQuery('/discovery/conversations'),
    );

    if (response is! Map<String, dynamic> || response['success'] != true) {
      throw Exception(
        response is Map<String, dynamic>
            ? response['message']?.toString() ??
                  'Gagal memuat percakapan Discovery.'
            : 'Gagal memuat percakapan Discovery.',
      );
    }

    _conversations = (response['data'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              DiscoveryConversation.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);

    if (_activeConversation == null) {
      return;
    }

    final activeItems = _conversations.where(
      (item) => item.uuid == _activeConversation!.uuid,
    );
    _activeConversation = activeItems.isEmpty ? null : activeItems.first;
  }

  Future<void> _loadConversationInternal(
    String uuid, {
    required bool showLoading,
  }) async {
    if (showLoading) {
      _isLoadingConversation = true;
      notifyListeners();
    }

    try {
      final response = await _apiService.get(
        _withCompanyQuery('/discovery/conversations/$uuid'),
      );

      if (response is! Map<String, dynamic> || response['success'] != true) {
        throw Exception(
          response is Map<String, dynamic>
              ? response['message']?.toString() ??
                    'Gagal memuat percakapan Discovery.'
              : 'Gagal memuat percakapan Discovery.',
        );
      }

      final payload = Map<String, dynamic>.from(response['data'] as Map);
      final nextConversation = DiscoveryConversation.fromJson(
        Map<String, dynamic>.from(payload['conversation'] as Map),
      );

      _activeConversation = nextConversation;
      _messages = (payload['messages'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                DiscoveryMessage.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
      _selectedDocumentIds = nextConversation.selectedDocumentIds.isNotEmpty
          ? nextConversation.selectedDocumentIds
          : _defaultDocumentIds;
    } finally {
      if (showLoading) {
        _isLoadingConversation = false;
        notifyListeners();
      }
    }
  }

  Future<DiscoveryConversation> _createConversationInternal() async {
    final response = await _apiService
        .post(_withCompanyQuery('/discovery/conversations'), {
          'document_ids': _selectedDocumentIds,
          if (_companyCode.isNotEmpty) 'c_code': _companyCode,
        });

    if (response is! Map<String, dynamic> || response['success'] != true) {
      throw Exception(
        response is Map<String, dynamic>
            ? response['message']?.toString() ??
                  'Gagal membuat percakapan Discovery.'
            : 'Gagal membuat percakapan Discovery.',
      );
    }

    final conversation = DiscoveryConversation.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );

    _activeConversation = conversation;
    _messages = [];
    _conversations = [
      conversation,
      ..._conversations.where((item) => item.uuid != conversation.uuid),
    ];

    return conversation;
  }

  List<int> get _defaultDocumentIds => _documents
      .where(
        (document) =>
            document.discoveryEnabled &&
            document.discoverySyncStatus.toLowerCase() != 'failed',
      )
      .map((document) => document.id)
      .toList(growable: false);

  String _extractWarningMessage(dynamic warnings) {
    if (warnings is! List || warnings.isEmpty) {
      return '';
    }

    final items = warnings
        .whereType<Map>()
        .map((item) {
          final map = Map<String, dynamic>.from(item);
          final name =
              map['document']?.toString() ??
              map['document_id']?.toString() ??
              'Dokumen';
          final message =
              map['message']?.toString() ??
              'Ada catatan saat proses Discovery.';
          return '$name: $message';
        })
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);

    return items.join('\n');
  }

  String _withCompanyQuery(String endpoint) {
    if (_companyCode.isEmpty) {
      return endpoint;
    }

    final separator = endpoint.contains('?') ? '&' : '?';
    return '$endpoint${separator}c_code=${Uri.encodeComponent(_companyCode)}';
  }

  String get _companyCode => _authProvider.getCompanyCode().trim();

  String _normalizeError(Object error) {
    var message = error.toString();

    const prefixes = ['Exception: ', 'Network error: ', 'Exception: '];

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
