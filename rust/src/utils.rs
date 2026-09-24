use std::collections::BTreeMap;
use zellij_tile::prelude::{actions::Action, *};

pub fn write_to_pipe(source: PipeSource, message: &str) {
    if let PipeSource::Cli(pipe_id) = source {
        cli_pipe_output(&pipe_id, &format!("{}\n", message));
    }
}

/// Creates a new pane in the given direction.
///
/// Requires the plugin root to listen for new pane events like this:
/// ```
/// Event::ActionComplete(Action::NewPane { .. }, new_pane_id, context) => {
///     utils::new_pane_callback(new_pane_id, context);
/// }
/// ```
pub fn new_pane(direction: Direction) {
    // Zellij does not support spawning panes up or left.
    // Workaround: Spawn the pane 'down' or 'right', then move the new pane 'up' or 'left' after it has spawned

    let spawn_direction = match direction {
        Direction::Left => Direction::Right,
        Direction::Up => Direction::Down,
        other_direction => other_direction,
    };

    let mut context = BTreeMap::<String, String>::new();
    let direction_str = match direction {
        Direction::Left => "left",
        Direction::Right => "right",
        Direction::Up => "up",
        Direction::Down => "down",
    };
    context.insert("direction".to_string(), direction_str.to_string());

    run_action(
        Action::NewPane {
            direction: Some(spawn_direction),
            pane_name: None,
            start_suppressed: false,
        },
        context,
    );

    // Now we will wait for the event ActionComplete(Action::NewPane) to be triggered.
    // The pane must be spawned before we can try to move it.
}

/// Should be called by plugin root after new_pane(direction) has spawned a new pane. Like this:
/// ```
/// Event::ActionComplete(Action::NewPane { .. }, new_pane_id, context) => {
///     utils::new_pane_callback(new_pane_id, context);
/// }
/// ```
pub fn new_pane_callback(new_pane_id: Option<PaneId>, context: BTreeMap<String, String>) {
    let Some(pane_id) = new_pane_id else { return };

    let Some(diection_str) = context.get("direction") else {
        return;
    };
    let Ok(direction) = diection_str.parse::<Direction>() else {
        return;
    };

    if matches!(direction, Direction::Left | Direction::Up) {
        move_pane_with_pane_id_in_direction(pane_id, direction);
    }
}
