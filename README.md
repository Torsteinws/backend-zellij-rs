## About

> [!WARNING]
> This is under development and currently broken.

Zellij integration for [smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim), written in rust.

## Install

### Lazy package manager

TODO...

## Configuration

### Default

<!-- > [!WARNING] -->
<!-- > **EXPERIMENTAL** configs are not stable and may break or be removed without warning. -->

```lua
opts = {
  -- General behavior when moving cursor.
  move_cursor = {
    pane_or_tab = false,            -- Go to the next tab when navigating to an edge.
  },

  -- Behavior when at_edge is 'split'
  split = {
    left = true,    -- Whether to create a split when navigating to this edge.
    right = true,
    up = true,
    down = true,
  }

  -- Behavior when zellij is in fullscreen
  fullscreen = {
    block_nav = false,          -- Block navigation if the current pane is fullscreen
    state_after_nav = 'native'  -- **EXPERIMENTAL** Controls fullscreen state after navigation: 'exit', 'keep', or 'native'
                                -- 'exit': Exit fullscreen
                                -- 'keep': Stay in fullscreen
                                -- 'native': automatically picks whichever of the two is fastest and causes the least screen flicker.
  },
}
```

## Lua API

TODO...

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for documentation.
