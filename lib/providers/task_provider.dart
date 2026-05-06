import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/constants/api_constants.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';

class TaskAssigneeOverride {
  const TaskAssigneeOverride({
    required this.assigneeEmployeeId,
    this.assigneeName,
    required this.assignmentScope,
  });

  final String assigneeEmployeeId;
  final String? assigneeName;
  final String assignmentScope;
}

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
  final Map<String, TaskAssigneeOverride> _assigneeOverrides =
      <String, TaskAssigneeOverride>{};

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
      final tasks = extractTasksFromResponse(response);
      if (tasks.isNotEmpty) {
        _tasks = applyRequestedAssigneeOverridesToTasks(
          tasks,
          _assigneeOverrides,
        ).toList(growable: true);
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
    String? assigneeEmployeeId,
    String? assigneeName,
    String? assigneeEmployeeRecordId,
    String assignmentScope = 'self',
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
          assigneeEmployeeId: assigneeEmployeeId,
          assigneeEmployeeRecordId: assigneeEmployeeRecordId,
          assignmentScope: assignmentScope,
        ),
      );

      final rawTask = response is Map<String, dynamic>
          ? response['data']
          : null;
      if (rawTask is Map<String, dynamic>) {
        final task = _applyRequestedAssigneeFallback(
          TaskModel.fromJson(rawTask),
          assigneeEmployeeId: assigneeEmployeeId,
          assigneeName: assigneeName,
          assignmentScope: assignmentScope,
        );
        _rememberAssigneeOverride(task.id, task);
        _upsertTask(task);
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
    String? assigneeEmployeeId,
    String? assigneeName,
    String? assigneeEmployeeRecordId,
    String assignmentScope = 'self',
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
          assigneeEmployeeId: assigneeEmployeeId,
          assigneeEmployeeRecordId: assigneeEmployeeRecordId,
          assignmentScope: assignmentScope,
        ),
      );

      final rawTask = response is Map<String, dynamic>
          ? response['data']
          : null;
      if (rawTask is Map<String, dynamic>) {
        final task = _applyRequestedAssigneeFallback(
          TaskModel.fromJson(rawTask),
          assigneeEmployeeId: assigneeEmployeeId,
          assigneeName: assigneeName,
          assignmentScope: assignmentScope,
        );
        _rememberAssigneeOverride(id, task);
        _upsertTask(task);
      } else {
        final task = _applyRequestedAssigneeFallback(
          currentTask.copyWith(
            title: title,
            description: description ?? '',
            dueDate: dueDate,
            priority: priority,
            type: type,
          ),
          assigneeEmployeeId: assigneeEmployeeId,
          assigneeName: assigneeName,
          assignmentScope: assignmentScope,
        );
        _rememberAssigneeOverride(id, task);
        _upsertTask(task);
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
    String? assigneeEmployeeId,
    String? assigneeEmployeeRecordId,
    String assignmentScope = 'self',
  }) {
    return buildTaskPayloadForRequest(
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      type: type,
      assigneeEmployeeId: assigneeEmployeeId,
      assigneeEmployeeRecordId: assigneeEmployeeRecordId,
      assignmentScope: assignmentScope,
    );
  }

  static Map<String, dynamic> buildTaskPayloadForRequest({
    required String title,
    String? description,
    DateTime? dueDate,
    required String priority,
    required String type,
    String? assigneeEmployeeId,
    String? assigneeEmployeeRecordId,
    String assignmentScope = 'self',
  }) {
    final normalizedDescription = description?.trim();
    final normalizedAssignee = assigneeEmployeeId?.trim();
    final normalizedAssigneeRecordId = assigneeEmployeeRecordId?.trim();
    final normalizedScope = assignmentScope == 'subordinate'
        ? 'subordinate'
        : 'self';
    final payload = <String, dynamic>{
      'title': title.trim(),
      'description':
          normalizedDescription == null || normalizedDescription.isEmpty
          ? null
          : normalizedDescription,
      'due_date': dueDate?.toIso8601String(),
      'priority': priority,
      'type': type,
      'assignment_scope': normalizedScope,
    };

    if (normalizedScope == 'subordinate' &&
        normalizedAssignee != null &&
        normalizedAssignee.isNotEmpty) {
      payload['assignee_employee_uuid'] = normalizedAssignee;
      payload['assigned_to_uuid'] = normalizedAssignee;
      payload['assigned_to_employee_uuid'] = normalizedAssignee;
      payload['employee_uuid'] = normalizedAssignee;
    }

    if (normalizedScope == 'subordinate' &&
        normalizedAssigneeRecordId != null &&
        normalizedAssigneeRecordId.isNotEmpty) {
      payload['employee_id'] = normalizedAssigneeRecordId;
      payload['assignee_employee_id'] = normalizedAssigneeRecordId;
      payload['assignee_id'] = normalizedAssigneeRecordId;
      payload['assigned_to'] = normalizedAssigneeRecordId;
      payload['assigned_to_employee_id'] = normalizedAssigneeRecordId;
      payload['assigned_employee_id'] = normalizedAssigneeRecordId;
      payload['target_employee_id'] = normalizedAssigneeRecordId;
      payload['recipient_employee_id'] = normalizedAssigneeRecordId;
    } else if (normalizedScope == 'subordinate' &&
        normalizedAssignee != null &&
        normalizedAssignee.isNotEmpty) {
      payload['assignee_employee_id'] = normalizedAssignee;
      payload['assigned_to'] = normalizedAssignee;
    }

    return payload;
  }

  TaskModel _applyRequestedAssigneeFallback(
    TaskModel task, {
    String? assigneeEmployeeId,
    String? assigneeName,
    required String assignmentScope,
  }) {
    return applyRequestedAssigneeFallbackForTask(
      task,
      assigneeEmployeeId: assigneeEmployeeId,
      assigneeName: assigneeName,
      assignmentScope: assignmentScope,
    );
  }

  static List<TaskModel> extractTasksFromResponse(dynamic response) {
    if (response is! Map<String, dynamic>) {
      return const [];
    }

    final data = response['data'];
    final rawTasks = data is List
        ? data
        : data is Map<String, dynamic>
        ? data['tasks']
        : response['tasks'];

    if (rawTasks is! List) {
      return const [];
    }

    return rawTasks
        .whereType<Map>()
        .map((item) => TaskModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  static TaskModel applyRequestedAssigneeFallbackForTask(
    TaskModel task, {
    String? assigneeEmployeeId,
    String? assigneeName,
    required String assignmentScope,
  }) {
    final normalizedAssignee = assigneeEmployeeId?.trim();
    final normalizedAssigneeName = assigneeName?.trim();
    if (assignmentScope != 'subordinate' ||
        normalizedAssignee == null ||
        normalizedAssignee.isEmpty) {
      return task;
    }

    return task.copyWith(
      assigneeEmployeeId: normalizedAssignee,
      assigneeName:
          normalizedAssigneeName ??
          ((task.assigneeName?.trim().isNotEmpty ?? false)
              ? task.assigneeName
              : null),
      assignmentScope: 'subordinate',
    );
  }

  static List<TaskModel> applyRequestedAssigneeOverridesToTasks(
    Iterable<TaskModel> tasks,
    Map<String, TaskAssigneeOverride> overrides,
  ) {
    return tasks
        .map((task) {
          final override = overrides[task.id];
          if (override == null) {
            return task;
          }

          return applyRequestedAssigneeFallbackForTask(
            task,
            assigneeEmployeeId: override.assigneeEmployeeId,
            assigneeName: override.assigneeName,
            assignmentScope: override.assignmentScope,
          );
        })
        .toList(growable: false);
  }

  void _rememberAssigneeOverride(String id, TaskModel task) {
    if (task.assignmentScope == 'subordinate' &&
        (task.assigneeEmployeeId?.trim().isNotEmpty ?? false)) {
      _assigneeOverrides[id] = TaskAssigneeOverride(
        assigneeEmployeeId: task.assigneeEmployeeId!.trim(),
        assigneeName: task.assigneeName,
        assignmentScope: 'subordinate',
      );
      return;
    }

    _assigneeOverrides.remove(id);
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
