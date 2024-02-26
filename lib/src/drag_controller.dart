import 'package:flutter/foundation.dart';
import 'package:teamin_board/src/board_models.dart';

class DragController extends ChangeNotifier {
  BoardPosition? _previousCandidatePosition;
  BoardPosition? get previousCandidatePosition => _previousCandidatePosition;

  // Candidate preview position.
  BoardPosition? _candidatePosition;
  BoardPosition? get candidatePosition => _candidatePosition;
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
  set startItemPosition(BoardPosition? value) {
    if (_startItemPosition != value) {
      _startItemPosition = value;
      notifyListeners();
    }
  }

  bool get isDragging => startItemPosition != null;

  void clean() {
    _candidatePosition = null;
    _previousCandidatePosition = null;
    _startItemPosition = null;
    notifyListeners();
  }
}
