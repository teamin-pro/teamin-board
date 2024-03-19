import 'package:flutter/widgets.dart';
import 'package:teamin_board/src/board_models.dart';
import 'package:meta/meta.dart';
import 'package:teamin_board/src/utils.dart';

typedef OnItemMoved = void Function(
  ItemBoardPosition from,
  ItemBoardPosition to,
);
typedef OnColumnMoved = void Function(int from, int to);
typedef OnItemMovedToColumn = void Function(
  ItemBoardPosition from,
  int toColumn,
);

class BoardController {
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

  final dragController = DragController();

  /// Whether an item (card or column) is currently being dragged.
  bool get isDragging => dragController.isDragging;

  void dispose() {
    dragController.dispose();
  }
}

class DragController extends ChangeNotifier {
  BoardPosition? _previousCandidatePosition;
  BoardPosition? get previousCandidatePosition => _previousCandidatePosition;

  // Candidate preview position.
  BoardPosition? _candidatePosition;
  BoardPosition? get candidatePosition => _candidatePosition;
  @internal
  void setCandidatePosition(BoardPosition value) {
    if (_candidatePosition != value) {
      _candidatePosition = value;
      notifyListeners();
    }
  }

  void removeCandidatePosition(BoardPosition value) {
    if (_candidatePosition == value) {
      _previousCandidatePosition = _candidatePosition;
      _candidatePosition = null;
      notifyListeners();
    }
  }

  BoardPosition? _startItemPosition;
  BoardPosition? get startItemPosition => _startItemPosition;
  @internal
  set startItemPosition(BoardPosition? value) {
    if (_startItemPosition != value) {
      _startItemPosition = value;
      notifyListeners();
    }
  }

  int? _hoveredColumnIndex;
  int? get hoveredColumnIndex => _hoveredColumnIndex;
  @internal
  set hoveredColumnIndex(int? value) {
    if (_hoveredColumnIndex != value) {
      _hoveredColumnIndex = value;
      notifyListeners();
    }
  }

  bool get isDragging => startItemPosition != null;

  bool shouldHoverColumn(int columnIndex) {
    return _startItemPosition?.columnIndex != columnIndex &&
        columnIndex == _hoveredColumnIndex;
  }

  void clean() {
    _candidatePosition = null;
    _previousCandidatePosition = null;
    _startItemPosition = null;
    _hoveredColumnIndex = null;
    notifyListeners();
  }
}
