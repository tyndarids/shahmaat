import 'board.dart';
import 'board_pos.dart';

sealed class ServerMessage {
  ServerMessage();

  factory ServerMessage.fromJson(Map<String, dynamic> json) {
    assert(json.keys.length == 1);

    return switch (json.keys.first) {
      "Start" => Start.fromJson(json),
      "ValidMoves" => ValidMoves.fromJson(json),
      "Place" => Place.fromJson(json),
      "GameEnd" => GameEnd.fromJson(json),
      "Error" => ServerError.fromJson(json),

      _ => throw "Unexpected JSON data from server",
    };
  }
}

final class Start extends ServerMessage {
  final BoardState board;

  Start.fromJson(Map<String, dynamic> json)
    : board = BoardState.fromJson(json["Start"]);
}

final class ValidMoves extends ServerMessage {
  late final List<BoardPos> validMoves;

  ValidMoves.fromJson(Map<String, dynamic> json) {
    validMoves =
        (json["ValidMoves"] as List<dynamic>)
            .map<BoardPos>((pos) => BoardPos.fromJson(pos as List))
            .toList();
  }
}

final class Place extends ServerMessage {
  final BoardPos at;

  Place.fromJson(Map<String, dynamic> json)
    : at = BoardPos.fromJson(json["Place"]);
}

final class GameEnd extends ServerMessage {
  final bool didWin;

  GameEnd.fromJson(Map<String, dynamic> json) : didWin = json["GameEnd"];
}

final class ServerError extends ServerMessage {
  final String error;

  ServerError.fromJson(Map<String, dynamic> json) : error = json["Error"];
}

sealed class ClientMessage {
  Map<String, dynamic> toJson();
}

final class Picked extends ClientMessage {
  final BoardPos pos;
  Picked(this.pos);

  @override
  Map<String, dynamic> toJson() => {"Picked": pos};
}

final class Placed extends ClientMessage {
  final BoardPos pos;
  Placed(this.pos);

  @override
  Map<String, dynamic> toJson() => {"Placed": pos};
}

final class ClientError extends ClientMessage {
  final String error;
  ClientError(this.error);

  @override
  Map<String, dynamic> toJson() => {"Error": error};
}
