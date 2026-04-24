import 'dart:async';
import 'dart:developer' as developer;

import 'board.dart';
import 'board_source.dart';
import 'kanban_task.dart';

class BoardColumn {
  const BoardColumn({
    required this.parentId,
    required this.name,
    required this.tasks,
  });

  final int parentId;
  final String name;
  final List<KanbanTask> tasks;
}

class BoardInteractor {
  BoardInteractor({required BoardSource source}) : _source = source;

  final BoardSource _source;
  final StreamController<Board> _controller = StreamController<Board>.broadcast();

  Board _state = Board.initial;

  Board get state => _state;
  Stream<Board> get stream => _controller.stream;

  Future<void> init() async {
    _emit(_state.copyWith(isLoading: true, clearError: true));
    try {
      final tasks = await _source.loadTasks();
      final columnOrder = _mergeColumnOrder(_state.columnOrder, tasks);
      _emit(Board(
        tasks: tasks,
        columnOrder: columnOrder,
        isLoading: false,
      ));
    } catch (e) {
      _emit(_state.copyWith(isLoading: false, error: e));
    }
  }

  Future<void> refresh() => init();

  List<BoardColumn> get columns {
    final tasks = _state.tasks;
    final nameById = {for (final t in tasks) t.indicatorToMoId: t.name};

    final grouped = <int, List<KanbanTask>>{};
    for (final t in tasks) {
      grouped.putIfAbsent(t.parentId, () => []).add(t);
    }

    final ordered = <BoardColumn>[];
    for (final pid in _state.columnOrder) {
      final list = grouped[pid];
      if (list == null) continue;
      list.sort((a, b) => a.order.compareTo(b.order));
      final name = nameById[pid] ?? (pid == 0 ? 'Без папки' : 'Папка #$pid');
      ordered.add(BoardColumn(
        parentId: pid,
        name: name,
        tasks: List.unmodifiable(list),
      ));
    }
    return ordered;
  }

  Future<void> moveTask({
    required int taskId,
    required int newParentId,
    required int newOrder,
  }) async {
    final snapshot = _state;
    final idx = snapshot.tasks.indexWhere((t) => t.indicatorToMoId == taskId);
    if (idx == -1) return;

    final source = snapshot.tasks[idx];
    final sameColumn = source.parentId == newParentId;

    final sourceSorted = snapshot.tasks
        .where((t) => t.parentId == source.parentId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final sourceVisualIdx =
        sourceSorted.indexWhere((t) => t.indicatorToMoId == taskId);

    if (sameColumn && newOrder == sourceVisualIdx) {
      developer.log(
        'moveTask noop: task=$taskId already at board=$newParentId position=$newOrder',
        name: 'BoardInteractor',
      );
      return;
    }

    final targetSorted = sameColumn
        ? <KanbanTask>[]
        : (snapshot.tasks
            .where((t) => t.parentId == newParentId)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order)));

    final List<KanbanTask> reindexedSource;
    final List<KanbanTask> reindexedTarget;

    if (sameColumn) {
      final list = List<KanbanTask>.from(sourceSorted)..removeAt(sourceVisualIdx);
      final insertAt = newOrder.clamp(0, list.length);
      list.insert(insertAt, source.copyWith(order: insertAt));
      reindexedSource = [
        for (int i = 0; i < list.length; i++) list[i].copyWith(order: i),
      ];
      reindexedTarget = const [];
    } else {
      final sourceWithout = List<KanbanTask>.from(sourceSorted)
        ..removeAt(sourceVisualIdx);
      reindexedSource = [
        for (int i = 0; i < sourceWithout.length; i++)
          sourceWithout[i].copyWith(order: i),
      ];

      final list = List<KanbanTask>.from(targetSorted);
      final insertAt = newOrder.clamp(0, list.length);
      list.insert(
        insertAt,
        source.copyWith(parentId: newParentId, order: insertAt),
      );
      reindexedTarget = [
        for (int i = 0; i < list.length; i++) list[i].copyWith(order: i),
      ];
    }

    final affectedParents = sameColumn
        ? {source.parentId}
        : {source.parentId, newParentId};

    final untouched = snapshot.tasks
        .where((t) => !affectedParents.contains(t.parentId))
        .toList();
    final newTasks = [...untouched, ...reindexedSource, ...reindexedTarget];

    final byIdBefore = {
      for (final t in snapshot.tasks) t.indicatorToMoId: t,
    };
    final changed = <KanbanTask>[];
    for (final t in newTasks) {
      final old = byIdBefore[t.indicatorToMoId];
      if (old == null) continue;
      if (old.parentId != t.parentId || old.order != t.order) {
        changed.add(t);
      }
    }

    developer.log(
      'moveTask: task=$taskId "${source.name}" '
      'from board=${source.parentId} position=$sourceVisualIdx (order=${source.order}) '
      'to board=$newParentId position=$newOrder; '
      'reindex saves ${changed.length} task(s)',
      name: 'BoardInteractor',
    );

    if (changed.isEmpty) {
      return;
    }

    _emit(snapshot.copyWith(
      tasks: newTasks,
      savingTaskIds: {
        ...snapshot.savingTaskIds,
        for (final t in changed) t.indicatorToMoId,
      },
      clearError: true,
    ));

    try {
      await Future.wait(
        changed.map(
          (t) => _source.saveTaskPosition(
            indicatorToMoId: t.indicatorToMoId,
            parentId: t.parentId,
            order: t.order,
          ),
        ),
      );
      developer.log(
        'moveTask OK: saved ${changed.length} task(s)',
        name: 'BoardInteractor',
      );
      final remaining = Set<int>.from(_state.savingTaskIds);
      for (final t in changed) {
        remaining.remove(t.indicatorToMoId);
      }
      _emit(_state.copyWith(savingTaskIds: remaining));
    } catch (e) {
      developer.log(
        'moveTask FAIL: $e, rolled back ${changed.length} task(s)',
        name: 'BoardInteractor',
      );
      _emit(snapshot.copyWith(error: e));
    }
  }

  void moveColumn({required int parentId, required int toIndex}) {
    final current = _state.columnOrder;
    final fromIndex = current.indexOf(parentId);
    if (fromIndex == -1) return;

    final adjusted = toIndex > fromIndex ? toIndex - 1 : toIndex;
    if (adjusted == fromIndex) {
      developer.log(
        'moveColumn noop: board=$parentId already at index=$fromIndex',
        name: 'BoardInteractor',
      );
      return;
    }

    final newOrder = List<int>.from(current)..removeAt(fromIndex);
    newOrder.insert(adjusted, parentId);

    developer.log(
      'moveColumn: board=$parentId from index=$fromIndex to index=$adjusted',
      name: 'BoardInteractor',
    );

    _emit(_state.copyWith(columnOrder: newOrder));
  }

  List<int> _mergeColumnOrder(List<int> previous, List<KanbanTask> tasks) {
    final allParents = <int>{for (final t in tasks) t.parentId};
    final preserved = previous.where(allParents.contains).toList();
    final appended = (allParents.toList()..sort())
        .where((p) => !preserved.contains(p));
    return [...preserved, ...appended];
  }

  void _emit(Board next) {
    _state = next;
    _controller.add(next);
  }

  Future<void> dispose() => _controller.close();
}
