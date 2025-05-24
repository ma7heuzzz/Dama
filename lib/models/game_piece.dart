class Position {
  final int row;
  final int col;

  const Position({required this.row, required this.col});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Position && other.row == row && other.col == col;
  }

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

class GamePiece {
  final Position position;
  final bool isWhite;
  final bool isKing;

  const GamePiece({
    required this.position,
    required this.isWhite,
    this.isKing = false,
  });

  GamePiece copyWith({
    Position? position,
    bool? isWhite,
    bool? isKing,
  }) {
    return GamePiece(
      position: position ?? this.position,
      isWhite: isWhite ?? this.isWhite,
      isKing: isKing ?? this.isKing,
    );
  }
}
