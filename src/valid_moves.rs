use crate::{board::BoardState, board_pos::BoardPos};

impl BoardState {
    pub fn valid_moves(&self, _piece_pos: BoardPos) -> Vec<BoardPos> {
        // TODO
        let mut valid_moves = vec![];

        for y in (0..8).rev() {
            for x in 0..8 {
                valid_moves.push(BoardPos::try_from((x, y)).unwrap());
            }
        }

        valid_moves
    }
}
