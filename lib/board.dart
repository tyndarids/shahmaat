import 'piece.dart';

final class BoardState {
  final List<List<Piece?>> board;

  BoardState.fromJson(List<dynamic> json)
    : board = List.generate(
        8,
        (i) => List.generate(
          8,
          (j) => json[i][j] != null ? Piece.fromJson(json[i][j]) : null,
        ),
      );
}
