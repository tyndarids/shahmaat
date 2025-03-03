final class BoardPos {
  final int x;
  final int y;

  BoardPos(this.x, this.y);

  BoardPos.fromJson(List<dynamic> json)
    : x = json[0].codeUnitAt(0) - "A".codeUnitAt(0),
      y = int.parse(json[1][1]) - 1;

  List<dynamic> toJson() => [
    String.fromCharCode("A".codeUnitAt(0) + x),
    "_${y + 1}",
  ];

  @override
  bool operator ==(other) => other is BoardPos && x == other.x && y == other.y;

  @override
  int get hashCode => (x, y).hashCode;

  @override
  String toString() => "BoardPos($x, $y)";
}
