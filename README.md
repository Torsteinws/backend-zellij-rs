## About

Zellij integration for [smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim)

## Install

### Lazy package manager

```lua
return {
  "smart-splits-nvim/smart-splits.nvim",
  branch = "v3",
  opts = {
    mux = {
      backend = "smart-splits-backend-zellij",
    },
  },
  dependencies = {
    {
      "smart-splits-nvim/backend-zellij",
    },
  },
}
```

## Configuration

### Default

```lua

opts = {
    -- Go to the next tab when navigating to an edge.
    move_focus_or_tab = false,

    -- Disable navigation if the pane is zoomed (fullscreen).
    disable_nav_when_zoomed = false,
},

```

## Lua API

TODO...

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for documentation.
