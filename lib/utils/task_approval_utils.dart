import '../models/task_model.dart';

int pendingAssignedTaskCountForApproval(Iterable<TaskModel> tasks) {
  return tasks
      .where((task) => !task.isCompleted && task.isAssignedToSubordinate)
      .length;
}
