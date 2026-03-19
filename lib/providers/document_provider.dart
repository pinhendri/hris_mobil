import 'package:flutter/material.dart';

import '../data/models/document_model.dart';
import '../services/api_service.dart';

class DocumentProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _error;
  List<DocumentItem> _documents = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<DocumentItem> get documents => _documents;

  Future<void> fetchDocuments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/documents');
      final rawItems = response is Map<String, dynamic>
          ? response['data']
          : null;

      if (rawItems is List) {
        _documents =
            rawItems
                .whereType<Map<String, dynamic>>()
                .map(DocumentItem.fromJson)
                .toList(growable: true)
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      } else {
        _documents = [];
      }
    } catch (e) {
      _error = _normalizeError(e);
      _documents = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await fetchDocuments();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _normalizeError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }
}
