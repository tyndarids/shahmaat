import 'board.dart';
import 'board_pos.dart';
import 'piece.dart';

/* SERVER MESSAGES */

sealed class ServerMessage {
  ServerMessage();

  factory ServerMessage.fromJson(Map<String, dynamic> json) {
    assert(json.keys.length == 1);

    return switch (json.keys.first) {
      "Start" => Start.fromJson(json["Start"]),
      "ValidMoves" => ValidMoves.fromJson(json["ValidMoves"]),
      "Place" => Place.fromJson(json["Place"]),
      "GameEnd" => GameEnd.fromJson(json["GameEnd"]),
      "Error" => ServerError.fromJson(json["Error"]),

      _ => throw "Unexpected JSON data from server",
    };
  }
}

final class Start extends ServerMessage {
  final BoardState board;

  Start.fromJson(List json) : board = BoardState.fromJson(json);
}

final class ValidMoves extends ServerMessage {
  final List<BoardPos> validMoves;

  ValidMoves.fromJson(List json)
    : validMoves = json.map<BoardPos>((pos) => BoardPos.fromJson(pos)).toList();
}

final class Place extends ServerMessage {
  final BoardPos from;
  final BoardPos to;
  final Piece? takes;

  Place.fromJson(Map<String, dynamic> json)
    : from = BoardPos.fromJson(json["from"]),
      to = BoardPos.fromJson(json["to"]),
      takes = json["takes"] != null ? Piece.fromJson(json["takes"]) : null;
}

final class GameEnd extends ServerMessage {
  final bool didWin;

  GameEnd.fromJson(json) : didWin = json;
}

final class ServerError extends ServerMessage {
  final String error;

  ServerError.fromJson(json) : error = json;
}

/* CLIENT MESSAGES */

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
