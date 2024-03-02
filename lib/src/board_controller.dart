import 'package:flutter/widgets.dart';
import 'package:teamin_board/src/board_models.dart';
import 'package:meta/meta.dart';

typedef OnItemMoved = void Function(
  ItemBoardPosition from,
  ItemBoardPosition to,
);
typedef OnColumnMoved = void Function(int from, int to);
typedef OnItemMovedToColumn = void Function(
  ItemBoardPosition from,
  int toColumn,
);

class BoardController extends ChangeNotifier {
  BoardController({
    this.onItemMoved,
    this.onColumnMoved,
    this.onItemMovedToColumn,
  });

  /// Called when an item is moved from one position to another.
  ///
  /// Items can be moved from any column position to any other column position when this is provided.
  final OnItemMoved? onItemMoved;
  final OnColumnMoved? onColumnMoved;
  final OnItemMovedToColumn? onItemMovedToColumn;

  var _isDragging = false;

  /// Whether an item (card or column) is currently being dragged.
  bool get isDragging => _isDragging;
  @internal
  set isDragging(bool value) {
    if (_isDragging != value) {
      _isDragging = value;
      notifyListeners();
    }
  }
}
