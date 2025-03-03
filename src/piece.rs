use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Player {
    Black,
    White,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
pub enum PieceType {
    King,
    Queen,
    Rook,
    Bishop,
    Knight,
    Pawn,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct Piece(pub Player, pub PieceType);

impl std::fmt::Display for Piece {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let Self(player, _type) = self;

        use PieceType::*;
        use Player::*;
        write!(
            f,
            "{}",
            match player {
                Black => match _type {
                    King => "♔",
                    Queen => "♕",
                    Rook => "♖",
                    Bishop => "♗",
                    Knight => "♘",
                    Pawn => "♙",
                },
                White => match _type {
                    King => "♚",
                    Queen => "♛",
                    Rook => "♜",
                    Bishop => "♝",
                    Knight => "♞",
                    Pawn => "♟",
                },
            }
        )
    }
}
