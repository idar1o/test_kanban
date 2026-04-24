import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/board_interactor.dart';
import 'board_state.dart';

class BoardCubit extends Cubit<BoardViewState> {
  BoardCubit({required BoardInteractor interactor})
      : _interactor = interactor,
        super(BoardViewState(board: interactor.state, columns: interactor.columns)) {
    _sub = _interactor.stream.listen((board) {
      emit(BoardViewState(board: board, columns: _interactor.columns));
    });
  }

  final BoardInteractor _interactor;
  late final StreamSubscription _sub;

  Future<void> refresh() => _interactor.refresh();

  Future<void> moveTask({
    required int taskId,
    required int newParentId,
    required int newOrder,
  }) {
    return _interactor.moveTask(
      taskId: taskId,
      newParentId: newParentId,
      newOrder: newOrder,
    );
  }

  void moveColumn({required int parentId, required int toIndex}) {
    _interactor.moveColumn(parentId: parentId, toIndex: toIndex);
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
