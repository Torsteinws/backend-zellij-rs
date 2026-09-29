mod cli;
mod move_cursor_action;
mod utils;
use crate::PluginError::NotInstantiated;
use crate::cli::MoveBehavior;
use crate::cli::parser::ParsedMoveCommand;
use crate::move_cursor_action::{MoveCursorAction, MoveCursorError, TabBehavior};
use std::collections::BTreeMap;
use thiserror::Error;
use zellij_tile::prelude::{actions::Action, *};

const VERSION: &str = env!("VERSION");

#[derive(Default)]
struct State {
    tabs: Option<Vec<TabInfo>>,
    pane_manifest: Option<PaneManifest>,

    // Keybinds don't support passing down args to the plugin.
    // It does however support configuration, so we will treat that as args.
    keybind_args: BTreeMap<String, String>,

    // If the plugin receives a command on startup, we must keep track of the command until the
    // plugin is fully loaded. I.E. We have permissions to run and have a reference to current tabs and panes.
    launch_pipe: Option<PipeMessage>,
    permissions_granted: bool,
    is_initialized: bool,
}

register_plugin!(State);

impl ZellijPlugin for State {
    fn load(&mut self, configuration: BTreeMap<String, String>) {
        self.keybind_args = configuration;
        self.is_initialized = false;

        self.permissions_granted = false;
        request_permission(&[
            PermissionType::ReadApplicationState,
            PermissionType::ChangeApplicationState,
            PermissionType::ReadCliPipes,
            PermissionType::RunActionsAsUser,
        ]);
        subscribe(&[EventType::PermissionRequestResult]);
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::PermissionRequestResult(PermissionStatus::Denied) => self.launch_pipe = None,
            Event::PermissionRequestResult(PermissionStatus::Granted) => {
                // permissions granted, subscribe to events that require them
                subscribe(&[
                    EventType::TabUpdate,
                    EventType::PaneUpdate,
                    EventType::ActionComplete,
                ]);
                self.permissions_granted = true;
                make_invisible();
                self.try_initialize();
            }
            Event::TabUpdate(tab_infos) => {
                self.tabs = Some(tab_infos);
                self.try_initialize();
            }
            Event::PaneUpdate(pane_manifest) => {
                self.pane_manifest = Some(pane_manifest);
                self.try_initialize();
            }
            Event::ActionComplete(Action::NewPane { .. }, new_pane_id, context) => {
                utils::new_pane_callback(new_pane_id, &context);
            }

            _ => {}
        }
        false
    }

    fn pipe(&mut self, pipe_message: PipeMessage) -> bool {
        if !self.is_initialized {
            self.launch_pipe = Some(pipe_message);
            return false;
        }

        // Set up a panic handler. The handler will not try to recover, it will only notify the caller that the plugin has panicked.
        if let PipeSource::Cli(pipe_id) = pipe_message.source.clone() {
            // Hold the CLI command open so that we can print to stdout if the plugin panics.
            block_cli_pipe_input(&pipe_id);
            std::panic::set_hook(Box::new(move |info| {
                let message = info.payload_as_str().unwrap_or("");
                cli_pipe_output(&pipe_id, &format!("PANIC! {message}\n"));
                unblock_cli_pipe_input(&pipe_id);
                report_panic(info);
            }));
        }

        // Main program
        self.handle_commmand(&pipe_message);

        if let PipeSource::Cli(pipe_id) = &pipe_message.source {
            unblock_cli_pipe_input(pipe_id);
        }

        false
    }

    fn render(&mut self, _rows: usize, _cols: usize) {}
}

impl State {
    fn try_initialize(&mut self) {
        if self.is_initialized {
            return;
        }

        let ready = self.permissions_granted && self.tabs.is_some() && self.pane_manifest.is_some();
        if !ready {
            return;
        }

        self.is_initialized = true;
        if let Some(launch_cmd) = self.launch_pipe.take() {
            self.pipe(launch_cmd);
        }
    }

    pub fn handle_commmand(&self, pipe_message: &PipeMessage) {
        let args = match pipe_message.source {
            PipeSource::Keybind if pipe_message.args.is_empty() => &self.keybind_args,
            _ => &pipe_message.args,
        };
        let name = &pipe_message.name;
        let payload = pipe_message.payload.as_deref();

        let parsed_cmd = match cli::parse_input(name, payload, args) {
            Ok(cmd) => cmd,
            Err(err) => {
                write_error(&pipe_message.source, err);
                return;
            }
        };

        match parsed_cmd {
            cli::ParsedCommand::Version => utils::write_to_pipe(&pipe_message.source, VERSION),
            cli::ParsedCommand::Move(cmd) => {
                let result = self.handle_move_command(cmd);
                if let Err(err) = result {
                    write_error(&pipe_message.source, err);
                }
            }
        }
    }

    fn handle_move_command(&self, cmd: ParsedMoveCommand) -> Result<(), PluginError> {
        let Some(tabs) = &self.tabs else {
            return Err(NotInstantiated("tabs"));
        };
        let Some(pane_manifest) = &self.pane_manifest else {
            return Err(NotInstantiated("pane_manifest"));
        };

        let mover = MoveCursorAction::new(tabs, pane_manifest, &cmd.options);
        match cmd.command {
            MoveBehavior::Normal => mover.normal_move(cmd.direction, TabBehavior::Stop),
            MoveBehavior::NormalOrTab => mover.normal_move(cmd.direction, TabBehavior::Move),

            MoveBehavior::Wrap => mover.move_or_wrap(cmd.direction, TabBehavior::Stop),
            MoveBehavior::TabOrWrap => mover.move_or_wrap(cmd.direction, TabBehavior::Move),

            MoveBehavior::Split => mover.move_or_split(cmd.direction, TabBehavior::Stop),
            MoveBehavior::TabOrSplit => mover.move_or_split(cmd.direction, TabBehavior::Move),
        }?;

        Ok(())
    }
}

fn write_error<E: std::fmt::Display>(source: &PipeSource, err: E) {
    eprintln!("ERROR: {err}");
    utils::write_to_pipe(source, &format!("ERROR: {err}"));
}

fn make_invisible() {
    // We can not use `hide_self()` or `close_self()`, because that will prevent `PaneUpdate` and
    // `TabUpdate` events from being triggered.
    // Workaround: Force pane to have 0 width/height and make it floating.

    let ids = get_plugin_ids();
    let pane_id = PaneId::Plugin(ids.plugin_id);
    let Some(pane) = get_pane_info(pane_id) else {
        return;
    };

    // Ensure plugin pane is floating
    if !pane.is_floating {
        toggle_pane_embed_or_eject_for_pane_id(pane_id);
    }

    // Hide in top left corner with 0 size
    let mut coordinates = FloatingPaneCoordinates::default()
        .with_x_fixed(0)
        .with_y_fixed(0)
        .with_width_fixed(0)
        .with_height_fixed(0);
    coordinates.pinned = Some(false);
    coordinates.borderless = Some(true);

    change_floating_panes_coordinates(vec![(pane_id, coordinates)]);

    // Don't allow the pane to receive keyboard focus
    set_selectable(false);
}

#[derive(Error, Debug, Clone, PartialEq, Eq)]
enum PluginError {
    #[error(transparent)]
    MoveCommandError(#[from] MoveCursorError),

    #[error("can't read property '{0}' because it has not yet been instantiated")]
    NotInstantiated(&'static str),
}
