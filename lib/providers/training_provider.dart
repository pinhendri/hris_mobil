import 'package:flutter/material.dart';
import '../models/training_model.dart';

class TrainingProvider with ChangeNotifier {
  List<TrainingModel> _trainings = [];
  bool _isLoading = false;

  List<TrainingModel> get trainings => _trainings;
  bool get isLoading => _isLoading;

  TrainingProvider() {
    _loadMockData();
  }

  Future<void> _loadMockData() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _trainings = [
      TrainingModel(
        id: '1',
        title: 'Flutter Advanced Development',
        instructor: 'John Doe',
        description: 'Deep dive into Flutter internals, state management, and performance optimization.',
        startDate: DateTime.now().add(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        status: 'upcoming',
        progress: 0.0,
        type: 'online',
        location: 'Zoom',
      ),
      TrainingModel(
        id: '2',
        title: 'Leadership & Management',
        instructor: 'Jane Smith',
        description: 'Essential skills for new managers and team leaders.',
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 20)),
        status: 'ongoing',
        progress: 0.45,
        type: 'offline',
        location: 'HQ Conference Room A',
      ),
      TrainingModel(
        id: '3',
        title: 'Cybersecurity Awareness',
        instructor: 'Security Team',
        description: 'Annual mandatory security training for all employees.',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().subtract(const Duration(days: 25)),
        status: 'completed',
        progress: 1.0,
        type: 'online',
        location: 'LMS Portal',
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _loadMockData();
  }
}
