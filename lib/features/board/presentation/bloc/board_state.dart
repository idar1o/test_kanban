import 'package:equatable/equatable.dart';

import '../../domain/board.dart';
import '../../domain/board_interactor.dart';

class BoardViewState extends Equatable {
  const BoardViewState({
    required this.board,
    required this.columns,
  });

  final Board board;
  final List<BoardColumn> columns;

  bool get isLoading => board.isLoading;
  Object? get error => board.error;
  bool isSaving(int taskId) => board.savingTaskIds.contains(taskId);

  @override
  List<Object?> get props => [board, columns.length];
}
