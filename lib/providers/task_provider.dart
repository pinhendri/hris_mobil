import 'package:flutter/material.dart';
import '../models/task_model.dart';

class TaskProvider with ChangeNotifier {
  List<TaskModel> _tasks = [];
  bool _isLoading = false;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;

  TaskProvider() {
    _loadMockData();
  }

  Future<void> _loadMockData() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _tasks = [
      TaskModel(
        id: '1',
        title: 'Complete Employee Profile',
        description: 'Fill in your personal details, emergency contacts, and bank information.',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        isCompleted: false,
        priority: 'high',
        type: 'onboarding',
      ),
      TaskModel(
        id: '2',
        title: 'Upload ID Documents',
        description: 'Upload a clear copy of your National ID and Passport.',
        dueDate: DateTime.now().add(const Duration(days: 3)),
        isCompleted: true,
        priority: 'high',
        type: 'onboarding',
      ),
      TaskModel(
        id: '3',
        title: 'Read Employee Handbook',
        description: 'Read and acknowledge the company policies and employee handbook.',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        isCompleted: false,
        priority: 'medium',
        type: 'onboarding',
      ),
      TaskModel(
        id: '4',
        title: 'IT Security Setup',
        description: 'Setup 2FA and configure VPN access.',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        isCompleted: false,
        priority: 'high',
        type: 'regular',
      ),
      TaskModel(
        id: '5',
        title: 'Submit Asset Handover Form',
        description: 'Return laptop and access card before last working day.',
        dueDate: DateTime.now().add(const Duration(days: 30)),
        isCompleted: false,
        priority: 'high',
        type: 'offboarding',
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  void toggleTaskStatus(String id) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _loadMockData();
  }
}
