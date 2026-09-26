use zellij_tile::prelude::*;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FullscreenState {
    Normal,
    Fullscreen,
    NoUiFullscreen,
}

pub fn get_fullscreen_state(pane: &PaneInfo, tab: &TabInfo) -> FullscreenState {
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

pub fn set_fullscreen_state(current_state: FullscreenState, next_state: FullscreenState) {
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
