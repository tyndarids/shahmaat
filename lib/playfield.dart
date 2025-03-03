import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'piece.dart';
import 'protocol.dart';
import 'board.dart';
import 'board_pos.dart';

class Playfield extends StatefulWidget {
  final WebSocketChannel channel;

  const Playfield({super.key, required this.channel});

  @override
  State<Playfield> createState() => _PlayfieldState();
}

class _PlayfieldState extends State<Playfield> {
  BoardState? _board;

  List<BoardPos>? _validMoves;
  BoardPos? _picked;

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: widget.channel.stream,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.active &&
          snapshot.hasData) {
        switch (ServerMessage.fromJson(jsonDecode(snapshot.data))) {
          case Start(board: final board):
            _board = board;
            break;

          case ValidMoves(validMoves: final validMoves):
            _validMoves = validMoves;
            break;

          case Place(at: final placedPos):
            if (_picked != placedPos) {
              _board!.board[placedPos.x][placedPos.y] =
                  _board!.board[_picked!.x][_picked!.y];
              _board!.board[_picked!.x][_picked!.y] = null;
            }
            _picked = null;
            break;

          case GameEnd(didWin: final didWin):
            // TODO
            debugPrint("Win: $didWin");
            break;

          case ServerError(error: final error):
            throw "Server error: $error";
        }
      }

      return _board != null
          ? Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boardLength = constraints.biggest.shortestSide;
                  final pieceLength = constraints.biggest.shortestSide / 8;

                  return SizedBox.square(
                    dimension: boardLength,
                    child: GridView.count(
                      childAspectRatio: 1,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 8,
                      children: [
                        for (final y in Iterable.generate(8).toList().reversed)
                          for (final x in Iterable.generate(8))
                            Container(
                              color:
                                  (x + y) % 2 == 1
                                      ? Color(0xFFFAF5F0)
                                      : Color(0xFF262942),
                              child:
                                  _board!.board[y][x] != null
                                      ? Draggable<BoardPos>(
                                        data: BoardPos(y, x),
                                        maxSimultaneousDrags: 1,
                                        feedback: PieceWidget(
                                          _board!.board[y][x]!,
                                          pieceLength: pieceLength,
                                        ),
                                        childWhenDragging: Container(),
                                        child: PieceWidget(
                                          _board!.board[y][x]!,
                                          pieceLength: pieceLength,
                                        ),
                                        onDragStarted: () async {
                                          _picked = BoardPos(y, x);
                                          widget.channel.sink.add(
                                            jsonEncode(Picked(BoardPos(y, x))),
                                          );
                                        },
                                        onDraggableCanceled: (_, _) {
                                          widget.channel.sink.add(
                                            jsonEncode(Placed(BoardPos(y, x))),
                                          );
                                          setState(() => _validMoves = null);
                                        },
                                      )
                                      : DragTarget<BoardPos>(
                                        builder:
                                            (_, _, _) => Container(
                                              color:
                                                  _validMoves?.contains(
                                                            BoardPos(y, x),
                                                          ) ??
                                                          false
                                                      ? (x + y) % 2 == 1
                                                          ? Color(0x20000000)
                                                          : Color(0x20FFFFFF)
                                                      : null,
                                            ),
                                        onWillAcceptWithDetails:
                                            (details) =>
                                                _validMoves?.contains(
                                                  BoardPos(y, x),
                                                ) ??
                                                false,
                                        onAcceptWithDetails: (details) {
                                          widget.channel.sink.add(
                                            jsonEncode(Placed(BoardPos(y, x))),
                                          );
                                          setState(() => _validMoves = null);
                                        },
                                      ),
                            ),
                      ],
                    ),
                  );
                },
              ),
            ),
          )
          : Container();
    },
  );
}

class PieceWidget extends StatelessWidget {
  const PieceWidget(this.piece, {super.key, required this.pieceLength});

  final Piece piece;
  final double pieceLength;

  @override
  Widget build(BuildContext context) => Image.asset(
    piece.assetName,
    filterQuality: FilterQuality.none,
    fit: BoxFit.contain,
    height: pieceLength,
    width: pieceLength,
  );
}
