import 'package:flutter/widgets.dart';
import 'package:teamin_board/src/drag_controller.dart';
import 'package:teamin_board/src/draggable_item_widget.dart';
import 'package:teamin_board/src/utils.dart';

class ColumnHover extends StatelessWidget {
  const ColumnHover({
    super.key,
    required this.onItemDropped,
    required this.dragController,
    required this.enabled,
    required this.builder,
  });

  final VoidCallback onItemDropped;
  final DragController dragController;
  final bool enabled;
  final Widget Function(bool isHovered) builder;

  @override
  Widget build(BuildContext context) {
    return DragTarget<DragItemVm>(
      onWillAcceptWithDetails: (details) {
        return enabled &&
            details.data.itemBoardPosition.columnIndex !=
                dragController.startItemPosition?.columnIndex;
      },
      onAcceptWithDetails: (_) => onItemDropped(),
      builder: (_, candidateData, __) => builder(candidateData.isNotEmpty),
    );
  }
}
