import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/models/task_model.dart';
import 'package:hris_mobile/models/user.dart';
import 'package:hris_mobile/utils/task_visibility_utils.dart';

void main() {
  final rba = User(
    id: 17,
    name: 'Rba',
    email: 'rba@kkk.com',
    uuid: 'user-rba',
    employeeUuid: 'employee-rba',
    employeeRecordId: '42',
    position: '',
    selectedCCode: '',
    permissions: [],
  );

  test('assigned subordinate task belongs to self view for assignee', () {
    final task = TaskModel.fromJson({
      'id': 1,
      'title': 'Assigned to rba',
      'description': 'From manager',
      'assignment_scope': 'subordinate',
      'assignee_employee_id': 'employee-rba',
      'assignee_name': 'Rba',
    });

    expect(taskBelongsToSelfView(task, rba), isTrue);
    expect(taskBelongsToSubordinateView(task, rba), isFalse);
  });

  test('assigned task stays in subordinate view for manager', () {
    final manager = User(
      id: 1,
      name: 'Manager',
      email: 'manager@kkk.com',
      uuid: 'user-manager',
      employeeUuid: 'employee-manager',
      position: '',
      selectedCCode: '',
      permissions: [],
    );

    final task = TaskModel.fromJson({
      'id': 2,
      'title': 'Assigned to rba',
      'description': 'From manager',
      'assignment_scope': 'subordinate',
      'assignee_employee_id': 'employee-rba',
      'assignee_name': 'Rba',
    });

    expect(taskBelongsToSelfView(task, manager), isFalse);
    expect(taskBelongsToSubordinateView(task, manager), isTrue);
  });

  test(
    'matches assigned task by employee record id when backend returns number',
    () {
      final task = TaskModel.fromJson({
        'id': 3,
        'title': 'Assigned to rba by record id',
        'description': 'From manager',
        'assignment_scope': 'subordinate',
        'employee_id': 42,
        'assignee_name': 'Rba',
      });

      expect(taskBelongsToSelfView(task, rba), isTrue);
      expect(taskBelongsToSubordinateView(task, rba), isFalse);
    },
  );

  test('counts only self and subordinate tree tasks for hen my task cards', () {
    final hen = User(
      id: 1,
      name: 'Hen',
      email: 'hen@kkk.com',
      uuid: 'user-hen',
      employeeUuid: 'employee-hen',
      employeeRecordId: '10',
      position: '',
      selectedCCode: '',
      permissions: [],
    );

    final tasks = [
      TaskModel.fromJson({
        'id': 1,
        'title': 'Self no assignee',
        'description': 'Personal',
        'assignment_scope': 'self',
      }),
      TaskModel.fromJson({
        'id': 2,
        'title': 'Assigned to hen',
        'description': 'Personal assignment',
        'assignment_scope': 'subordinate',
        'assignee_employee_id': 'employee-hen',
      }),
      TaskModel.fromJson({
        'id': 3,
        'title': 'Assigned to rba',
        'description': 'Subordinate',
        'assignment_scope': 'subordinate',
        'assignee_employee_id': 'employee-rba',
      }),
      TaskModel.fromJson({
        'id': 4,
        'title': 'Other manager task',
        'description': 'Not in hen tree',
        'assignment_scope': 'subordinate',
        'assignee_employee_id': 'employee-other',
      }),
    ];

    final subordinateIds = {'employee-rba'};
    final visible = tasksForMyTaskCards(
      tasks,
      hen,
      subordinateAssigneeIds: subordinateIds,
    );

    expect(visible, hasLength(3));
    expect(
      visible.where((task) => taskBelongsToSelfView(task, hen)),
      hasLength(2),
    );
    expect(
      visible.where(
        (task) => taskBelongsToSubordinateView(
          task,
          hen,
          subordinateAssigneeIds: subordinateIds,
        ),
      ),
      hasLength(1),
    );
  });
}
