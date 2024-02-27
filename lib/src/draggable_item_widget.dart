import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:teamin_board/src/drag_controller.dart';
import 'package:teamin_board/src/utils.dart';
import 'package:teamin_board/teamin_board.dart';

typedef DragChildBuilder = Widget Function(BuildContext context, Widget child);

class DragItemVm {
  DragItemVm({
    required this.columnItem,
    required this.direction,
    required this.onDragStarted,
    required this.dragController,
    required this.onItemDropped,
    required this.itemBoardPosition,
    required this.dragItemListPosition,
    required this.feedbackBuilder,
    required this.childWhenDraggingBuilder,
    required this.childPreviewBuilder,
    required this.spacing,
  });

  final Axis direction;
  final VoidCallback onDragStarted;
  final ColumnItem columnItem;
  final DragController dragController;
  final BoardPosition itemBoardPosition;
  final DragItemListPosition dragItemListPosition;
  final ValueChanged<DragItemSide>? onItemDropped;
  final DragChildBuilder feedbackBuilder;
  final DragChildBuilder childWhenDraggingBuilder;
  final DragChildBuilder childPreviewBuilder;
  final double spacing;

  Size? _dratStartedSize;
  Offset get itemLocalCenter =>
      _dratStartedSize?.center(Offset.zero) ?? Offset.zero;
}

class DragItem extends StatefulWidget {
  const DragItem({
    super.key,
    required this.vm,
  });

  final DragItemVm vm;

  @override
  State<DragItem> createState() => _DragItemState();
}

class _DragItemState<T> extends State<DragItem> {
  DragItemSide? _dragItemSide;
  // Used to determine the direction of the drag.
  Offset? _lastOffset;

  double _pickOffsetCoordinate(Offset offset) {
    return widget.vm.direction == Axis.vertical ? offset.dy : offset.dx;
  }

  DragItemSide? _dragItemSideFromCenter(BuildContext? context, Offset offset) {
    final renderBox = context?.findRenderObject();
    if (renderBox is RenderBox) {
      final itemCenter = getRect(renderBox).center;
      return _pickOffsetCoordinate(itemCenter) > _pickOffsetCoordinate(offset)
          ? DragItemSide.before
          : DragItemSide.after;
    }
    return null;
  }

  DragItemSide? _dragItemSideFromScroll(Offset offset) {
    final lastOffset = _lastOffset;
    if (lastOffset != null) {
      const moveThresholdToChangeSide = 10.0;
      final lastPosition = _pickOffsetCoordinate(lastOffset);
      final position = _pickOffsetCoordinate(offset);
      final thresholdReached =
          (lastPosition - position).abs() > moveThresholdToChangeSide;
      return thresholdReached
          ? (lastPosition > position ? DragItemSide.before : DragItemSide.after)
          : null;
    }
    return null;
  }

  bool _canAcceptDragSide(DragItemSide? side) {
    final currentPosition = widget.vm.itemBoardPosition;
    final dragItemPosition = widget.vm.dragController.startItemPosition;
    final sameColumn =
        currentPosition.inSameColumnWith(dragItemPosition) == true;
    final positionToStartItem = currentPosition.getPositionTo(dragItemPosition);
    if (sameColumn && side != null) {
      if (side.isAfter && positionToStartItem?.isAfter == true ||
          side.isBefore && positionToStartItem?.isBefore == true) {
        return false;
      }
    }
    return true;
  }

  void _setDragItemSide(DragItemSide? side) {
    _dragItemSide = side;
    final controller = widget.vm.dragController;
    if (side != null) {
      controller.setCandidatePosition(widget.vm.itemBoardPosition);
    } else {
      controller.removeCandidatePosition(widget.vm.itemBoardPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final onItemDropped = vm.onItemDropped;
    if (onItemDropped == null) return _Draggable(vm: vm);

    return DragTarget<DragItemVm>(
      onWillAcceptWithDetails: (details) {
        final dragToItself = details.data.columnItem.key == vm.columnItem.key;
        final dragToDifferentAxis = details.data.direction != vm.direction;
        if (dragToItself || dragToDifferentAxis) return false;

        final offset = details.offset + details.data.itemLocalCenter;
        final dragItemSideFromCenter = _dragItemSideFromCenter(context, offset);
        final canAcceptFromCenter = _canAcceptDragSide(dragItemSideFromCenter);
        final dragItemSideFromScroll = _dragItemSideFromScroll(offset);
        final canAcceptFromScroll = _canAcceptDragSide(dragItemSideFromScroll);

        _lastOffset ??= offset;
        if (canAcceptFromCenter) {
          _setDragItemSide(dragItemSideFromCenter);
          return true;
        } else if (canAcceptFromScroll) {
          _setDragItemSide(dragItemSideFromScroll);
          return true;
        } else {
          return false;
        }
      },
      onMove: (details) {
        final offset = details.offset + details.data.itemLocalCenter;
        final dragItemFromScroll = _dragItemSideFromScroll(offset);
        if (!_canAcceptDragSide(dragItemFromScroll)) {
          _lastOffset = offset;
          if (_dragItemSide != null) {
            _setDragItemSide(null);
            setState(() {});
          }
        } else if (dragItemFromScroll != null) {
          if (_dragItemSide != dragItemFromScroll) {
            _setDragItemSide(dragItemFromScroll);
          }
          _lastOffset = offset;
          setState(() {});
        }
      },
      onLeave: (_) {
        _setDragItemSide(null);
        _lastOffset = null;
      },
      onAcceptWithDetails: (_) {
        final side = _dragItemSide;
        if (side != null) onItemDropped(side);
      },
      builder: (context, candidateData, rejectedData) {
        final candidate = candidateData.firstOrNull;
        final candidatePreview = candidate != null
            ? vm.childPreviewBuilder(
                context, candidate.columnItem.builder(context))
            : null;
        final showPreviewBefore =
            candidatePreview != null && _dragItemSide == DragItemSide.before;
        final showPreviewAfter =
            candidatePreview != null && _dragItemSide == DragItemSide.after;

        return Flex(
          direction: vm.direction,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showPreviewBefore)
              Padding(
                // Add correct spacing between the candidate and the current item.
                padding: switch (vm.dragItemListPosition) {
                  DragItemListPosition.between ||
                  DragItemListPosition.end =>
                    EdgeInsets.symmetric(vertical: vm.spacing / 2),
                  DragItemListPosition.single ||
                  DragItemListPosition.start =>
                    EdgeInsets.only(bottom: vm.spacing),
                }
                    .transposeWhenHorizontal(vm.direction),
                child: candidatePreview,
              ),
            Flexible(
              child: _Draggable(vm: vm),
            ),
            if (showPreviewAfter)
              Padding(
                // Add correct spacing between the candidate and the current item.
                padding: switch (vm.dragItemListPosition) {
                  DragItemListPosition.between ||
                  DragItemListPosition.start =>
                    EdgeInsets.symmetric(vertical: vm.spacing / 2),
                  DragItemListPosition.single ||
                  DragItemListPosition.end =>
                    EdgeInsets.only(top: vm.spacing),
                }
                    .transposeWhenHorizontal(vm.direction),
                child: candidatePreview,
              ),
          ],
        );
      },
    );
  }
}

class _Draggable extends StatefulWidget {
  const _Draggable({required this.vm});

  final DragItemVm vm;

  @override
  State<_Draggable> createState() => _DraggableState();
}

class _DraggableState<T> extends State<_Draggable> {
  @override
  void initState() {
    widget.vm._dratStartedSize = null;
    super.initState();
  }

  @override
  void dispose() {
    widget.vm._dratStartedSize = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final placeholder = SizedBox(
      width: vm.direction.isVertical ? double.infinity : null,
      height: vm.direction.isHorizontal ? double.infinity : null,
    );

    final childWithPadding = Padding(
      padding: vm.dragItemListPosition
          .padding(vm.spacing)
          .transposeWhenHorizontal(vm.direction),
      child: vm.columnItem.builder(context),
    );

    if (!vm.columnItem.isDraggable) return childWithPadding;

    return _PressDraggable<DragItemVm>(
      data: vm,
      maxSimultaneousDrags: 1,
      feedback: Builder(builder: (context) {
        return SizedBox.fromSize(
          size: vm._dratStartedSize,
          child: vm.feedbackBuilder(context, childWithPadding),
        );
      }),
      onDragStarted: () {
        vm._dratStartedSize = context.size;
        vm.onDragStarted();
      },
      childWhenDragging: ListenableBuilder(
        listenable: vm.dragController,
        builder: (context, _) {
          // Show the original child when dragging not in the same column.
          if (!_candidateAndDraggableAreInSameColumn() ||
              vm.dragController.candidatePosition == null) {
            return vm.childWhenDraggingBuilder(context, childWithPadding);
          }
          return placeholder;
        },
      ),
      child: childWithPadding,
    );
  }

  bool _candidateAndDraggableAreInSameColumn() {
    return switch ((
      widget.vm.dragController.candidatePosition,
      widget.vm.itemBoardPosition
    )) {
      (ColumnBoardPosition _, ColumnBoardPosition _) => true,
      (ItemBoardPosition sp, ItemBoardPosition cp) =>
        sp.columnIndex == cp.columnIndex,
      _ => false,
    };
  }
}

class _PressDraggable<T extends Object> extends Draggable<T> {
  const _PressDraggable({
    super.key,
    required super.child,
    required super.feedback,
    super.data,
    super.axis,
    super.childWhenDragging,
    super.feedbackOffset,
    super.ignoringFeedbackSemantics,
    super.maxSimultaneousDrags,
    super.onDragCompleted,
    super.onDragEnd,
    super.onDraggableCanceled,
    super.onDragStarted,
    super.onDragUpdate,
    super.allowedButtonsFilter,
    this.delay = kLongPressTimeout,
    super.dragAnchorStrategy,
    this.hapticFeedbackOnStart = true,
    super.ignoringFeedbackPointer,
    this.triggerMode,
    super.affinity,
    super.hitTestBehavior,
    super.rootOverlay,
  });

  final DragTriggerMode? triggerMode;

  /// Whether haptic feedback should be triggered on drag start.
  final bool hapticFeedbackOnStart;

  /// The duration that a user has to press down before a long press is registered.
  ///
  /// Defaults to [kLongPressTimeout].
  final Duration delay;

  @override
  MultiDragGestureRecognizer createRecognizer(
      GestureMultiDragStartCallback onStart) {
    final triggerMode = this.triggerMode ??
        (defaultTargetPlatform.isMobile
            ? DragTriggerMode.longPress
            : DragTriggerMode.press);
    return switch (triggerMode) {
      DragTriggerMode.press => super.createRecognizer(onStart),
      DragTriggerMode.longPress =>
        // Copied form the [LongPressDraggable.createRecognizer].
        DelayedMultiDragGestureRecognizer(
            delay: delay, allowedButtonsFilter: allowedButtonsFilter)
          ..onStart = (Offset position) {
            final Drag? result = onStart(position);
            if (result != null && hapticFeedbackOnStart) {
              HapticFeedback.selectionClick();
            }
            return result;
          },
    };
  }
}

enum DragItemSide {
  before,
  after;

  bool get isBefore => this == DragItemSide.before;
  bool get isAfter => this == DragItemSide.after;
}

enum DragItemListPosition {
  start,
  end,
  single,
  between;

  EdgeInsets padding(double space) {
    return switch (this) {
      start => EdgeInsets.only(bottom: space / 2),
      end => EdgeInsets.only(top: space / 2),
      single => EdgeInsets.zero,
      between => EdgeInsets.symmetric(vertical: space / 2),
    };
  }
}
