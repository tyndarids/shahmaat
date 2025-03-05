use super::piece::Piece;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct BoardState(pub [[Option<Piece>; 8]; 8]);

impl Default for BoardState {
    fn default() -> Self {
        use super::piece::{PieceType::*, Player::*};
        let mut state = [
            [
                Some(Piece(Black, Rook)),
                Some(Piece(Black, Knight)),
                Some(Piece(Black, Bishop)),
                Some(Piece(Black, Queen)),
                Some(Piece(Black, King)),
                Some(Piece(Black, Bishop)),
                Some(Piece(Black, Knight)),
                Some(Piece(Black, Rook)),
            ],
            [Some(Piece(Black, Pawn)); 8],
            [None; 8],
            [None; 8],
            [None; 8],
            [None; 8],
            [Some(Piece(White, Pawn)); 8],
            [
                Some(Piece(White, Rook)),
                Some(Piece(White, Knight)),
                Some(Piece(White, Bishop)),
                Some(Piece(White, Queen)),
                Some(Piece(White, King)),
                Some(Piece(White, Bishop)),
                Some(Piece(White, Knight)),
                Some(Piece(White, Rook)),
            ],
        ];
        state.reverse();
        Self(state)
    }
}

impl std::fmt::Display for BoardState {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        writeln!(f, "  ╭────────────────────────╮")?;
        for (y, row) in self.0.iter().enumerate().rev() {
            write!(f, "{} │", y + 1)?;
            for piece in row {
                if let Some(piece) = piece {
                    write!(f, " {piece} ")?;
                } else {
                    write!(f, "   ")?;
                }
            }
            writeln!(f, "│")?;
        }
        writeln!(f, "  ╰────────────────────────╯")?;
        writeln!(f, "    a  b  c  d  e  f  g  h")?;
        Ok(())
    }
}

impl<T: Into<(usize, usize)>> std::ops::Index<T> for BoardState {
    type Output = Option<Piece>;

    fn index(&self, index: T) -> &Self::Output {
        let (x, y) = index.into();
        &self.0[y][x]
    }
}

impl<T: Into<(usize, usize)>> std::ops::IndexMut<T> for BoardState {
    fn index_mut(&mut self, index: T) -> &mut Self::Output {
        let (x, y) = index.into();
        &mut self.0[y][x]
    }
}
