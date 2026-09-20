use crate::cli::{self, Options, ParseFullscreenBehaviorError, UnknownCommand};
use std::collections::BTreeMap;
use thiserror::Error;
use zellij_tile::prelude::Direction;

use zellij_tile::prelude::PipeMessage;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ParsedCommand {
    pub command: cli::Command,
    pub direction: Direction,
    pub options: cli::Options,
}

pub fn parse_input(pipe_message: &PipeMessage) -> Result<ParsedCommand, ParseError> {
    let command: cli::Command = pipe_message.name.parse()?;

    let Some(payload) = pipe_message.payload.as_ref() else {
        return Err(ParseError::MissingPayload);
    };

    let direction: Direction = match payload.parse() {
        Ok(direction) => direction,
        Err(err) => return Err(ParseError::InvalidPayload(err)),
    };

    let options = parse_options(&pipe_message.args)?;

    Ok(ParsedCommand {
        command,
        direction,
        options,
    })
}

pub fn parse_options(opts: &BTreeMap<String, String>) -> Result<Options, ParseError> {
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
            value: value.to_string(),
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
