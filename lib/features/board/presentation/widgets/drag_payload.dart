import '../../domain/kanban_task.dart';

class TaskDragPayload {
  const TaskDragPayload({required this.task});
  final KanbanTask task;
}

class ColumnDragPayload {
  const ColumnDragPayload({required this.parentId});
  final int parentId;
}
