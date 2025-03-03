use crate::{board::BoardState, board_pos::BoardPos};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub enum ServerMessage {
    Start { board: BoardState },

    ValidMoves(Vec<BoardPos>),
    Place { at: BoardPos },

    GameEnd(bool),

    Error(&'static str),
}

#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
pub enum ClientMessage {
    Picked { pos: BoardPos },
    Placed { pos: BoardPos },

    Error(String),
}
