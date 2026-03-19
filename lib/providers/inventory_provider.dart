import 'package:flutter/material.dart';
import '../models/inventory_model.dart';
import '../services/api_service.dart';

class InventoryProvider with ChangeNotifier {
  InventoryProvider() {
    fetchInventories();
  }

  final ApiService _apiService = ApiService();

  List<InventoryModel> _inventories = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  String? _nextRequestNumber;

  List<InventoryModel> get inventories => _inventories;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  String? get nextRequestNumber => _nextRequestNumber;

  Future<void> fetchInventories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/inventories?per_page=100');
      final rawItems = _extractList(response['data']);
      _inventories = rawItems
          .map((item) => InventoryModel.fromJson(item))
          .toList(growable: false);
    } catch (e) {
      _error = _normalizeError(e);
      _inventories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> fetchNextRequestNumber() async {
    try {
      final response = await _apiService.get('/inventory-requests/last-number');
      _nextRequestNumber = response['data']?['next_number']?.toString();
      notifyListeners();
      return _nextRequestNumber;
    } catch (e) {
      _error = _normalizeError(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> submitRequest({
    required String requestedBy,
    required String department,
    required InventoryModel inventory,
    required int quantity,
    required String purpose,
    required String priority,
    String? notes,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final requestNumber =
          _nextRequestNumber ?? await fetchNextRequestNumber() ?? '';
      if (requestNumber.isEmpty) {
        throw Exception('Nomor request tidak tersedia.');
      }

      final response = await _apiService.post('/inventory-requests', {
        'request_number': requestNumber,
        'requested_by': requestedBy,
        'department': department,
        'priority': priority,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        'items': [
          {
            'inventory_id': int.tryParse(inventory.id) ?? inventory.id,
            'quantity': quantity,
            'purpose': purpose.trim(),
          },
        ],
      });

      final success =
          response is Map<String, dynamic> &&
          (response['success'] == true || response['status'] == 'success');
      if (!success) {
        _error = response is Map<String, dynamic>
            ? response['message']?.toString() ?? 'Gagal mengirim request asset.'
            : 'Gagal mengirim request asset.';
        return false;
      }

      await fetchNextRequestNumber();
      return true;
    } catch (e) {
      _error = _normalizeError(e);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await fetchInventories();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<Map<String, dynamic>> _extractList(dynamic rawData) {
    if (rawData is List) {
      return rawData.whereType<Map<String, dynamic>>().toList(growable: false);
    }

    if (rawData is Map<String, dynamic>) {
      final nestedData = rawData['data'];
      if (nestedData is List) {
        return nestedData.whereType<Map<String, dynamic>>().toList(
          growable: false,
        );
      }
    }

    return const [];
  }

  String _normalizeError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }
}
