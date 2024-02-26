import 'package:flutter/material.dart';
import 'package:teamin_board/src/board_scroll_controller.dart';
import 'package:teamin_board/src/utils.dart';

typedef ScrollSpeedThresholds = ({
  double slowThreshold,
  double mediumThreshold,
  double fastThreshold
});
typedef ScrollThresholdCalculator = double Function(
  BuildContext context,
  Axis axis,
);

class BoardScrollListener extends StatefulWidget {
  const BoardScrollListener({
    super.key,
    required this.child,
    required this.onDrag,
    required this.onDragEnd,
    required this.thresholdCalculator,
    this.showDebugOverlay = false,
  });

  final Widget child;
  final void Function(Set<ScrollInfo> scrollData, Offset position) onDrag;
  final VoidCallback onDragEnd;
  final ScrollThresholdCalculator thresholdCalculator;
  final bool showDebugOverlay;

  @override
  State<BoardScrollListener> createState() => _BoardScrollListenerState();
}

class _BoardScrollListenerState extends State<BoardScrollListener> {
  Rect? _boardRect;
  double _horizontalScrollThreshold = 0;
  double _verticalScrollThreshold = 0;

  void _onStopDrag() {
    _boardRect = null;
    widget.onDragEnd();
  }

  void _onMove(Offset position) {
    if (_boardRect == null) _calculateRectAndThreshold();
    final boardRect = _boardRect;
    if (boardRect != null) {
      final rightDelta = boardRect.right - position.dx;
      final leftDelta = position.dx - boardRect.left;
      final downDelta = boardRect.bottom - position.dy;
      final upDelta = position.dy - boardRect.top;

      final rightSpeed = _speedFactorFromDelta(rightDelta, Axis.horizontal);
      final leftSpeed = _speedFactorFromDelta(leftDelta, Axis.horizontal);
      final downSpeed = _speedFactorFromDelta(downDelta, Axis.vertical);
      final upSpeed = _speedFactorFromDelta(upDelta, Axis.vertical);
      final scrollData = <ScrollInfo>{};

      if (rightSpeed != null) {
        scrollData
            .add((direction: AxisDirection.right, speedFactor: rightSpeed));
      }
      if (leftSpeed != null) {
        scrollData.add((direction: AxisDirection.left, speedFactor: leftSpeed));
      }
      if (downSpeed != null) {
        scrollData.add((direction: AxisDirection.down, speedFactor: downSpeed));
      }
      if (upSpeed != null) {
        scrollData.add((direction: AxisDirection.up, speedFactor: upSpeed));
      }

      if (scrollData.isNotEmpty) {
        widget.onDrag(scrollData, position);
      } else {
        _onStopDrag();
      }
    }
  }

  double? _speedFactorFromDelta(double delta, Axis axis) {
    final threshold = axis.isHorizontal
        ? _horizontalScrollThreshold
        : _verticalScrollThreshold;
    if (delta > threshold) return null;
    return 1 - delta / threshold;
  }

  Rect? _calculateBoardRect() {
    final renderBox = context.findRenderObject();
    if (renderBox is RenderBox) return getRect(renderBox);
    return null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dragInProgress = _boardRect != null;
    if (dragInProgress || widget.showDebugOverlay) {
      _calculateRectAndThreshold();
    }
  }

  void _calculateRectAndThreshold() {
    _boardRect = _calculateBoardRect();
    _horizontalScrollThreshold = widget.thresholdCalculator(
      context,
      Axis.horizontal,
    );
    _verticalScrollThreshold = widget.thresholdCalculator(
      context,
      Axis.vertical,
    );
  }

  @override
  Widget build(BuildContext context) {
    var child = widget.child;
    if (widget.showDebugOverlay) {
      child = Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(
                      color: Colors.red.withOpacity(0.4),
                      width: _horizontalScrollThreshold,
                    ),
                    horizontal: BorderSide(
                      color: Colors.red.withOpacity(0.4),
                      width: _verticalScrollThreshold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Listener(
      onPointerMove: (event) => _onMove(event.position),
      onPointerUp: (_) => _onStopDrag(),
      onPointerCancel: (_) => _onStopDrag(),
      child: child,
    );
  }
}
