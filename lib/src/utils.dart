import 'package:flutter/widgets.dart';
import 'package:teamin_board/teamin_board.dart';

Rect getRect(RenderBox renderBox) {
  final paintBounds = renderBox.paintBounds;
  final topLeft = renderBox.localToGlobal(paintBounds.topLeft);
  final bottomRight = renderBox.localToGlobal(paintBounds.bottomRight);
  return Rect.fromPoints(topLeft, bottomRight);
}

extension ScrollControllerX on ScrollController {
  bool get canScroll => positions.length == 1;

  bool get canScrollForward {
    return canScroll && position.maxScrollExtent > position.pixels;
  }

  bool get canScrollBackward {
    return canScroll && position.pixels > position.minScrollExtent;
  }
}

extension PlatformX on TargetPlatform {
  bool get isAndroid => this == TargetPlatform.android;
  bool get isIOS => this == TargetPlatform.iOS;

  bool get isMobile => isAndroid || isIOS;
}

extension AxisX on Axis {
  bool get isVertical => this == Axis.vertical;
  bool get isHorizontal => this == Axis.horizontal;
}

extension AxisDirectionX on AxisDirection {
  bool get isLeft => this == AxisDirection.left;
  bool get isRight => this == AxisDirection.right;
  bool get isUp => this == AxisDirection.up;
  bool get isDown => this == AxisDirection.down;
  bool get isRightOrDown => isRight || isDown;
  bool get isLeftOrUp => isLeft || isUp;

  bool get isHorizontal => isLeft || isRight;
  bool get isVertical => isUp || isDown;

  VerticalDirection toVerticalDirection() {
    return switch (this) {
      AxisDirection.up || AxisDirection.left => VerticalDirection.up,
      AxisDirection.down || AxisDirection.right => VerticalDirection.down,
    };
  }
}

extension VerticalDirectionX on VerticalDirection {
  bool get isUp => this == VerticalDirection.up;
  bool get isDown => this == VerticalDirection.down;
}

extension EdgeInsetsX on EdgeInsets {
  EdgeInsets transpose() {
    return EdgeInsets.fromLTRB(top, left, bottom, right);
  }

  EdgeInsets transposeWhenHorizontal(Axis axis) {
    return axis.isHorizontal ? transpose() : this;
  }
}

extension BoardPositionX on BoardPosition {
  bool? inSameColumnWith(BoardPosition? other) {
    return switch ((this, other)) {
      (ColumnBoardPosition _, ColumnBoardPosition _) => true,
      (ItemBoardPosition t, ItemBoardPosition o) =>
        t.columnIndex == o.columnIndex,
      _ => null,
    };
  }

  ({bool isBefore, bool isAfter})? getPositionTo(BoardPosition? other) {
    return switch ((this, other)) {
      (ItemBoardPosition t, ItemBoardPosition o) => (
          isBefore: t.columnIndex == o.columnIndex + 1,
          isAfter: t.columnIndex == o.columnIndex - 1,
        ),
      (ColumnBoardPosition t, ColumnBoardPosition o) => (
          isBefore: t.columnIndex == o.columnIndex + 1,
          isAfter: t.columnIndex == o.columnIndex - 1,
        ),
      _ => null,
    };
  }

  bool get isItemBoardPosition => this is ItemBoardPosition;
  int get columnIndex => switch (this) {
        ColumnBoardPosition t => t.columnIndex,
        ItemBoardPosition t => t.columnIndex,
      };
}
