import 'package:flutter/material.dart';

import '../../../../app/app.dart';
import '../../domain/kanban_task.dart';

class KanbanCard extends StatelessWidget {
  const KanbanCard({
    super.key,
    required this.task,
    this.isSaving = false,
    this.isGhost = false,
    this.isDragging = false,
  });

  final KanbanTask task;
  final bool isSaving;
  final bool isGhost;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final bg = isDragging ? AppColors.dragRed : AppColors.cardBg;
    final border = isDragging ? AppColors.dragRedBorder : AppColors.cardBorder;
    final textColor = isDragging ? Colors.white : AppColors.textPrimary;

    return Opacity(
      opacity: isGhost ? 0.25 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: isDragging ? 1.5 : 1),
          boxShadow: isDragging
              ? const [
                  BoxShadow(
                    color: Color(0x66E53935),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                task.name,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  height: 1.3,
                  fontWeight: isDragging ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSaving)
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 2),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.accentPurple),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
