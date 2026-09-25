use crate::cli::options;
use crate::cli::Options;
use crate::fullscreen_state::*;
use crate::utils;
use std::cell::OnceCell;
use thiserror::Error;
use zellij_tile::prelude::*;

pub struct MoveCursorAction<'a> {
    tabs: &'a Vec<TabInfo>,
    pane_manifest: &'a PaneManifest,
    options: &'a Options,
    current_tab: OnceCell<Option<TabInfo>>,
    current_pane: OnceCell<Option<PaneInfo>>,
    current_tab_panes: OnceCell<&'a Vec<PaneInfo>>,
    pane_candidates: OnceCell<Vec<&'a PaneInfo>>, // All possible navigation targets
}

#[derive(Error, Debug, Clone, PartialEq, Eq)]
pub enum MoveCursorError {
    #[error("current zellij tab was not found")]
    TabNotFound,

    #[error("current zellij pane was not found")]
    CurrentPaneNotFound,

    #[error("did not find any zellij panes in the current tab")]
    CurrentTabPanesNotFound,

    #[error("reached a code path that should be unreachable.\n{0}")]
    ReachedUnreachableCodePath(&'static str),
}

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
            pane_candidates: OnceCell::new(),
        }
    }

    pub fn current_tab(&self) -> Result<&TabInfo, MoveCursorError> {
        self.current_tab
            .get_or_init(|| get_focused_tab(self.tabs))
            .as_ref()
            .ok_or(MoveCursorError::TabNotFound)
    }

    pub fn current_pane(&self) -> Result<&PaneInfo, MoveCursorError> {
        let tab = self.current_tab()?;
        self.current_pane
            .get_or_init(|| get_focused_pane(tab.position, self.pane_manifest))
            .as_ref()
            .ok_or(MoveCursorError::CurrentPaneNotFound)
    }

    pub fn current_tab_panes(&self) -> Result<&'a Vec<PaneInfo>, MoveCursorError> {
        if let Some(tab_panes) = self.current_tab_panes.get() {
            return Ok(tab_panes);
        }

        let tab = self.current_tab()?;

        let tab_panes = self
            .pane_manifest
            .panes
            .get(&tab.position)
            .ok_or(MoveCursorError::CurrentTabPanesNotFound)?;

        let _ = self.current_tab_panes.get_or_init(|| tab_panes);

        Ok(tab_panes)
    }

    fn pane_candidates(&self) -> Result<&Vec<&PaneInfo>, MoveCursorError> {
        if let Some(candidates) = self.pane_candidates.get() {
            return Ok(candidates);
        }

        let current_pane = self.current_pane()?;
        let tab_panes = self.current_tab_panes()?;

        let candidates = self.pane_candidates.get_or_init(|| {
            tab_panes
                .iter()
                .filter(|p| {
                    p.is_selectable && !p.is_suppressed && !p.is_floating && p.id != current_pane.id
                })
                .collect()
        });

        Ok(candidates)
    }

    pub fn is_blocked_by_fullscreen(&self) -> Result<bool, MoveCursorError> {
        if self.options.ignore_if_fullscreen {
            let tab = self.current_tab()?;
            return Ok(tab.is_fullscreen_active);
        }
        Ok(false)
    }

    fn set_fullscreen_state(&self, next_state: FullscreenState) -> Result<(), MoveCursorError> {
        let current_state = self.get_fullscreen_state()?;
        set_fullscreen_state(current_state, next_state);
        Ok(())
    }

    fn get_fullscreen_state(&self) -> Result<FullscreenState, MoveCursorError> {
        let tab = self.current_tab()?;
        let pane = self.current_pane()?;
        Ok(get_fullscreen_state(pane, tab))
    }

    fn move_focus(&self, direction: Direction) -> Result<(), MoveCursorError> {
        move_focus(direction);
        if self.options.fullscreen == options::FullscreenBehavior::Exit {
            self.set_fullscreen_state(FullscreenState::Normal)?;
        }
        Ok(())
    }

    fn move_focus_or_tab(&self, direction: Direction) -> Result<(), MoveCursorError> {
        move_focus_or_tab(direction);
        if self.options.fullscreen == options::FullscreenBehavior::Exit {
            self.set_fullscreen_state(FullscreenState::Normal)?;
        }
        Ok(())
    }

    fn focus_terminal_pane(&self, pane_id: u32) -> Result<(), MoveCursorError> {
        let initial_fullscreen_state = self.get_fullscreen_state()?;

        focus_terminal_pane(pane_id, false, false);

        if self.options.fullscreen == options::FullscreenBehavior::Keep {
            set_fullscreen_state(FullscreenState::Normal, initial_fullscreen_state);
        }

        Ok(())
    }

    fn get_current_cursor(&self) -> Option<Point> {
        match self.current_pane() {
            Ok(pane) => Self::get_cursor(pane),
            _ => None,
        }
    }

    fn get_cursor(pane: &PaneInfo) -> Option<Point> {
        pane.cursor_coordinates_in_pane.map(|cursor| {
            Point::new(
                (pane.pane_x + cursor.0) as isize,
                (pane.pane_y + cursor.1) as isize,
            )
        })
    }

    fn get_current_pane_geometry(&self) -> Result<Rect, MoveCursorError> {
        let pane = self.current_pane()?;
        if !pane.is_fullscreen {
            return Ok(Rect::from_pane(pane));
        }

        todo!()
    }

    pub fn normal_move(
        &self,
        direction: Direction,
        tab_behavior: TabBehavior,
    ) -> Result<(), MoveCursorError> {
        if self.is_blocked_by_fullscreen()? {
            return Ok(());
        }

        if tab_behavior == TabBehavior::Move && direction.is_horizontal() {
            self.move_focus_or_tab(direction)?;
        } else {
            self.move_focus(direction)?;
        }

        Ok(())
    }

    pub fn move_or_wrap(
        &self,
        direction: Direction,
        tab_behavior: TabBehavior,
    ) -> Result<(), MoveCursorError> {
        if self.is_blocked_by_fullscreen()? {
            return Ok(());
        }

        if tab_behavior == TabBehavior::Move && self.tabs.len() > 1 {
            return self.move_focus_or_tab(direction);
        }

        let candidates = self.pane_candidates()?;
        if candidates.is_empty() {
            return Ok(());
        }

        if self.candidate_exists(direction)? {
            return self.move_focus(direction);
        }

        let current_pane_geometry = self.get_current_pane_geometry()?;

        // Find all panes that borders the diametrical opposing edge,
        // and aligns with the current pane.
        let opposing_panes = {
            let mut result: Vec<&PaneInfo> = Vec::new();
            let mut largest_delta = 0;
            let origin = &current_pane_geometry;

            let wrap_direction = direction.invert();

            for pane in candidates {
                let target = Rect::from_pane(pane);

                // Target must align with the current pane to be valid.
                let is_aligned = match wrap_direction {
                    Direction::Left | Direction::Right => target.rows_overlap(origin), // Moving horizontally, target must have overlaping rows
                    Direction::Up | Direction::Down => target.cols_overlap(origin), // Moving vertically, target must have overlapping columns
                };
                if !is_aligned {
                    continue;
                }

                let delta = match wrap_direction {
                    Direction::Left => origin.x - target.x,
                    Direction::Right => target.right() - origin.x,
                    Direction::Up => origin.y - target.y,
                    Direction::Down => target.bottom() - origin.y,
                };

                if delta > largest_delta {
                    largest_delta = delta;
                    result.clear();
                    result.push(pane);
                } else if delta == largest_delta {
                    result.push(pane)
                }
            }
            result
        };

        if opposing_panes.is_empty() {
            return Ok(());
        }

        let wrap_target = {
            let mut result: Option<&PaneInfo> = None;

            let origin = match self.current_pane()?.is_fullscreen {
                true => current_pane_geometry.center(),
                false => match self.get_current_cursor() {
                    Some(cursor) => cursor,
                    None => current_pane_geometry.center(),
                },
            };

            for pane in &opposing_panes {
                let target = Rect::from_pane(pane);

                let is_aligned = match direction {
                    Direction::Left | Direction::Right => {
                        target.y <= origin.y && origin.y < target.bottom()
                    }
                    Direction::Up | Direction::Down => {
                        target.x <= origin.x && origin.x < target.right()
                    }
                };

                if is_aligned {
                    result = Some(pane);
                    break;
                }
            }

            result
        };

        let Some(target) = wrap_target else {
            return Err(MoveCursorError::ReachedUnreachableCodePath(
                "Failed to pick a wrap target out of multiple valid panes.",
            ));
        };

        self.focus_terminal_pane(target.id)
    }

    fn candidate_exists(&self, direction: Direction) -> Result<bool, MoveCursorError> {
        let origin = self.get_current_pane_geometry()?;
        for pane in self.pane_candidates()? {
            let target = Rect::from_pane(pane);

            let in_direction = match direction {
                Direction::Left => target.is_left_of(&origin),
                Direction::Right => target.is_right_of(&origin),
                Direction::Up => target.is_above(&origin),
                Direction::Down => target.is_under(&origin),
            };

            // The target pane must align on the secondary axis to be a valid candidate
            let is_aligned = match direction.is_horizontal() {
                true => origin.rows_overlap(&target),
                false => origin.cols_overlap(&target),
            };

            if in_direction && is_aligned {
                return Ok(true);
            }
        }

        Ok(false)
    }

    pub fn move_or_split(
        &self,
        direction: Direction,
        tab_behavior: TabBehavior,
    ) -> Result<(), MoveCursorError> {
        if self.is_blocked_by_fullscreen()? {
            return Ok(());
        }

        if tab_behavior == TabBehavior::Move && self.tabs.len() > 1 {
            return self.move_focus_or_tab(direction);
        }

        if self.candidate_exists(direction)? {
            return self.move_focus(direction);
        }

        utils::new_pane(direction);

        Ok(())
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TabBehavior {
    Stop,
    Move,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct Rect {
    x: isize,
    y: isize,
    cols: isize,
    rows: isize,
}

impl Rect {
    pub fn from_pane(pane: &PaneInfo) -> Rect {
        Rect {
            x: pane.pane_x as isize,
            y: pane.pane_y as isize,
            cols: pane.pane_columns as isize,
            rows: pane.pane_rows as isize,
        }
    }

    pub fn right(&self) -> isize {
        self.x + self.cols
    }

    pub fn bottom(&self) -> isize {
        self.y + self.rows
    }

    pub fn is_left_of(&self, rect: &Rect) -> bool {
        self.x < rect.x
    }

    pub fn is_right_of(&self, rect: &Rect) -> bool {
        self.x > rect.x
    }

    pub fn is_under(&self, rect: &Rect) -> bool {
        self.y > rect.y
    }

    pub fn is_above(&self, rect: &Rect) -> bool {
        self.y < rect.y
    }

    pub fn cols_overlap(&self, rect: &Rect) -> bool {
        self.x < rect.right() && rect.x < self.right()
    }

    pub fn rows_overlap(&self, rect: &Rect) -> bool {
        self.y < rect.bottom() && rect.y < self.bottom()
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct Point {
    x: isize,
    y: isize,
}
