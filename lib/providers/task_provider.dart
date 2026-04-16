import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/constants/api_constants.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';

class TaskProvider with ChangeNotifier {
  TaskProvider() {
    refresh();
  }

  final ApiService _apiService = ApiService();
  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _error;
  final Set<String> _updatingTaskIds = <String>{};
  final Set<String> _deletingTaskIds = <String>{};

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool isUpdating(String id) => _updatingTaskIds.contains(id);
  bool isDeleting(String id) => _deletingTaskIds.contains(id);

  Future<void> fetchTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(
        ApiConstants.tasksEndpoint.replaceFirst('/api', ''),
      );
      final rawTasks = response is Map<String, dynamic>
          ? response['data']
          : null;

      if (rawTasks is List) {
        _tasks = rawTasks
            .whereType<Map<String, dynamic>>()
            .map(TaskModel.fromJson)
            .toList(growable: true);
        _sortTasks();
      } else {
        _tasks = [];
      }
    } catch (e) {
      _error = _normalizeError(e);
      _tasks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleTaskStatus(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) {
      return false;
    }

    if (!_tasks[index].canToggle) {
      _error = 'Task ini tidak bisa diubah statusnya.';
      notifyListeners();
      return false;
    }

    _updatingTaskIds.add(id);
    _error = null;
    notifyListeners();

    final task = _tasks[index];
    final nextStatus = !task.isCompleted;

    try {
      final response = await _apiService.put(
        '${ApiConstants.taskStatusEndpoint.replaceFirst('/api', '')}/$id/status',
        {'is_completed': nextStatus},
      );
      final rawTask = response is Map<String, dynamic>
          ? response['data']
          : null;

      if (rawTask is Map<String, dynamic>) {
        _tasks[index] = TaskModel.fromJson(rawTask);
      } else {
        _tasks[index] = task.copyWith(isCompleted: nextStatus);
      }

      _sortTasks();
      notifyListeners();
      return true;
    } catch (e) {
      _error = _normalizeError(e);
      notifyListeners();
      return false;
    } finally {
      _updatingTaskIds.remove(id);
      notifyListeners();
    }
  }

  Future<bool> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    String priority = 'medium',
    String type = 'regular',
  }) async {
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        ApiConstants.tasksEndpoint.replaceFirst('/api', ''),
        _buildTaskPayload(
          title: title,
          description: description,
          dueDate: dueDate,
          priority: priority,
          type: type,
        ),
      );

      final rawTask = response is Map<String, dynamic>
          ? response['data']
          : null;
      if (rawTask is Map<String, dynamic>) {
        _upsertTask(TaskModel.fromJson(rawTask));
      }

      return true;
    } catch (e) {
      _error = _normalizeError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask({
    required String id,
    required String title,
    String? description,
    DateTime? dueDate,
    String priority = 'medium',
    String type = 'regular',
  }) async {
    final currentTask = _tasks.cast<TaskModel?>().firstWhere(
      (task) => task?.id == id,
      orElse: () => null,
    );
    if (currentTask == null) {
      _error = 'Task tidak ditemukan.';
      notifyListeners();
      return false;
    }

    if (!currentTask.canEdit) {
      _error = 'Task ini tidak bisa diedit.';
      notifyListeners();
      return false;
    }

    _updatingTaskIds.add(id);
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put(
        '${ApiConstants.tasksEndpoint.replaceFirst('/api', '')}/$id',
        _buildTaskPayload(
          title: title,
          description: description,
          dueDate: dueDate,
          priority: priority,
          type: type,
        ),
      );

      final rawTask = response is Map<String, dynamic>
          ? response['data']
          : null;
      if (rawTask is Map<String, dynamic>) {
        _upsertTask(TaskModel.fromJson(rawTask));
      }

      return true;
    } catch (e) {
      _error = _normalizeError(e);
      notifyListeners();
      return false;
    } finally {
      _updatingTaskIds.remove(id);
      notifyListeners();
    }
  }

  Future<bool> deleteTask(String id) async {
    final currentTask = _tasks.cast<TaskModel?>().firstWhere(
      (task) => task?.id == id,
      orElse: () => null,
    );
    if (currentTask == null) {
      _error = 'Task tidak ditemukan.';
      notifyListeners();
      return false;
    }

    if (!currentTask.canDelete) {
      _error = 'Task ini tidak bisa dihapus.';
      notifyListeners();
      return false;
    }

    _deletingTaskIds.add(id);
    _error = null;
    notifyListeners();

    try {
      await _apiService.delete(
        '${ApiConstants.tasksEndpoint.replaceFirst('/api', '')}/$id',
      );
      _tasks.removeWhere((task) => task.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _normalizeError(e);
      notifyListeners();
      return false;
    } finally {
      _deletingTaskIds.remove(id);
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await fetchTasks();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Map<String, dynamic> _buildTaskPayload({
    required String title,
    String? description,
    DateTime? dueDate,
    required String priority,
    required String type,
  }) {
    final normalizedDescription = description?.trim();
    return {
      'title': title.trim(),
      'description':
          normalizedDescription == null || normalizedDescription.isEmpty
          ? null
          : normalizedDescription,
      'due_date': dueDate?.toIso8601String(),
      'priority': priority,
      'type': type,
    };
  }

  void _upsertTask(TaskModel task) {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      _tasks.add(task);
    } else {
      _tasks[index] = task;
    }
    _sortTasks();
    notifyListeners();
  }

  void _sortTasks() {
    _tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      final priorityCompare = _priorityWeight(
        a.priority,
      ).compareTo(_priorityWeight(b.priority));
      if (priorityCompare != 0) {
        return priorityCompare;
      }

      if (a.dueDate == null && b.dueDate == null) {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
      if (a.dueDate == null) {
        return 1;
      }
      if (b.dueDate == null) {
        return -1;
      }

      return a.dueDate!.compareTo(b.dueDate!);
    });
  }

  int _priorityWeight(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 0;
      case 'medium':
        return 1;
      default:
        return 2;
    }
  }

  String _normalizeError(Object error) {
    final rawMessage = error.toString();
    final message = rawMessage.startsWith('Exception: ')
        ? rawMessage.substring('Exception: '.length)
        : rawMessage;
    final backendMessage = _extractBackendMessage(message);

    if (backendMessage != null) {
      final normalizedBackendMessage = backendMessage.trim();
      if (normalizedBackendMessage.contains('route api/tasks') ||
          normalizedBackendMessage.contains('route api/tasks/') ||
          normalizedBackendMessage.contains('/api/tasks')) {
        return 'Endpoint Tasks belum tersedia di server. Upload backend Tasks, lalu jalankan clear cache route.';
      }

      return normalizedBackendMessage;
    }

    return message;
  }

  String? _extractBackendMessage(String message) {
    final jsonStart = message.indexOf('{');
    if (jsonStart == -1) {
      return null;
    }

    final payload = message.substring(jsonStart);

    try {
      final decoded = json.decode(payload);
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {
      // Keep the original message if the payload is not valid JSON.
    }

    return null;
  }
}
