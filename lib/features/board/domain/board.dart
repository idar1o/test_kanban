import 'package:equatable/equatable.dart';

import 'kanban_task.dart';

class Board extends Equatable {
  const Board({
    this.tasks = const [],
    this.columnOrder = const [],
    this.isLoading = false,
    this.error,
    this.savingTaskIds = const {},
  });

  final List<KanbanTask> tasks;
  final List<int> columnOrder;
  final bool isLoading;
  final Object? error;
  final Set<int> savingTaskIds;

  static const Board initial = Board(isLoading: true);

  Board copyWith({
    List<KanbanTask>? tasks,
    List<int>? columnOrder,
    bool? isLoading,
    Object? error,
    bool clearError = false,
    Set<int>? savingTaskIds,
  }) {
    return Board(
      tasks: tasks ?? this.tasks,
      columnOrder: columnOrder ?? this.columnOrder,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      savingTaskIds: savingTaskIds ?? this.savingTaskIds,
    );
  }

  @override
  List<Object?> get props => [tasks, columnOrder, isLoading, error, savingTaskIds];
}
