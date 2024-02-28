import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

abstract class ColumnListBuilderDelegate {
  Widget createList({
    required ScrollController controller,
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
  });
}

class ColumnListBuilder implements ColumnListBuilderDelegate {
  const ColumnListBuilder({
    this.shrinkWrap = false,
    this.padding,
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
