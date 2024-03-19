import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:teamin_board/src/utils.dart';

/// [speedFactor] could be in range of 0.0 to 1.0
typedef ScrollInfo = ({AxisDirection direction, double speedFactor});

class BoardScrollController {
  BoardScrollController({
    required TickerProvider vsync,
    required this.horizontalScrollController,
    required this.maxScrollSpeedSelector,
  }) {
    _scrollTicker = vsync.createTicker(_scrollOnTick);
  }

  late Ticker _scrollTicker;
  final ScrollController horizontalScrollController;
  final double Function(Axis axis) maxScrollSpeedSelector;
  ScrollController? _verticalScrollController;
  var _scrollData = <ScrollInfo>{};

  void scrollDataUpdated({
    required Set<ScrollInfo> scrollData,
    required ScrollController? verticalScrollController,
  }) {
    _verticalScrollController = verticalScrollController;
    if (scrollData.isEmpty || setEquals(_scrollData, scrollData)) return;

    _scrollData = scrollData;
    if (!_scrollTicker.isActive) {
      _scrollTicker.start();
    }
  }

  void _removeScrollInfo(ScrollInfo scrollInfo) {
    _scrollData = _scrollData.toSet()..remove(scrollInfo);
    if (_scrollData.isEmpty) {
      stopScroll();
    }
  }

  void stopScroll() {
    _scrollData = {};
    _scrollTicker.stop();
  }

  void _scrollOnTick(Duration _) {
    for (final scrollInfo in _scrollData) {
      final direction = scrollInfo.direction;
      final controller = direction.isHorizontal
          ? horizontalScrollController
          : _verticalScrollController;
      if (controller == null || !controller.hasClients) return;

      final delta = scrollInfo.speedFactor.abs() *
          maxScrollSpeedSelector(axisDirectionToAxis(direction)) *
          (direction.isRightOrDown ? 1 : -1);
      if (delta > 0 && !controller.canScrollForward ||
          delta < 0 && !controller.canScrollBackward) {
        _removeScrollInfo(scrollInfo);
      } else {
        controller.jumpTo(controller.offset + delta);
      }
    }
  }

  void dispose() {
    stopScroll();
    _scrollTicker.dispose();
  }
}
