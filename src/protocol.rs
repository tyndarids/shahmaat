use serde::{Deserialize, Serialize};

use crate::{board::BoardState, board_pos::BoardPos, piece::Piece};

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub enum ServerMessage {
    Start(BoardState),

    ValidMoves(Vec<BoardPos>),
    Place {
        from: BoardPos,
        to: BoardPos,
        takes: Option<Piece>,
    },

    GameEnd(bool),

    Error(&'static str),
}

#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
pub enum ClientMessage {
    Picked(BoardPos),
    Placed(BoardPos),

    Error(String),
}
