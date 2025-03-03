use crate::{board::BoardState, board_pos::BoardPos};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum ServerMessage {
    Start { board: BoardState },

    ValidPositions(Vec<BoardPos>),
    Move { to: BoardPos },

    GameEnd(bool),

    Error(String),
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum ClientMessage {
    Picked { pos: BoardPos },
    Placed { pos: BoardPos },

    Error(String),
}
