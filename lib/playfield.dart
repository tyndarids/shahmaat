import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'piece.dart';
import 'protocol.dart';
import 'board.dart';
import 'board_pos.dart';

class StreamHandler extends StatefulWidget {
  const StreamHandler({super.key, required this.channel});

  final WebSocketChannel channel;

  @override
  State<StreamHandler> createState() => _StreamHandlerState();
}

class _StreamHandlerState extends State<StreamHandler> {
  // DO NOT call setState in this widget since that will rebuild the
  // StreamBuilder, resubscribe to the stream, and reprocess the latest data,
  // which wrecks havoc on the game state.

  BoardState? _board;
  List<BoardPos>? _validMoves;
  List<Piece> taken = [];

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

          case Place(from: final from, to: final to):
            if (_board != null) {
              final movedPiece = _board![from];
              _board![from] = null;
              if (_board![to] != null) taken.add(_board![to]!);
              _board![to] = movedPiece;
            }
            _validMoves = null;
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
          ? Playfield(
            channelTx: widget.channel.sink,
            board: _board!,
            validMoves: _validMoves,
          )
          : CircularProgressIndicator();
    },
  );
}

class Playfield extends StatefulWidget {
  const Playfield({
    super.key,
    required this.channelTx,
    required this.board,
    required this.validMoves,
  });

  final Sink channelTx;
  final BoardState board;
  final List<BoardPos>? validMoves;

  @override
  State<Playfield> createState() => _PlayfieldState();
}

class _PlayfieldState extends State<Playfield> {
  bool _hasPicked = false;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boardLength = constraints.biggest.shortestSide;
          final pieceLength = boardLength / 8;

          return SizedBox.square(
            dimension: boardLength,
            child: GridView.count(
              childAspectRatio: 1,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 8,
              children: [
                for (final y in Iterable.generate(8).toList().reversed)
                  for (final x in Iterable.generate(8))
                    Stack(
                      children: [
                        Container(
                          color:
                              (x + y) % 2 == 1
                                  ? Color(0xFFFAF5F0)
                                  : Color(0xFF262942),
                        ),
                        BoardTile(
                          widget.board[BoardPos(x, y)],
                          pieceLength: pieceLength,
                          hasPicked: _hasPicked,
                          isValidMove:
                              widget.validMoves?.contains(BoardPos(x, y)) ??
                              false,
                          picked: () {
                            setState(() => _hasPicked = true);
                            widget.channelTx.add(
                              jsonEncode(Picked(BoardPos(x, y))),
                            );
                          },
                          placed: () {
                            setState(() => _hasPicked = false);
                            widget.channelTx.add(
                              jsonEncode(Placed(BoardPos(x, y))),
                            );
                          },
                        ),
                      ],
                    ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class BoardTile extends StatelessWidget {
  const BoardTile(
    this.piece, {
    super.key,
    required this.hasPicked,
    required this.isValidMove,
    required this.pieceLength,
    required this.picked,
    required this.placed,
  });

  final Piece? piece;
  final bool hasPicked;
  final bool isValidMove;
  final double pieceLength;

  final void Function() picked;
  final void Function() placed;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      piece != null
          ? Draggable<BoardPos>(
            data: BoardPos(0, 0), // placeholder value
            maxSimultaneousDrags: hasPicked ? 0 : 1,
            onDragStarted: picked,
            onDraggableCanceled: (_, _) => placed(),
            childWhenDragging: Container(),
            feedback: PieceWidget(piece!, pieceLength: pieceLength),
            child: PieceWidget(piece!, pieceLength: pieceLength),
          )
          : Container(),
      isValidMove
          ? DragTarget<BoardPos>(
            builder:
                (_, _, _) => Image.asset(
                  "assets/valid_move.png",
                  // disable antialiasing for pixel art
                  filterQuality: FilterQuality.none,
                  fit: BoxFit.contain,
                  height: pieceLength,
                  width: pieceLength,
                ),
            onWillAcceptWithDetails: (_) => isValidMove,
            onAcceptWithDetails: (_) => placed(),
          )
          : Container(),
    ],
  );
}

class PieceWidget extends StatelessWidget {
  const PieceWidget(this.piece, {super.key, required this.pieceLength});

  final Piece piece;
  final double pieceLength;

  @override
  Widget build(BuildContext context) => Image.asset(
    piece.assetName,
    filterQuality: FilterQuality.none, // disable antialiasing for pixel art
    fit: BoxFit.contain,
    height: pieceLength,
    width: pieceLength,
  );
}
