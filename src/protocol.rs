use crate::{board::BoardState, board_pos::BoardPos};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub enum ServerMessage {
    Start(BoardState),

    ValidMoves(Vec<BoardPos>),
    Place(BoardPos, BoardPos),

    GameEnd(bool),

    Error(&'static str),
}

#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
pub enum ClientMessage {
    Picked(BoardPos),
    Placed(BoardPos),

    Error(String),
}
