import 'package:flutter/material.dart';

import '../models/training_model.dart';
import '../services/api_service.dart';

class TrainingProvider with ChangeNotifier {
  TrainingProvider() {
    refresh();
  }

  final ApiService _apiService = ApiService();

  List<TrainingModel> _trainings = [];
  bool _isLoading = false;
  String? _error;

  List<TrainingModel> get trainings => _trainings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/learning');
      final data = response is Map<String, dynamic> ? response['data'] : null;
      final rawPrograms = data is Map<String, dynamic>
          ? data['programs']
          : null;

      if (rawPrograms is List) {
        _trainings =
            rawPrograms
                .whereType<Map<String, dynamic>>()
                .map(TrainingModel.fromJson)
                .toList(growable: true)
              ..sort((a, b) => a.startDate.compareTo(b.startDate));
      } else {
        _trainings = [];
      }
    } catch (e) {
      _error = _normalizeError(e);
      _trainings = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _normalizeError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }
}
