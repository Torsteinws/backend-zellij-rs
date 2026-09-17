mod cli;
mod types;

use std::collections::BTreeMap;
use zellij_tile::prelude::*;

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

        eprintln!("{:#?}", cmd);

        false
    }

    fn render(&mut self, _rows: usize, _cols: usize) {}
}

#[allow(unused)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum FullscreenState {
    Normal,
    Fullscreen,
    NoUiFullscreen,
}

#[allow(unused)]
fn get_fullscreen_state(pane: &PaneInfo, tab: &TabInfo) -> FullscreenState {
    if !pane.is_fullscreen {
        return FullscreenState::Normal;
    }

    if pane.pane_x == 0
        && pane.pane_y == 0
        && pane.pane_rows == tab.display_area_rows
        && pane.pane_columns == tab.display_area_columns
    {
        FullscreenState::NoUiFullscreen
    } else {
        FullscreenState::Fullscreen
    }
}

#[allow(unused)]
fn set_fullscreen_state(current_state: FullscreenState, next_state: FullscreenState) {
    use FullscreenState::*;
    match (current_state, next_state) {
        (Normal, Fullscreen) => toggle_focus_fullscreen(),
        (Normal, NoUiFullscreen) => toggle_focus_no_ui_fullscreen(),
        (Fullscreen, Normal) => toggle_focus_fullscreen(),
        (Fullscreen, NoUiFullscreen) => toggle_focus_no_ui_fullscreen(),
        (NoUiFullscreen, Normal) => toggle_focus_no_ui_fullscreen(),
        (NoUiFullscreen, Fullscreen) => toggle_focus_fullscreen(),

        (Normal, Normal) | (Fullscreen, Fullscreen) | (NoUiFullscreen, NoUiFullscreen) => {}
    }
}
