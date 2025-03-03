use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
pub enum BoardPosX {
    A,
    B,
    C,
    D,
    E,
    F,
    G,
    H,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
pub enum BoardPosY {
    _1,
    _2,
    _3,
    _4,
    _5,
    _6,
    _7,
    _8,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
pub struct BoardPos(pub BoardPosX, pub BoardPosY);

impl TryFrom<usize> for BoardPosX {
    type Error = ();

    fn try_from(x: usize) -> Result<Self, Self::Error> {
        use BoardPosX::*;
        match x {
            0 => Ok(A),
            1 => Ok(B),
            2 => Ok(C),
            3 => Ok(D),
            4 => Ok(E),
            5 => Ok(F),
            6 => Ok(G),
            7 => Ok(H),
            _ => Err(()),
        }
    }
}

impl TryFrom<usize> for BoardPosY {
    type Error = ();

    fn try_from(y: usize) -> Result<Self, Self::Error> {
        use BoardPosY::*;
        match y {
            0 => Ok(_1),
            1 => Ok(_2),
            2 => Ok(_3),
            3 => Ok(_4),
            4 => Ok(_5),
            5 => Ok(_6),
            6 => Ok(_7),
            7 => Ok(_8),
            _ => Err(()),
        }
    }
}

impl TryFrom<(usize, usize)> for BoardPos {
    type Error = ();

    fn try_from((x, y): (usize, usize)) -> Result<Self, Self::Error> {
        Ok(Self(x.try_into()?, y.try_into()?))
    }
}

#[expect(
    clippy::from_over_into,
    reason = "From<(usize, usize)> is fallible while Into is not"
)]
impl Into<(usize, usize)> for BoardPos {
    fn into(self) -> (usize, usize) {
        let Self(x, y) = self;
        (
            match x {
                BoardPosX::A => 0,
                BoardPosX::B => 1,
                BoardPosX::C => 2,
                BoardPosX::D => 3,
                BoardPosX::E => 4,
                BoardPosX::F => 5,
                BoardPosX::G => 6,
                BoardPosX::H => 7,
            },
            match y {
                BoardPosY::_1 => 0,
                BoardPosY::_2 => 1,
                BoardPosY::_3 => 2,
                BoardPosY::_4 => 3,
                BoardPosY::_5 => 4,
                BoardPosY::_6 => 5,
                BoardPosY::_7 => 6,
                BoardPosY::_8 => 7,
            },
        )
    }
}
