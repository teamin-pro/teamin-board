import 'package:flutter/material.dart';
import 'package:teamin_board/src/column_list_builder.dart';
import 'package:teamin_board/src/utils.dart';

class BoardConfig {
  const BoardConfig({
    this.cardsSpacing = 8,
    this.columnsSpacing = 8,
    this.maxColumnWidth = 300,
    this.showScrollThresholdDebugOverlay = false,
    this.columnListBuilder = const ColumnListBuilder(),
    this.boardColumnsBuilder = const BoardColumnsBuilder(),
  });

  double calculateScrollThreshold(BuildContext context, Axis axis) {
    if (Theme.of(context).platform.isMobile) {
      return axis.isHorizontal ? 80 : 100;
    } else {
      final threshold = switch (MediaQuery.sizeOf(context).width) {
        < 900 => 80.0,
        _ => 100.0,
      };
      // Make horizontal threshold a bit larger because it's convenient for lists.
      return axis.isVertical ? threshold : threshold * 1.3;
    }
  }

  final double cardsSpacing;
  final double columnsSpacing;
  final double maxColumnWidth;

  /// Whether to show red border on the board to show the scroll area.
  final bool showScrollThresholdDebugOverlay;

  double calculateMaxScrollSpeed(BuildContext context, Axis axis) {
    if (Theme.of(context).platform.isMobile) {
      return 20;
    } else {
      return switch (MediaQuery.sizeOf(context).width) {
        < 800 => 20,
        _ => 25,
      };
    }
  }

  /// The widget to show under the pointer when a drag is under way.
  Widget feedbackBuilder(BuildContext context, Widget child) => child;

  /// The widget to display instead of [child] when drag is under way.
  Widget childWhenDraggingBuilder(BuildContext context, Widget child) {
    return Opacity(opacity: 0.5, child: child);
  }

  /// The widget to preview [child] in the new position when dragging.
  Widget childPreviewBuilder(BuildContext context, Widget child) {
    return Opacity(opacity: 0.5, child: child);
  }

  /// The builder for the column (cards) list.
  ///
  /// You can provide your own implementation using [CustomScrollView] or anything else.
  final ColumnListBuilderDelegate columnListBuilder;

  /// The builder for the board columns list.
  final ColumnListBuilderDelegate boardColumnsBuilder;
}
