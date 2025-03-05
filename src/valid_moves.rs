use crate::{board::BoardState, board_pos::BoardPos};

impl BoardState {
    pub fn valid_moves(&self, _piece_pos: BoardPos) -> Vec<BoardPos> {
        // TODO
        let mut valid_moves = vec![];

        for (y, row) in self.0.iter().enumerate() {
            for (x, piece) in row.iter().enumerate() {
                if piece.is_none() {
                    valid_moves.push(BoardPos::try_from((x, y)).unwrap());
                }
            }
        }

        valid_moves
    }
}
