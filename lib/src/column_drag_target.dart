import 'package:flutter/widgets.dart';
import 'package:teamin_board/src/draggable_item_widget.dart';

class ColumnDragTarget extends StatelessWidget {
  const ColumnDragTarget({
    super.key,
    required this.onItemDropped,
    required this.enabled,
    required this.builder,
  });

  final ValueChanged<DragItemVm> onItemDropped;
  final bool enabled;
  final Widget Function(DragItemVm? candidateVm) builder;

  @override
  Widget build(BuildContext context) {
    return DragTarget<DragItemVm>(
      onWillAcceptWithDetails: (_) => enabled,
      onAcceptWithDetails: (details) => onItemDropped(details.data),
      builder: (_, candidateData, __) => builder(candidateData.firstOrNull),
    );
  }
}
