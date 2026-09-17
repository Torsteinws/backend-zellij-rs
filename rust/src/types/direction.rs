use std::str::FromStr;
use thiserror::Error;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Direction {
    Left,
    Right,
    Up,
    Down,
}

impl FromStr for Direction {
    type Err = ParseDirectionError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "left" => Ok(Direction::Left),
            "right" => Ok(Direction::Right),
            "up" => Ok(Direction::Up),
            "down" => Ok(Direction::Down),
            other => Err(ParseDirectionError {
                value: other.to_string(),
            }),
        }
    }
}

#[derive(Error, Debug, Clone, PartialEq, Eq)]
#[error("invalid direction: {value}")]
pub struct ParseDirectionError {
    value: String,
}
