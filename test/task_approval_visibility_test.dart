import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/models/task_model.dart';
import 'package:hris_mobile/utils/task_approval_utils.dart';

void main() {
  test('counts pending tasks assigned by manager for approval tab badge', () {
    final tasks = [
      TaskModel.fromJson({
        'id': 1,
        'title': 'Assigned',
        'description': 'From manager',
        'status': 'pending',
        'assignment_scope': 'subordinate',
        'assignee_employee_id': 'rba-uuid',
      }),
      TaskModel.fromJson({
        'id': 2,
        'title': 'Done assigned',
        'description': 'Already complete',
        'is_completed': true,
        'assignment_scope': 'subordinate',
        'assignee_employee_id': 'rba-uuid',
      }),
      TaskModel.fromJson({
        'id': 3,
        'title': 'Self task',
        'description': 'Personal task',
        'status': 'pending',
        'assignment_scope': 'self',
      }),
    ];

    expect(pendingAssignedTaskCountForApproval(tasks), 1);
  });
}
