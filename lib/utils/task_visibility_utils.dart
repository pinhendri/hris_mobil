import '../models/task_model.dart';
import '../models/user.dart';

List<TaskModel> tasksForMyTaskCards(
  Iterable<TaskModel> tasks,
  User? user, {
  Set<String>? subordinateAssigneeIds,
}) {
  return tasks
      .where(
        (task) =>
            taskBelongsToSelfView(task, user) ||
            taskBelongsToSubordinateView(
              task,
              user,
              subordinateAssigneeIds: subordinateAssigneeIds,
            ),
      )
      .toList(growable: false);
}

bool taskBelongsToSelfView(TaskModel task, User? user) {
  return !task.isAssignedToSubordinate || taskIsAssignedToUser(task, user);
}

bool taskBelongsToSubordinateView(
  TaskModel task,
  User? user, {
  Set<String>? subordinateAssigneeIds,
}) {
  if (!task.isAssignedToSubordinate || taskIsAssignedToUser(task, user)) {
    return false;
  }

  if (subordinateAssigneeIds == null) {
    return true;
  }

  final assigneeId = _normalizeTaskIdentity(task.assigneeEmployeeId);
  return assigneeId != null && subordinateAssigneeIds.contains(assigneeId);
}

bool taskIsAssignedToUser(TaskModel task, User? user) {
  final assigneeId = _normalizeTaskIdentity(task.assigneeEmployeeId);
  if (assigneeId == null || assigneeId.isEmpty || user == null) {
    return false;
  }

  return taskUserIdentityValues(user).contains(assigneeId);
}

Set<String> normalizeTaskIdentityValues(Iterable<String?> values) {
  return values.map(_normalizeTaskIdentity).whereType<String>().toSet();
}

String? _normalizeTaskIdentity(String? value) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty || normalized == 'null') {
    return null;
  }

  return normalized;
}

Set<String> taskUserIdentityValues(User user) {
  return {
        user.id.toString(),
        user.uuid,
        if (user.employeeUuid != null) user.employeeUuid!,
        if (user.employeeRecordId != null) user.employeeRecordId!,
        user.employeeId,
        user.email,
      }
      .map((value) => value.trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .toSet();
}
