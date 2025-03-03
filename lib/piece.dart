final class Piece {
  final Player player;
  final PieceType type;

  String get assetName => "assets/${player.name}_${type.name}.png";

  Piece.fromJson(List<dynamic> json)
    : player = Player.fromJson(json[0]),
      type = PieceType.fromJson(json[1]);
}

enum Player {
  white,
  black;

  factory Player.fromJson(String json) {
    for (final variant in values) {
      if (json.toLowerCase() == variant.name) {
        return variant;
      }
    }
    throw "Unknown variant";
  }
}

enum PieceType {
  king,
  queen,
  rook,
  bishop,
  knight,
  pawn;

  factory PieceType.fromJson(String json) {
    for (final variant in values) {
      if (json.toLowerCase() == variant.name) {
        return variant;
      }
    }
    throw "Unknown variant";
  }
}
