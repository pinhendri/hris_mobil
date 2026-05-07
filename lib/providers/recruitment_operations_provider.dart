import 'package:flutter/material.dart';

import '../models/recruitment_operations_model.dart';
import '../services/api_service.dart';

class RecruitmentOperationsProvider extends ChangeNotifier {
  RecruitmentOperationsProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  List<RecruitmentOpsApplicationOption> _applications = [];
  List<RecruitmentOpsInterviewerOption> _interviewers = [];
  List<InterviewSchedule> _schedules = [];
  List<JobOffer> _offers = [];
  bool _isLoading = false;
  String? _error;

  List<RecruitmentOpsApplicationOption> get applications => _applications;
  List<RecruitmentOpsInterviewerOption> get interviewers => _interviewers;
  List<InterviewSchedule> get schedules => _schedules;
  List<JobOffer> get offers => _offers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/recruitment/ops');
      final rawData = response is Map && response['data'] is Map
          ? response['data']
          : response;

      if (rawData is Map) {
        final data = RecruitmentOperationsData.fromJson(
          Map<String, dynamic>.from(rawData),
        );
        _applications = data.applications;
        _interviewers = data.interviewers;
        _schedules = data.schedules;
        _offers = data.offers;
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveSchedule(Map<String, dynamic> payload) {
    return _submit(
      () => _apiService.post('/recruitment/ops/schedules', payload),
    );
  }

  Future<bool> deleteSchedule(int id) {
    return _submit(() => _apiService.delete('/recruitment/ops/schedules/$id'));
  }

  Future<bool> saveFeedback(Map<String, dynamic> payload) {
    return _submit(
      () => _apiService.post('/recruitment/ops/feedback', payload),
    );
  }

  Future<bool> saveOffer(Map<String, dynamic> payload) {
    return _submit(() => _apiService.post('/recruitment/ops/offers', payload));
  }

  Future<bool> updateOfferStatus(int id, String status) {
    return _submit(
      () => _apiService.post('/recruitment/ops/offers/$id/status', {
        'offer_status': status,
      }),
    );
  }

  Future<bool> _submit(Future<dynamic> Function() request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await request();
      await loadData();
      return true;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
