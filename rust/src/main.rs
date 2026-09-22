mod cli;
mod fullscreen_state;
mod move_cursor_action;
use crate::move_cursor_action::{MoveCursorAction, TabBehavior};

use std::collections::BTreeMap;
use zellij_tile::prelude::*;

use crate::cli::Command;

#[derive(Default)]
struct State {
    permissions_granted: bool,
    tabs: Vec<TabInfo>,
    pane_manifest: PaneManifest,
}

register_plugin!(State);

impl ZellijPlugin for State {
    fn load(&mut self, _configuration: BTreeMap<String, String>) {
        self.permissions_granted = false;
        request_permission(&[
            PermissionType::ReadApplicationState,
            PermissionType::ChangeApplicationState,
        ]);
        subscribe(&[EventType::PermissionRequestResult]);
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            // ...
            Event::PermissionRequestResult(PermissionStatus::Granted) => {
                // permissions granted, subscribe to events that require them
                subscribe(&[EventType::TabUpdate, EventType::PaneUpdate]);
                self.permissions_granted = true;
            }
            Event::TabUpdate(tab_infos) => {
                self.tabs = tab_infos;
            }
            Event::PaneUpdate(pane_manifest) => {
                self.pane_manifest = pane_manifest;
            }
            _ => {}
        }
        false
    }

    fn pipe(&mut self, pipe_message: PipeMessage) -> bool {
        if !self.permissions_granted {
            return false;
        }

        let cmd = match cli::parse_input(&pipe_message) {
            Ok(cmd) => cmd,
            Err(err) => {
                eprintln!("{err}");
                return false;
            }
        };

        let mover = MoveCursorAction::new(&self.tabs, &self.pane_manifest, &cmd.options);
        let result = match cmd.command {
            Command::MoveFocus => mover.normal_move(cmd.direction, TabBehavior::Stop),
            Command::MoveFocusOrTab => mover.normal_move(cmd.direction, TabBehavior::Move),

            Command::MoveFocusOrWrap => mover.move_or_wrap(cmd.direction, TabBehavior::Stop),
            Command::MoveFocusOrTabOrWrap => mover.move_or_wrap(cmd.direction, TabBehavior::Move),

            Command::MoveFocusOrSplit => mover.move_or_split(cmd.direction, TabBehavior::Stop),
            Command::MoveFocusOrTabOrSplit => mover.move_or_split(cmd.direction, TabBehavior::Move),
        };

        if let Err(err) = result {
            eprint!("ERROR: {0}", err)
        }

        false
    }

    fn render(&mut self, _rows: usize, _cols: usize) {}
}
