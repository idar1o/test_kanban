import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/app.dart';
import '../bloc/board_cubit.dart';
import '../bloc/board_state.dart';
import 'drag_auto_scroll.dart';
import 'drag_payload.dart';
import 'kanban_column.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Канбан-доска'),
        actions: [
          BlocBuilder<BoardCubit, BoardViewState>(
            buildWhen: (p, c) => p.isLoading != c.isLoading,
            builder: (context, state) => IconButton(
              icon: state.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
              onPressed: state.isLoading
                  ? null
                  : () => context.read<BoardCubit>().refresh(),
              tooltip: 'Обновить',
            ),
          ),
        ],
      ),
      body: BlocConsumer<BoardCubit, BoardViewState>(
        listenWhen: (prev, curr) =>
            prev.error != curr.error && curr.error != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                backgroundColor: AppColors.accentRed,
                content: Text(
                  'Не удалось сохранить: ${_friendlyError(state.error)}',
                  style: const TextStyle(color: Colors.white),
                ),
                action: SnackBarAction(
                  label: 'Повторить',
                  textColor: Colors.white,
                  onPressed: () => context.read<BoardCubit>().refresh(),
                ),
              ),
            );
        },
        builder: (context, state) {
          if (state.isLoading && state.columns.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.accentPurple),
              ),
            );
          }
          if (state.error != null && state.columns.isEmpty) {
            return _ErrorView(
              error: state.error!,
              onRetry: () => context.read<BoardCubit>().refresh(),
            );
          }
          if (state.columns.isEmpty) {
            return const Center(
              child: Text(
                'Нет задач',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          final cubit = context.read<BoardCubit>();
          final parentIdsInOrder =
              state.columns.map((c) => c.parentId).toList(growable: false);
          return DragAutoScrollRegion(
            controller: _horizontalController,
            axis: Axis.horizontal,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: IntrinsicHeight(
                child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < state.columns.length; i++)
                    _ColumnSlot(
                      key: ValueKey(state.columns[i].parentId),
                      index: i,
                      parentId: state.columns[i].parentId,
                      parentIdsInOrder: parentIdsInOrder,
                      onReorder: (draggedParentId, insertIndex) =>
                          cubit.moveColumn(
                        parentId: draggedParentId,
                        toIndex: insertIndex,
                      ),
                      child: KanbanColumn(
                        column: state.columns[i],
                        viewState: state,
                        onDrop: ({
                          required task,
                          required newParentId,
                          required newOrder,
                        }) {
                          cubit.moveTask(
                            taskId: task.indicatorToMoId,
                            newParentId: newParentId,
                            newOrder: newOrder,
                          );
                        },
                      ),
                    ),
                ],
              ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _friendlyError(Object? e) {
    if (e == null) return '';
    final s = e.toString();
    return s.length > 140 ? '${s.substring(0, 140)}…' : s;
  }
}

class _ColumnSlot extends StatefulWidget {
  const _ColumnSlot({
    super.key,
    required this.index,
    required this.parentId,
    required this.parentIdsInOrder,
    required this.child,
    required this.onReorder,
  });

  final int index;
  final int parentId;
  final List<int> parentIdsInOrder;
  final Widget child;
  final void Function(int draggedParentId, int insertIndex) onReorder;

  @override
  State<_ColumnSlot> createState() => _ColumnSlotState();
}

class _ColumnSlotState extends State<_ColumnSlot> {
  bool? _hoverLeft;

  bool _isSame(ColumnDragPayload p) => p.parentId == widget.parentId;

  bool _isNoop(ColumnDragPayload p, bool left) {
    final fromIndex = widget.parentIdsInOrder.indexOf(p.parentId);
    if (fromIndex == -1) return false;
    final targetIndex = widget.index;
    return (left && fromIndex == targetIndex - 1) ||
        (!left && fromIndex == targetIndex + 1);
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<ColumnDragPayload>(
      onWillAcceptWithDetails: (d) => !_isSame(d.data),
      onMove: (d) {
        if (_isSame(d.data)) return;
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        final local = box.globalToLocal(d.offset);
        final left = local.dx < box.size.width / 2;
        final desired = _isNoop(d.data, left) ? null : left;
        if (_hoverLeft != desired) {
          setState(() => _hoverLeft = desired);
        }
      },
      onLeave: (_) {
        if (_hoverLeft != null) setState(() => _hoverLeft = null);
      },
      onAcceptWithDetails: (d) {
        final left = _hoverLeft;
        setState(() => _hoverLeft = null);
        if (left == null) return;
        widget.onReorder(
          d.data.parentId,
          left ? widget.index : widget.index + 1,
        );
      },
      builder: (context, candidate, rejected) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ColumnInsertBar(active: _hoverLeft == true),
            widget.child,
            _ColumnInsertBar(active: _hoverLeft == false),
          ],
        );
      },
    );
  }
}

class _ColumnInsertBar extends StatelessWidget {
  const _ColumnInsertBar({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      width: active ? 60 : 0,
      margin: EdgeInsets.symmetric(
        horizontal: active ? 6 : 0,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: active ? AppColors.indicatorFill : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: active
            ? Border.all(color: AppColors.indicatorBorder, width: 2)
            : null,
        boxShadow: active
            ? const [
                BoxShadow(
                  color: Color(0x66E53935),
                  blurRadius: 14,
                  offset: Offset(0, 0),
                ),
              ]
            : null,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Не удалось загрузить доску',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentPurple,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
