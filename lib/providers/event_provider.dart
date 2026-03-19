import 'package:flutter/material.dart';

import '../models/calendar_event_model.dart';
import '../services/api_service.dart';

class EventProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  List<CalendarEvent> _upcomingEvents = const [];
  List<CalendarEvent> _managedEvents = const [];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  List<CalendarEvent> get upcomingEvents => _upcomingEvents;
  List<CalendarEvent> get managedEvents => _managedEvents;

  Future<void> fetchUpcomingEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/events?upcoming=1');
      _upcomingEvents = _parseEvents(response);
    } catch (e) {
      _error = e.toString();
      _upcomingEvents = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchManagedEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/events?all=1');
      _managedEvents = _parseEvents(response);
    } catch (e) {
      _error = e.toString();
      _managedEvents = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime startsAt,
    required DateTime? endsAt,
    required bool isCompanyWide,
    required List<String> inviteEmployeeUuids,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.post('/events', {
        'title': title,
        'description': description,
        'location': location,
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt?.toIso8601String(),
        'is_company_wide': isCompanyWide,
        'invite_employee_uuids': inviteEmployeeUuids,
      });

      await Future.wait([fetchUpcomingEvents(), fetchManagedEvents()]);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updateEvent({
    required int eventId,
    required String title,
    required String description,
    required String location,
    required DateTime startsAt,
    required DateTime? endsAt,
    required bool isCompanyWide,
    required List<String> inviteEmployeeUuids,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.put('/events/$eventId', {
        'title': title,
        'description': description,
        'location': location,
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt?.toIso8601String(),
        'is_company_wide': isCompanyWide,
        'invite_employee_uuids': inviteEmployeeUuids,
      });

      await Future.wait([fetchUpcomingEvents(), fetchManagedEvents()]);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteEvent(int eventId) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete('/events/$eventId');
      await Future.wait([fetchUpcomingEvents(), fetchManagedEvents()]);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  List<CalendarEvent> _parseEvents(dynamic response) {
    if (response is! Map<String, dynamic>) {
      return const [];
    }

    final rawData = response['data'];
    if (rawData is! List) {
      return const [];
    }

    final events = rawData
        .whereType<Map<String, dynamic>>()
        .map(CalendarEvent.fromJson)
        .toList();

    events.sort((left, right) => left.startsAt.compareTo(right.startsAt));
    return events;
  }
}
