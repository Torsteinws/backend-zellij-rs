mod command;
pub use command::Command;
pub use command::UnknownCommand;

pub mod options;
pub use options::Options;
pub use options::ParseFullscreenBehaviorError;

mod parser;
pub use parser::parse_input;
