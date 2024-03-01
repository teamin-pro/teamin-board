import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

abstract class ColumnListBuilderDelegate {
  const ColumnListBuilderDelegate();

  Widget createList({
    required ScrollController controller,
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
  });
}

class ColumnListBuilder implements ColumnListBuilderDelegate {
  const ColumnListBuilder({
    this.shrinkWrap = false,
    this.padding = EdgeInsets.zero,
    this.physics,
  });

  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  @override
  Widget createList({
    required ScrollController controller,
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
  }) {
    return ListView.builder(
      itemBuilder: itemBuilder,
      itemCount: itemCount,
      controller: controller,
      shrinkWrap: shrinkWrap,
      padding: padding,
      physics: physics,
    );
  }
}

class BoardColumnsBuilder extends ColumnListBuilderDelegate {
  const BoardColumnsBuilder({
    this.scrollDirection = Axis.horizontal,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.physics,
    this.padding,
  });

  final Axis scrollDirection;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget createList({
    required ScrollController controller,
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
  }) {
    // Use single child scroll view instead of ListView.builder
    // to preserve a scroll position in columns when they are not visible.
    return SingleChildScrollView(
      controller: controller,
      scrollDirection: scrollDirection,
      physics: physics,
      padding: padding,
      child: Builder(builder: (context) {
        return Row(
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: [
            for (var i = 0; i < itemCount; i++) itemBuilder(context, i),
          ],
        );
      }),
    );
  }
}
