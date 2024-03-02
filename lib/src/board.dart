import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:teamin_board/src/board_config.dart';
import 'package:teamin_board/src/board_controller.dart';
import 'package:teamin_board/src/board_models.dart';
import 'package:teamin_board/src/board_scroll_listener.dart';
import 'package:teamin_board/src/board_scroll_controller.dart';
import 'package:teamin_board/src/column_hover.dart';
import 'package:teamin_board/src/drag_controller.dart';
import 'package:teamin_board/src/draggable_item_widget.dart';
import 'package:teamin_board/src/utils.dart';

class TeaminBoard extends StatefulWidget {
  const TeaminBoard({
    super.key,
    required this.columns,
    required this.controller,
    this.boardConfig = const BoardConfig(),
    this.boardScrollController,
    this.start,
    this.end,
  });

  final List<BoardColumn> columns;
  final BoardController controller;
  final BoardConfig boardConfig;

  /// Widget to be displayed as the first column.
  final Widget? start;

  /// Widget to be displayed as the last column.
  final Widget? end;
  final ScrollController? boardScrollController;

  @override
  State<TeaminBoard> createState() => _TeaminBoardState();
}

class _TeaminBoardState extends State<TeaminBoard>
    with SingleTickerProviderStateMixin {
  final _dragController = DragController();
  final _defaultBoardHorizontalScrollController = ScrollController();
  final _columnsScrollControllers = <Object, ScrollController>{};
  late final _flutterView = View.of(context);
  late final _boardScrollController = BoardScrollController(
    vsync: this,
    horizontalScrollController: _boardHorizontalScrollController,
    maxScrollSpeedSelector: (axis) {
      return widget.boardConfig.calculateMaxScrollSpeed(context, axis);
    },
    verticalScrollControllerSelector: () {
      final position = _lastPosition;
      if (position != null &&
          // Scroll column only when board item is dragging.
          _dragController.startItemPosition is ItemBoardPosition) {
        return _scrollControllerFromPosition(position);
      }
      return null;
    },
  );

  ScrollController get _boardHorizontalScrollController {
    return widget.boardScrollController ??
        _defaultBoardHorizontalScrollController;
  }

  Offset? _lastPosition;

  void _onDragStarted(BoardPosition position) {
    _dragController.startItemPosition = position;
    widget.controller.isDragging = true;
  }

  void _onItemDropped(BoardPosition newPosition) {
    final oldPosition = _dragController.startItemPosition;
    assert(oldPosition != null);
    switch ((oldPosition, newPosition)) {
      case (ItemBoardPosition oldP, ItemBoardPosition newP):
        widget.controller.onItemMoved?.call(oldP, newP);
      case (ColumnBoardPosition oldP, ColumnBoardPosition newP):
        widget.controller.onColumnMoved
            ?.call(oldP.columnIndex, newP.columnIndex);
      case (ItemBoardPosition oldP, ColumnBoardPosition newP):
        widget.controller.onItemMovedToColumn?.call(oldP, newP.columnIndex);
      default:
        assert(false, 'Unexpected board position');
    }
    _dragController.clean();
    widget.controller.isDragging = false;
  }

  ScrollController? _scrollControllerFromPosition(Offset position) {
    final hitTestResult = HitTestResult();
    WidgetsBinding.instance.hitTestInView(
      hitTestResult,
      position,
      _flutterView.viewId,
    );
    for (final target in hitTestResult.path) {
      if (target.target case RenderMetaData(:final ScrollController metaData)) {
        return metaData;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _defaultBoardHorizontalScrollController.dispose();
    _boardScrollController.dispose();
    for (var controller in _columnsScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.boardConfig;
    final columns = widget.columns;
    final columnsChildren = <Widget>[if (widget.start != null) widget.start!];
    for (var columnIndex = 0; columnIndex < columns.length; columnIndex++) {
      final column = columns[columnIndex];
      final scrollController = column.scrollController ??
          _columnsScrollControllers.putIfAbsent(
            column.key,
            () => ScrollController(debugLabel: column.key.toString()),
          );
      columnsChildren.add(
        DragItem(
          vm: DragItemVm(
            childWhenDraggingBuilder: config.childWhenDraggingBuilder,
            feedbackBuilder: config.feedbackBuilder,
            childPreviewBuilder: config.childPreviewBuilder,
            spacing: config.columnsSpacing,
            dragController: _dragController,
            itemBoardPosition: ColumnBoardPosition(columnIndex: columnIndex),
            dragItemListPosition: _dragItemListPositionFromListIndex(
              columnIndex,
              columns.length,
            ),
            onItemDropped: (side) {
              _onItemDropped(
                ColumnBoardPosition(
                  columnIndex: side == DragItemSide.before
                      ? columnIndex
                      : columnIndex + 1,
                ),
              );
            },
            direction: Axis.horizontal,
            onDragStarted: () {
              _onDragStarted(ColumnBoardPosition(columnIndex: columnIndex));
            },
            columnItem: ColumnItem(
              key: column.key,
              isDraggable:
                  column.isDraggable ?? widget.controller.onColumnMoved != null,
              builder: (_) => MetaData(
                // Provide column scroll controller that can be received from the `WidgetsBinding.hitTestInView`.
                metaData: scrollController,
                child: ColumnHover(
                  enabled: widget.controller.onItemMovedToColumn != null,
                  onItemDropped: () {
                    if (_dragController.startItemPosition?.columnIndex !=
                        columnIndex) {
                      _onItemDropped(
                        ColumnBoardPosition(columnIndex: columnIndex),
                      );
                    }
                  },
                  builder: (isHovered) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: config.maxColumnWidth,
                      ),
                      child: column.columnDecorationBuilder(
                        context,
                        _buildColumnList(columnIndex, scrollController),
                        isHovered &&
                            _dragController.startItemPosition?.columnIndex !=
                                columnIndex,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (widget.end != null) columnsChildren.add(widget.end!);

    return BoardScrollListener(
      onDrag: (scrollData, position) {
        // This callback may be called when user drag scroll bar.
        if (!_dragController.isDragging) return;
        _lastPosition = position;
        _boardScrollController.scrollDataUpdated(scrollData: scrollData);
      },
      onDragEnd: () {
        _lastPosition = null;
        _boardScrollController.stopScroll();
      },
      thresholdCalculator: config.calculateScrollThreshold,
      showDebugOverlay: config.showScrollThresholdDebugOverlay,
      child: config.boardColumnsBuilder.createList(
        controller: _boardHorizontalScrollController,
        itemCount: columnsChildren.length,
        itemBuilder: (_, index) => columnsChildren[index],
      ),
    );
  }

  Widget _buildColumnList(int columnIndex, ScrollController scrollController) {
    final column = widget.columns[columnIndex];
    final config = widget.boardConfig;

    return config.columnListBuilder.createList(
      controller: scrollController,
      itemCount: column.items.length,
      itemBuilder: (context, index) {
        return DragItem(
          vm: DragItemVm(
            childWhenDraggingBuilder: config.childWhenDraggingBuilder,
            feedbackBuilder: config.feedbackBuilder,
            childPreviewBuilder: config.childPreviewBuilder,
            dragItemListPosition: _dragItemListPositionFromListIndex(
              index,
              column.items.length,
            ),
            spacing: config.cardsSpacing,
            dragController: _dragController,
            columnItem: column.items[index],
            direction: Axis.vertical,
            onDragStarted: () {
              _onDragStarted(
                ItemBoardPosition(
                  columnIndex: columnIndex,
                  columnItemIndex: index,
                ),
              );
            },
            itemBoardPosition: ItemBoardPosition(
              columnIndex: columnIndex,
              columnItemIndex: index,
            ),
            onItemDropped: widget.controller.onItemMoved != null
                ? (side) {
                    final columnItemIndex =
                        side == DragItemSide.before ? index : index + 1;
                    _onItemDropped(
                      ItemBoardPosition(
                        columnIndex: columnIndex,
                        columnItemIndex: columnItemIndex,
                      ),
                    );
                  }
                : null,
          ),
        );
      },
    );
  }

  DragItemListPosition _dragItemListPositionFromListIndex(
    int index,
    int listLength,
  ) {
    if (listLength == 1) {
      return DragItemListPosition.single;
    } else if (index == 0) {
      return DragItemListPosition.start;
    } else if (index == listLength - 1) {
      return DragItemListPosition.end;
    }
    return DragItemListPosition.between;
  }
}
