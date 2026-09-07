## About

> [!WARNING]
> This is under active development and highly unstable. Breaking changes will occur without warning.

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
      opts = {
        -- Add zellij specific configuration here
      },
    },
  },
}
```

## Configuration

### Default

```lua

opts = {
  move_focus_or_tab = false,        -- Go to the next tab when navigating to an edge.

  disable_nav_when_zoomed = false,  -- Disable navigation if the pane is zoomed (fullscreen).
},

```

## Lua API

TODO...

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for documentation.
