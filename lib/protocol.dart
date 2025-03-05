import 'board.dart';
import 'board_pos.dart';

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

  Place.fromJson(List json)
    : from = BoardPos.fromJson(json[0]),
      to = BoardPos.fromJson(json[1]);
}

final class GameEnd extends ServerMessage {
  final bool didWin;

  GameEnd.fromJson(json) : didWin = json;
}

final class ServerError extends ServerMessage {
  final String error;

  ServerError.fromJson(json) : error = json;
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
