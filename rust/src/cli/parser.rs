use crate::cli::{self, Options, ParseFullscreenBehaviorError, UnknownCommand};
use std::collections::BTreeMap;
use thiserror::Error;
use zellij_tile::prelude::Direction;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ParsedMoveCommand {
    pub command: cli::MoveBehavior,
    pub direction: Direction,
    pub options: cli::Options,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ParsedCommand {
    Move(ParsedMoveCommand),
    Version,
}

pub fn parse_input(
    command_name: &str,
    payload: Option<&str>,
    pipe_args: &BTreeMap<String, String>,
) -> Result<ParsedCommand, ParseError> {
    let command: cli::Command = command_name.parse()?;

    match command {
        cli::Command::Move(action) => {
            let direction = parse_move_payload(payload)?;
            let options = parse_move_options(pipe_args)?;
            Ok(ParsedCommand::Move(ParsedMoveCommand {
                command: action,
                direction,
                options,
            }))
        }
        cli::Command::Version => Ok(ParsedCommand::Version),
    }
}

fn parse_move_payload(input: Option<&str>) -> Result<Direction, ParseError> {
    let Some(payload) = input.as_ref() else {
        return Err(ParseError::MissingPayload);
    };

    match payload.parse::<Direction>() {
        Ok(direction) => Ok(direction),
        Err(err) => Err(ParseError::InvalidPayload(err)),
    }
}

fn parse_move_options(opts: &BTreeMap<String, String>) -> Result<Options, ParseError> {
    let ignore_if_fullscreen = parse_bool_option(
        opts,
        "ignore-if-fullscreen",
        Options::default().ignore_if_fullscreen,
    )?;

    let fullscreen = match opts.get("fullscreen") {
        None => Options::default().fullscreen,
        Some(value) => value.parse()?,
    };

    Ok(Options {
        ignore_if_fullscreen,
        fullscreen,
    })
}

pub fn parse_bool_option(
    opts: &BTreeMap<String, String>,
    key: &'static str,
    default: bool,
) -> Result<bool, ParseError> {
    let Some(value) = opts.get(key) else {
        return Ok(default);
    };

    match value.trim().to_ascii_lowercase().as_str() {
        "true" | "" => Ok(true),
        "false" => Ok(false),
        _ => Err(ParseError::InvalidBooleanValue {
            key,
            value: value.clone(),
        }),
    }
}

#[derive(Error, Debug, Clone, PartialEq, Eq)]
pub enum ParseError {
    #[error(transparent)]
    InvalidPipeName(#[from] UnknownCommand),

    #[error("missing payload: expected one of \"left\", \"right\", \"up\", \"down\"")]
    MissingPayload,

    #[error("Invalid payload. Reason: {0}")]
    InvalidPayload(String),

    #[error("invalid value for fulsccreen. \nReason: {0}")]
    InvalidFullscreenValue(#[from] ParseFullscreenBehaviorError),

    #[error("invalid value {value:?} for {key:?}: expected \"true\" or \"false\"")]
    InvalidBooleanValue { key: &'static str, value: String },
}
