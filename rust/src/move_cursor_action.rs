use std::cell::OnceCell;
use zellij_tile::prelude::*;

use crate::cli::options;
use crate::cli::Options;
use crate::fullscreen_state::get_fullscreen_state;
use crate::fullscreen_state::set_fullscreen_state;
use crate::fullscreen_state::FullscreenState;

#[expect(dead_code)]
pub struct MoveCursorAction<'a> {
    tabs: &'a Vec<TabInfo>,
    pane_manifest: &'a PaneManifest,
    options: &'a Options,
    current_tab: OnceCell<Option<TabInfo>>,
    current_pane: OnceCell<Option<PaneInfo>>,
    current_tab_panes: OnceCell<Option<&'a [PaneInfo]>>,
}

#[expect(dead_code)]
impl<'a> MoveCursorAction<'a> {
    pub fn new(
        tabs: &'a Vec<TabInfo>,
        pane_manifest: &'a PaneManifest,
        options: &'a Options,
    ) -> Self {
        Self {
            tabs,
            pane_manifest,
            options,
            current_tab: OnceCell::new(),
            current_pane: OnceCell::new(),
            current_tab_panes: OnceCell::new(),
        }
    }

    pub fn current_tab(&self) -> Option<&TabInfo> {
        self.current_tab
            .get_or_init(|| get_focused_tab(self.tabs))
            .as_ref()
    }

    pub fn current_pane(&self) -> Option<&PaneInfo> {
        let tab = self.current_tab()?;
        self.current_pane
            .get_or_init(|| get_focused_pane(tab.position, self.pane_manifest))
            .as_ref()
    }

    pub fn crrent_tab_panes(&self) -> Option<&'a [PaneInfo]> {
        *self.current_tab_panes.get_or_init(|| {
            let tab = self.current_tab()?;
            self.pane_manifest
                .panes
                .get(&tab.position)
                .map(|panes| panes.as_slice())
        })
    }

    pub fn is_blocked_by_fullscreen(&self) -> bool {
        if self.options.ignore_if_fullscreen {
            if let Some(tab) = self.current_tab() {
                return tab.is_fullscreen_active;
            }
        }
        false
    }

    fn set_fullscreen_state(&self, next_state: FullscreenState) {
        let Some(tab) = self.current_tab() else {
            return;
        };
        let Some(pane) = self.current_pane() else {
            return;
        };

        let current_state = get_fullscreen_state(pane, tab);
        set_fullscreen_state(current_state, next_state);
    }

    pub fn normal_move(&self, direction: Direction, tab_behavior: TabBehavior) {
        if self.is_blocked_by_fullscreen() {
            return;
        }

        if tab_behavior == TabBehavior::Move && direction.is_horizontal() {
            move_focus_or_tab(direction)
        } else {
            move_focus(direction)
        }

        if self.options.fullscreen == options::FullscreenBehavior::Exit {
            self.set_fullscreen_state(FullscreenState::Normal);
        }
    }

    #[expect(unused)]
    pub fn move_or_wrap(&self, direction: Direction, tab_behavior: TabBehavior) {
        if self.is_blocked_by_fullscreen() {
            return;
        }

        todo!()
    }

    #[expect(unused)]
    pub fn move_or_split(&self, direction: Direction, tab_behavior: TabBehavior) {
        if self.is_blocked_by_fullscreen() {
            return;
        }

        todo!()
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TabBehavior {
    Stop,
    Move,
}
