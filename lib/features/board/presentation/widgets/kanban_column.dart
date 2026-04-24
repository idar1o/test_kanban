import 'package:flutter/material.dart';

import '../../../../app/app.dart';
import '../../domain/board_interactor.dart';
import '../../domain/kanban_task.dart';
import '../bloc/board_state.dart';
import 'drag_auto_scroll.dart';
import 'drag_payload.dart';
import 'kanban_card.dart';

typedef OnTaskDrop = void Function({
  required KanbanTask task,
  required int newParentId,
  required int newOrder,
});

class KanbanColumn extends StatefulWidget {
  const KanbanColumn({
    super.key,
    required this.column,
    required this.viewState,
    required this.onDrop,
  });

  final BoardColumn column;
  final BoardViewState viewState;
  final OnTaskDrop onDrop;

  @override
  State<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<KanbanColumn> {
  bool _isBeingDragged = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleDrop(TaskDragPayload payload, int targetIndex) {
    if (widget.viewState.isSaving(payload.task.indicatorToMoId)) return;

    var newOrder = targetIndex;
    if (payload.task.parentId == widget.column.parentId) {
      final currentIndex = widget.column.tasks.indexWhere(
        (t) => t.indicatorToMoId == payload.task.indicatorToMoId,
      );
      if (currentIndex != -1 && targetIndex > currentIndex) {
        newOrder = targetIndex - 1;
      }
    }

    widget.onDrop(
      task: payload.task,
      newParentId: widget.column.parentId,
      newOrder: newOrder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final column = widget.column;
    final body = Container(
      width: 290,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.columnBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _DraggableHeader(
            column: column,
            onDragStateChanged: (v) {
              if (mounted && _isBeingDragged != v) {
                setState(() => _isBeingDragged = v);
              }
            },
          ),
          Flexible(
            child: DragTarget<TaskDragPayload>(
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: (details) {
                _handleDrop(details.data, column.tasks.length);
              },
              builder: (context, candidate, rejected) {
                return DragAutoScrollRegion(
                  controller: _scrollController,
                  axis: Axis.vertical,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < column.tasks.length; i++)
                          _CardSlot(
                            key: ValueKey(column.tasks[i].indicatorToMoId),
                            task: column.tasks[i],
                            index: i,
                            isSaving: widget.viewState.isSaving(
                              column.tasks[i].indicatorToMoId,
                            ),
                            onDrop: _handleDrop,
                          ),
                        if (column.tasks.isEmpty)
                          const SizedBox(
                            height: 40,
                            child: Center(
                              child: Text(
                                'Перетащите сюда',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: _isBeingDragged ? 0.3 : 1.0,
      child: body,
    );
  }
}

class ColumnPreview extends StatelessWidget {
  const ColumnPreview({super.key, required this.column});

  final BoardColumn column;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 290,
        constraints: const BoxConstraints(maxHeight: 520),
        decoration: BoxDecoration(
          color: AppColors.columnBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accentPurple, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x557C3AED),
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Color(0x80000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeaderContent(column: column),
            if (column.tasks.isNotEmpty)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final t in column.tasks)
                        KanbanCard(task: t),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderContent extends StatelessWidget {
  const _HeaderContent({required this.column});

  final BoardColumn column;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 6),
      child: Row(
        children: [
          const Icon(
            Icons.drag_indicator,
            size: 16,
            color: AppColors.accentPurple,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              column.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${column.tasks.length}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.badgeText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraggableHeader extends StatelessWidget {
  const _DraggableHeader({
    required this.column,
    required this.onDragStateChanged,
  });

  final BoardColumn column;
  final void Function(bool isDragging) onDragStateChanged;

  @override
  Widget build(BuildContext context) {
    final header = _HeaderContent(column: column);

    return Draggable<ColumnDragPayload>(
      data: ColumnDragPayload(parentId: column.parentId),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () => onDragStateChanged(true),
      onDragEnd: (_) => onDragStateChanged(false),
      onDraggableCanceled: (_, _) => onDragStateChanged(false),
      onDragCompleted: () => onDragStateChanged(false),
      feedback: ColumnPreview(column: column),
      childWhenDragging: header,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: header,
      ),
    );
  }
}

class _CardSlot extends StatefulWidget {
  const _CardSlot({
    super.key,
    required this.task,
    required this.index,
    required this.isSaving,
    required this.onDrop,
  });

  final KanbanTask task;
  final int index;
  final bool isSaving;
  final void Function(TaskDragPayload payload, int targetIndex) onDrop;

  @override
  State<_CardSlot> createState() => _CardSlotState();
}

class _CardSlotState extends State<_CardSlot> {
  bool? _hoverAbove;

  bool _isSameTask(TaskDragPayload p) =>
      p.task.indicatorToMoId == widget.task.indicatorToMoId;

  @override
  Widget build(BuildContext context) {
    return DragTarget<TaskDragPayload>(
      onWillAcceptWithDetails: (_) => true,
      onMove: (details) {
        if (_isSameTask(details.data)) {
          if (_hoverAbove != null) setState(() => _hoverAbove = null);
          return;
        }
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        final local = box.globalToLocal(details.offset);
        final above = local.dy < box.size.height / 2;
        if (_hoverAbove != above) {
          setState(() => _hoverAbove = above);
        }
      },
      onLeave: (_) {
        if (_hoverAbove != null) setState(() => _hoverAbove = null);
      },
      onAcceptWithDetails: (details) {
        final above = _hoverAbove;
        setState(() => _hoverAbove = null);
        if (_isSameTask(details.data) || above == null) return;
        widget.onDrop(details.data, above ? widget.index : widget.index + 1);
      },
      builder: (context, candidate, rejected) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InsertionBar(active: _hoverAbove == true),
            _DraggableCard(task: widget.task, isSaving: widget.isSaving),
            _InsertionBar(active: _hoverAbove == false),
          ],
        );
      },
    );
  }
}

class _DraggableCard extends StatelessWidget {
  const _DraggableCard({required this.task, required this.isSaving});

  final KanbanTask task;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final card = KanbanCard(task: task, isSaving: isSaving);
    if (isSaving) return card;

    return Draggable<TaskDragPayload>(
      data: TaskDragPayload(task: task),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 270,
          child: Transform.rotate(
            angle: 0.02,
            child: KanbanCard(task: task, isDragging: true),
          ),
        ),
      ),
      childWhenDragging: KanbanCard(task: task, isGhost: true),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: card,
      ),
    );
  }
}

class _InsertionBar extends StatelessWidget {
  const _InsertionBar({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      height: active ? 40 : 0,
      margin: EdgeInsets.symmetric(vertical: active ? 4 : 0),
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
                  blurRadius: 12,
                  offset: Offset(0, 0),
                ),
              ]
            : null,
      ),
    );
  }
}
