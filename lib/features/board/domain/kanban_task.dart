import 'package:equatable/equatable.dart';

class KanbanTask extends Equatable {
  const KanbanTask({
    required this.indicatorToMoId,
    required this.parentId,
    required this.name,
    required this.order,
  });

  final int indicatorToMoId;
  final int parentId;
  final String name;
  final int order;

  KanbanTask copyWith({int? parentId, int? order, String? name}) {
    return KanbanTask(
      indicatorToMoId: indicatorToMoId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      order: order ?? this.order,
    );
  }

  @override
  List<Object?> get props => [indicatorToMoId, parentId, name, order];
}
