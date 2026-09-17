use std::str::FromStr;
use thiserror::Error;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Options {
    pub ignore_if_fullscreen: bool,
    pub fullscreen: FullscreenBehavior,
}

impl Default for Options {
    fn default() -> Self {
        Options {
            ignore_if_fullscreen: false,
            fullscreen: FullscreenBehavior::Default,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum FullscreenBehavior {
    Exit,
    Keep,
    #[default]
    Default,
}

impl FromStr for FullscreenBehavior {
    type Err = ParseFullscreenBehaviorError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "exit" => Ok(FullscreenBehavior::Exit),
            "keep" => Ok(FullscreenBehavior::Keep),
            "default" => Ok(FullscreenBehavior::Default),
            other => Err(ParseFullscreenBehaviorError {
                value: other.to_string(),
            }),
        }
    }
}

#[derive(Error, Debug, Clone, PartialEq, Eq)]
#[error("invalid value for fullscreen behavior. Got \"{value}\", expected one of \"exit\", \"keep\", \"default\"")]
pub struct ParseFullscreenBehaviorError {
    value: String,
}
