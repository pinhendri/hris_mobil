import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/models/task_model.dart';
import 'package:hris_mobile/providers/task_provider.dart';

void main() {
  test('parses assignee and creator metadata from backend task payload', () {
    final task = TaskModel.fromJson({
      'id': 'task-1',
      'title': 'Prepare payroll evidence',
      'description': 'Upload supporting docs',
      'due_date': '2026-05-08T09:00:00.000',
      'priority': 'high',
      'type': 'regular',
      'assignee_employee_id': 'emp-22',
      'assignee_name': 'Sinta Ayu',
      'created_by_name': 'Budi Manager',
      'assignment_scope': 'subordinate',
    });

    expect(task.assigneeEmployeeId, 'emp-22');
    expect(task.assigneeName, 'Sinta Ayu');
    expect(task.createdByName, 'Budi Manager');
    expect(task.assignmentScope, 'subordinate');
    expect(task.isAssignedToSubordinate, isTrue);
  });

  test('treats backend task with assignee but no scope as subordinate', () {
    final task = TaskModel.fromJson({
      'id': 'task-2',
      'title': 'Follow up branch checklist',
      'employee_id': 42,
      'employee_name': 'Rina Staff',
    });

    expect(task.assigneeEmployeeId, '42');
    expect(task.assignmentScope, 'subordinate');
    expect(task.isAssignedToSubordinate, isTrue);
  });

  test('parses assignee uuid fields from backend task payload', () {
    final task = TaskModel.fromJson({
      'id': 'task-uuid',
      'title': 'UUID assignee',
      'description': 'Assigned by uuid',
      'assigned_to_uuid': 'employee-rba',
    });

    expect(task.assigneeEmployeeId, 'employee-rba');
    expect(task.assignmentScope, 'subordinate');
  });

  test('builds task payload with assignee for subordinate task', () {
    final payload = TaskProvider.buildTaskPayloadForRequest(
      title: 'Review outlet checklist',
      description: 'Check closing evidence',
      dueDate: DateTime(2026, 5, 9, 9),
      priority: 'medium',
      type: 'regular',
      assigneeEmployeeId: 'employee-uuid-7',
      assigneeEmployeeRecordId: '42',
      assignmentScope: 'subordinate',
    );

    expect(payload['title'], 'Review outlet checklist');
    expect(payload['assignee_employee_id'], '42');
    expect(payload['assigned_to'], '42');
    expect(payload['assignee_employee_uuid'], 'employee-uuid-7');
    expect(payload['assigned_to_uuid'], 'employee-uuid-7');
    expect(payload['assigned_to_employee_uuid'], 'employee-uuid-7');
    expect(payload['employee_uuid'], 'employee-uuid-7');
    expect(payload['employee_id'], '42');
    expect(payload['assigned_to_employee_id'], '42');
    expect(payload['assigned_employee_id'], '42');
    expect(payload['target_employee_id'], '42');
    expect(payload['recipient_employee_id'], '42');
    expect(payload['assignment_scope'], 'subordinate');
  });

  test('builds self task payload without assignee fields', () {
    final payload = TaskProvider.buildTaskPayloadForRequest(
      title: 'Send daily recap',
      description: '',
      dueDate: null,
      priority: 'low',
      type: 'regular',
      assigneeEmployeeId: null,
      assignmentScope: 'self',
    );

    expect(payload['description'], isNull);
    expect(payload['assignment_scope'], 'self');
    expect(payload.containsKey('assignee_employee_id'), isFalse);
    expect(payload.containsKey('assigned_to'), isFalse);
  });

  test(
    'applies requested subordinate assignee when backend response is stale',
    () {
      final staleBackendTask = TaskModel.fromJson({
        'id': 'task-3',
        'title': 'Check report',
        'assignment_scope': 'self',
      });

      final merged = TaskProvider.applyRequestedAssigneeFallbackForTask(
        staleBackendTask,
        assigneeEmployeeId: 'employee-uuid-7',
        assigneeName: 'rba@kkk.com',
        assignmentScope: 'subordinate',
      );

      expect(merged.assignmentScope, 'subordinate');
      expect(merged.assigneeEmployeeId, 'employee-uuid-7');
      expect(merged.assigneeName, 'rba@kkk.com');
    },
  );

  test('overrides stale backend assignee with requested edit assignee', () {
    final staleBackendTask = TaskModel.fromJson({
      'id': 'task-4',
      'title': 'Reassign report',
      'assignment_scope': 'subordinate',
      'assignee_employee_id': 'old-employee',
      'assignee_name': 'Old Employee',
    });

    final merged = TaskProvider.applyRequestedAssigneeFallbackForTask(
      staleBackendTask,
      assigneeEmployeeId: 'new-employee',
      assigneeName: 'New Employee',
      assignmentScope: 'subordinate',
    );

    expect(merged.assigneeEmployeeId, 'new-employee');
    expect(merged.assigneeName, 'New Employee');
    expect(merged.assignmentScope, 'subordinate');
  });

  test('extracts tasks when backend wraps list under data.tasks', () {
    final tasks = TaskProvider.extractTasksFromResponse({
      'data': {
        'tasks': [
          {'id': 1, 'title': 'Wrapped', 'description': 'Task'},
        ],
      },
    });

    expect(tasks, hasLength(1));
    expect(tasks.first.title, 'Wrapped');
  });

  test('applies requested assignee overrides to fetched stale tasks', () {
    final fetchedTasks = [
      TaskModel.fromJson({
        'id': 'task-5',
        'title': 'Fetched old assignee',
        'assignment_scope': 'subordinate',
        'assignee_employee_id': 'old-employee',
        'assignee_name': 'Old Employee',
      }),
    ];

    final merged =
        TaskProvider.applyRequestedAssigneeOverridesToTasks(fetchedTasks, {
          'task-5': const TaskAssigneeOverride(
            assigneeEmployeeId: 'new-employee',
            assigneeName: 'New Employee',
            assignmentScope: 'subordinate',
          ),
        });

    expect(merged.single.assigneeEmployeeId, 'new-employee');
    expect(merged.single.assigneeName, 'New Employee');
  });
}
