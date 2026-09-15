# Rust plugin

## Prerequisites

- [Rust and cargo](https://doc.rust-lang.org/cargo/getting-started/installation.html)
- `wasm32-wasip1` – can be added with `rustup target add wasm32-wasip1`

## Quickstart dev

1. Start zellij
2. Open dev environment in current tab

    ```console
     zellij action override-layout --apply-only-to-active-tab ./zellij.kdl
    ```

The layout has 2 floating panes:

1. The plugin instance.
2. A command pane for building and reloading the plugin. Focus the pane and type enter to run command.
