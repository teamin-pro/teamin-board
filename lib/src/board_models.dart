import 'package:flutter/widgets.dart';
import 'package:teamin_board/teamin_board.dart';

sealed class BoardPosition {
  const BoardPosition();
}

class ColumnBoardPosition extends BoardPosition {
  const ColumnBoardPosition({required this.columnIndex});

  final int columnIndex;

  @override
  String toString() => 'BoardPosition(columnIndex: $columnIndex)';

  @override
  operator ==(Object other) =>
      other is ColumnBoardPosition && other.columnIndex == columnIndex;

  @override
  int get hashCode => columnIndex.hashCode;
}

class ItemBoardPosition extends BoardPosition {
  const ItemBoardPosition({
    required this.columnIndex,
    required this.columnItemIndex,
  });

  final int columnIndex;
  final int columnItemIndex;

  @override
  String toString() =>
      'ItemBoardPosition(columnIndex: $columnIndex, columnItemIndex: $columnItemIndex)';

  @override
  operator ==(Object other) =>
      other is ItemBoardPosition &&
      other.columnIndex == columnIndex &&
      other.columnItemIndex == columnItemIndex;

  @override
  int get hashCode => Object.hash(columnIndex, columnItemIndex);
}

/// The builder to decorate the column.
///
/// The [column] is the column widget.
typedef ColumnDecorationBuilder = Widget Function(
  BuildContext context,
  Widget column,
);

class BoardColumn {
  BoardColumn({
    required this.key,
    required this.items,
    required this.columnDecorationBuilder,
    this.isDraggable,
    this.scrollController,
  });

  final Object key;
  final List<ColumnItem> items;
  final ScrollController? scrollController;

  /// By default, the column is draggable when the [TeaminBoard.onColumnMoved] is provided.
  final bool? isDraggable;

  /// The builder to decorate the column.
  final ColumnDecorationBuilder columnDecorationBuilder;
  
  BoardColumn copyWith({
    List<ColumnItem>? items,
  }) {
    return BoardColumn(
      key: key,
      items: items ?? this.items,
      columnDecorationBuilder: columnDecorationBuilder,
      isDraggable: isDraggable,
      scrollController: scrollController,
    );
  }
}

class ColumnItem {
  const ColumnItem({
    required this.key,
    required this.builder,
    this.isDraggable = true,
    this.dragTriggerMode,
  });

  final Object key;
  final WidgetBuilder builder;
  final bool isDraggable;

  /// The mode to trigger the drag.
  ///
  /// Defaults to [DragTriggerMode.press] on desktop and [DragTriggerMode.longPress] on mobile.
  final DragTriggerMode? dragTriggerMode;
}

enum DragTriggerMode { press, longPress }
