use std::collections::HashSet;

use zellij_tile::prelude::PaneInfo;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Point {
    pub x: isize,
    pub y: isize,
}

impl Point {
    pub fn new(x: isize, y: isize) -> Point {
        Point { x, y }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Rect {
    pub x: isize,
    pub y: isize,
    pub cols: isize,
    pub rows: isize,
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

    pub fn corners(&self) -> [Point; 4] {
        [
            self.top_left(),
            self.top_right(),
            self.bottom_left(),
            self.bottom_right(),
        ]
    }

    pub fn right(&self) -> isize {
        self.x + self.cols
    }

    pub fn bottom(&self) -> isize {
        self.y + self.rows
    }

    pub fn center(&self) -> Point {
        Point::new(self.x + (self.cols / 2), self.y + (self.rows) / 2)
    }

    pub fn top_left(&self) -> Point {
        Point::new(self.x, self.y)
    }

    pub fn top_right(&self) -> Point {
        Point::new(self.right(), self.y)
    }

    pub fn bottom_left(&self) -> Point {
        Point::new(self.x, self.bottom())
    }

    pub fn bottom_right(&self) -> Point {
        Point::new(self.right(), self.bottom())
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

/// Given a grid of rectangles were exactly one rectangle is missing.
/// Find the rectangle that is missing to fill the grid.
///
/// Return None if the missing shape is not a rectangle.
///
pub fn find_missing_rect(perimeter: Rect, existing_rects: &[Rect]) -> Option<Rect> {
    let mut corners: HashSet<Point> = HashSet::new();

    for corner in perimeter.corners() {
        corners.insert(corner);
    }

    for rect in existing_rects {
        for corner in rect.corners() {
            if corners.contains(&corner) {
                corners.remove(&corner);
            } else {
                corners.insert(corner);
            }
        }
    }

    if corners.len() != 4 {
        return None;
    }

    let corners_x: HashSet<isize> = corners.iter().map(|p| p.x).collect();
    let corners_y: HashSet<isize> = corners.iter().map(|p| p.y).collect();
    if corners_x.len() != 2 || corners_y.len() != 2 {
        return None;
    }

    let x0 = *corners_x.iter().min().unwrap();
    let x1 = *corners_x.iter().max().unwrap();
    let y0 = *corners_y.iter().min().unwrap();
    let y1 = *corners_y.iter().max().unwrap();

    let rect = Rect {
        x: x0,
        y: y0,
        cols: x1 - x0,
        rows: y1 - y0,
    };

    // Validate that the 4 points form a rectangle
    let expected: HashSet<Point> = rect.corners().iter().copied().collect();
    if expected != corners {
        return None;
    }

    Some(rect)
}
