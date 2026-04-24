import '../domain/board_source.dart';
import '../domain/kanban_task.dart';

class BoardStubSource implements BoardSource {
  final List<KanbanTask> _tasks = [
    const KanbanTask(indicatorToMoId: 1, parentId: 0, name: 'To Do', order: 0),
    const KanbanTask(indicatorToMoId: 2, parentId: 0, name: 'In Progress', order: 1),
    const KanbanTask(indicatorToMoId: 3, parentId: 0, name: 'Done', order: 2),
    const KanbanTask(indicatorToMoId: 10, parentId: 1, name: 'Сверстать лендинг', order: 0),
    const KanbanTask(indicatorToMoId: 11, parentId: 1, name: 'Написать ТЗ', order: 1),
    const KanbanTask(indicatorToMoId: 12, parentId: 2, name: 'Интеграция API', order: 0),
    const KanbanTask(indicatorToMoId: 13, parentId: 3, name: 'Релиз v1.0', order: 0),
  ];

  @override
  Future<List<KanbanTask>> loadTasks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_tasks);
  }

  @override
  Future<void> saveTaskPosition({
    required int indicatorToMoId,
    required int parentId,
    required int order,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _tasks.indexWhere((t) => t.indicatorToMoId == indicatorToMoId);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(parentId: parentId, order: order);
    }
  }
}
