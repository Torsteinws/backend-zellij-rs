## About

Zellij integration for [smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim)

## Install

### Lazy package manager

```lua
return {
    "mrjones2014/smart-splits.nvim",
    opts = {
        mux = {
            backend = "smart-splits-backend-zellij",
        },
    },
    dependencies = {
        {
            "smart-splits-nvim/smart-splits-backend-zellij"
            opts = {
                -- Add zellij configuration here
            },
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
