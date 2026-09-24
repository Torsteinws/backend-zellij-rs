mod cli;
mod fullscreen_state;
mod move_cursor_action;
mod utils;
use crate::cli::MoveBehavior;
use crate::move_cursor_action::{MoveCursorAction, TabBehavior};
use std::collections::BTreeMap;
use zellij_tile::prelude::{actions::Action, *};

#[derive(Default)]
struct State {
    permissions_granted: bool,
    tabs: Vec<TabInfo>,
    pane_manifest: PaneManifest,
    launch_pipe: Option<PipeMessage>,
}

register_plugin!(State);

impl ZellijPlugin for State {
    fn load(&mut self, _configuration: BTreeMap<String, String>) {
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
                self.make_invisible();
                if let Some(pipe_message) = self.launch_pipe.take() {
                    self.pipe(pipe_message);
                }
            }
            Event::TabUpdate(tab_infos) => {
                self.tabs = tab_infos;
            }
            Event::PaneUpdate(pane_manifest) => {
                self.pane_manifest = pane_manifest;
            }
            Event::ActionComplete(Action::NewPane { .. }, new_pane_id, context) => {
                utils::new_pane_callback(new_pane_id, context);
            }

            _ => {}
        }
        false
    }

    fn pipe(&mut self, pipe_message: PipeMessage) -> bool {
        if !self.permissions_granted {
            self.launch_pipe = Some(pipe_message);
            return false;
        }

        let parsed_cmd = match cli::parse_input(&pipe_message) {
            Ok(cmd) => cmd,
            Err(err) => {
                eprintln!("{err}");
                return false;
            }
        };

        match parsed_cmd {
            cli::ParsedCommand::Version => utils::write_to_pipe(pipe_message.source, "0.1.0"),
            cli::ParsedCommand::Move(cmd) => {
                let mover = MoveCursorAction::new(&self.tabs, &self.pane_manifest, &cmd.options);
                let result = match cmd.command {
                    MoveBehavior::Normal => mover.normal_move(cmd.direction, TabBehavior::Stop),
                    MoveBehavior::NormalOrTab => {
                        mover.normal_move(cmd.direction, TabBehavior::Move)
                    }

                    MoveBehavior::Wrap => mover.move_or_wrap(cmd.direction, TabBehavior::Stop),
                    MoveBehavior::TabOrWrap => mover.move_or_wrap(cmd.direction, TabBehavior::Move),

                    MoveBehavior::Split => mover.move_or_split(cmd.direction, TabBehavior::Stop),
                    MoveBehavior::TabOrSplit => {
                        mover.move_or_split(cmd.direction, TabBehavior::Move)
                    }
                };
                if let Err(err) = result {
                    eprintln!("ERROR: {0}", err)
                }
            }
        }

        false
    }

    fn render(&mut self, _rows: usize, _cols: usize) {}
}

impl State {
    fn make_invisible(&self) {
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
}
