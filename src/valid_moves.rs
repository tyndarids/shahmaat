use crate::{board::BoardState, board_pos::BoardPos, piece::Piece};

impl Piece {
    pub fn valid_moves(&self, board: BoardState) -> Vec<BoardPos> {
        // TODO
        let mut valid_moves = vec![];

        for (x, row) in board.0.iter().enumerate() {
            for (y, piece) in row.iter().enumerate() {
                if piece.is_some() {
                    valid_moves.push(BoardPos::try_from((x, y)).unwrap());
                }
            }
        }

        valid_moves
    }
}
