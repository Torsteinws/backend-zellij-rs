use std::str::FromStr;
use thiserror::Error;

#[allow(clippy::enum_variant_names)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Command {
    MoveFocus,
    MoveFocusOrTab,
    MoveFocusOrWrap,
    MoveFocusOrTabOrWrap,
    MoveFocusOrSplit,
    MoveFocusOrTabOrSplit,
}

impl FromStr for Command {
    type Err = UnknownCommand;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "move-focus" => Ok(Command::MoveFocus),
            "move-focus-or-tab" => Ok(Command::MoveFocusOrTab),
            "move-focus-or-wrap" => Ok(Command::MoveFocusOrWrap),
            "move-focus-or-tab-or-wrap" => Ok(Command::MoveFocusOrTabOrWrap),
            "move-focus-or-split" => Ok(Command::MoveFocusOrSplit),
            "move-focus-or-tab-or-split" => Ok(Command::MoveFocusOrTabOrSplit),
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
