## About

> [!WARNING]
> This is under active development and highly unstable. Breaking changes will occur without warning.

Zellij integration for [smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim), written in rust.

## Install

### Prerequisite

Install and configure [vim-zellij-navigator](https://github.com/hiasr/vim-zellij-navigator).

<details>
<summary><strong>TLDR:</strong> Put this in your zellij config.</summary>

```kdl
// ~/.config/zellij/config.kdl
keybinds {
  shared {
    bind "Ctrl h" {
      MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
        name "move_focus";
        payload "left";

        // Plugin Configuration
        move_mod "ctrl"; // Optional, should be added on every move command if changed.
        use_arrow_keys "false"; // Optional, uses arrow keys instead of hjkl. Should be added to every command where you want to use it.
      };
    }

    bind "Ctrl j" {
      MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
        name "move_focus";
        payload "down";

        move_mod "ctrl";
        use_arrow_keys "false";
      };
    }

    bind "Ctrl k" {
      MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
        name "move_focus";
        payload "up";

        move_mod "ctrl";
        use_arrow_keys "false";
      };
    }

    bind "Ctrl l" {
      MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
        name "move_focus_or_tab";
        payload "right";

        move_mod "ctrl"; // Optional, should be added on every command if you want to use it
        use_arrow_keys "false";
      };
    }

    bind "Alt h" {
      MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
        name "resize";
        payload "left";

        resize_mod "alt";
      };
    }

    bind "Alt j" {
      MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
        name "resize";
        payload "down";

        resize_mod "alt";
      };
    }

    bind "Alt k" {
      MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
        name "resize";
        payload "up";

        resize_mod "alt";
      };
    }

    bind "Alt l" {
      MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
        name "resize";
        payload "right";

        resize_mod "alt";
      };
    }
  }
}

```

2. Verify that it works: launch a new zellij session and test that each keybinding works.

</details>

### Lazy package manager

```lua
{
  "smart-splits-nvim/smart-splits.nvim",
  branch = "v3",
  opts = {
    mux = {
      backend = "smart-splits-backend-zellij-rs",
    },
  },
  dependencies = {
    {
      "smart-splits-nvim/backend-zellij-rs",
      opts = {
        -- Add zellij specific configuration here
      },
    },
  },
}
```

### [Optional] Manually download precompiled binary

**Not recommended**: The zellij plugin risks getting out of sync with the nvim plugin. It requires you to handle updates manually.

<details>
<summary><strong>See steps</strong></summary>

1. Download [smart-splits-backend-zellij-rs.wasm](https://github.com/Torsteinws/zellij-idempotent-fullscreen/releases/latest/download/smart-splits-backend-zellij-rs.wasm). Put the file in your zellij plugins directory, typically `~/.config/zellij/plugins/`

2. Configure smart splits backend to use the local file. Pin backend version to keep it in sync with local file.

```lua
{
  "smart-splits-nvim/backend-zellij-rs",
  version = "v0.1.0",
  opts = {
    -- Config for the internal zellij plugin
    internal_zellij_plugin = {
      url = "file:/home/my-user/.config/zellij/plugins/smart-splits-backend-zellij-rs.wasm",
    },
  }
}
```

3. Verify that the local version is in use. Start nvim and run `checkhealth smart-splits`.

</details>

### [Optional] Build from source

**Not recommended**: Same as above, requires you to handle updates manually.

<details>
<summary><strong>See build steps</strong></summary>

1. Build zellij plugin

```console
git clone https://github.com/smart-splits-nvim/backend-zellij-rs
cd backend-zellij-rs/rust
cargo build --release
```

2. Move plugin to zellij plugin directory. The location of the plugin directory depends on your OS and your environment.

The following should work on most linux systems:

```console
mkdir -p ~/.config/zellij/plugins/
mv target/wasm32-wasip1/release/smart-splits-backend-zellij-rs.wasm ~/.config/zellij/plugins/
```

3. Configure smart splits backend to use the local file. Pin backend version to keep it in sync with local file.

```lua
{
  "smart-splits-nvim/backend-zellij-rs",
  version = "v0.1.0",
  opts = {
    -- Config for the internal zellij plugin
    internal_zellij_plugin = {
      url = "file:/home/my-user/.config/zellij/plugins/smart-splits-backend-zellij-rs.wasm",
    },
  }
}
```

4. Verify that the local version is in use. Start nvim and run `checkhealth smart-splits`.

</details>

### Configure nvim keybindings

Configure nvim to use the same keybindings as you previously configured for [vim-zellij-navigator](https://github.com/hiasr/vim-zellij-navigator).

```lua
-- moving between splits
vim.keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left)
vim.keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down)
vim.keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up)
vim.keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right)

-- resizing splits, these accept a count, so `10<A-h>` resizes by 10 * config.resize.amount
vim.keymap.set('n', '<A-h>', require('smart-splits').resize_left)
vim.keymap.set('n', '<A-j>', require('smart-splits').resize_down)
vim.keymap.set('n', '<A-k>', require('smart-splits').resize_up)
vim.keymap.set('n', '<A-l>', require('smart-splits').resize_right)
```

## Configuration

### Default

```lua
opts = {
  -- General behavior when moving cursor.
  move_cursor = {
    -- Go to the next tab when navigating to an edge.
    pane_or_tab = false,
  },

  -- Behavior when at_edge is 'split'
  split = {
    -- Which edges may create a zellij split
    left = true,
    right = true,
    up = true,
    down = true,
  }

  -- Behavior when zellij is in fullscreen
  fullscreen = {
    -- Refuse navigation and resize.
    block_nav = false,

    -- Change fullscreen state after navigation: 'exit', 'keep', or 'native'
    --   'exit': Exit fullscreen
    --   'keep': Stay in fullscreen
    --   'native': Let zellij dynamically decide which of the two is best.
    state_after_nav = 'native'
  },

  -- Config for the internal zellij plugin
  internal_zellij_plugin = {

    -- Path to the internal plugin that zellij should load
    -- Useful if you want to build the plugin from source.
    -- Follows the zellij plugin url schema: https://zellij.dev/documentation/plugin-loading.html#plugin-url-schema
    -- If nil, use plugin located in config folder or precompiled binary.
    url = nil,
  },
}
```

## Troubleshooting

Check health of plugin:

```
:checkhealth smart-splits
```

## Lua API

Not yet supported. Come back here later.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for documentation.
