import 'kanban_task.dart';

abstract class BoardSource {
  Future<List<KanbanTask>> loadTasks();

  Future<void> saveTaskPosition({
    required int indicatorToMoId,
    required int parentId,
    required int order,
  });
}
