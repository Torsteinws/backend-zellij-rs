use std::str::FromStr;
use thiserror::Error;

#[allow(clippy::enum_variant_names)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MoveBehavior {
    Normal,
    NormalOrTab,
    Wrap,
    TabOrWrap,
    Split,
    TabOrSplit,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Command {
    Move(MoveBehavior),
    Version,
}

impl FromStr for Command {
    type Err = UnknownCommand;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "version" => Ok(Command::Version),

            "move-focus" => Ok(Command::Move(MoveBehavior::Normal)),
            "move-focus-or-tab" => Ok(Command::Move(MoveBehavior::NormalOrTab)),
            "move-focus-or-wrap" => Ok(Command::Move(MoveBehavior::Wrap)),
            "move-focus-or-tab-or-wrap" => Ok(Command::Move(MoveBehavior::TabOrWrap)),
            "move-focus-or-split" => Ok(Command::Move(MoveBehavior::Split)),
            "move-focus-or-tab-or-split" => Ok(Command::Move(MoveBehavior::TabOrSplit)),
            other => Err(UnknownCommand {
                name: other.to_string(),
            }),
        }
    }
}

#[derive(Error, Debug, Clone, PartialEq, Eq)]
#[error("Unknown command: {name}")]
pub struct UnknownCommand {
    name: String,
}
