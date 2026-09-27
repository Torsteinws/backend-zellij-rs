local zellij = require('smart-splits-backend-zellij-rs.zellij')
local config = require('smart-splits-backend-zellij-rs.config')
local utils = require('smart-splits-backend-zellij-rs.utils')

local zellij_plugin = {}

---@param file string
---@return boolean
local function file_exists(file)
    local stat = vim.uv.fs_stat(file)
    return stat ~= nil and stat.type == 'file'
end

local function is_windows()
    return vim.fn.has('win32') == 1
end

local function is_macos()
    return vim.fn.has('mac') == 1
end

function zellij_plugin.online_url()
    local backend_version = tostring(utils.backend_version())
    if backend_version == '' then
        utils.error('Failed to find current version of backend-zellij-rs')
    end
    return 'https://github.com/smart-splits-nvim/backend-zellij-rs/releases/download/v'
        .. backend_version
        .. '/smart-splits-backend-zellij-rs.wasm'
end

--- Tries to resolve the custom url in the user config
---@return string|nil
local function find_config_url()
    local url = vim.trim(config.options.internal_zellij_plugin.url or '')
    if url == '' then
        return nil
    end

    if vim.startswith(url, 'http') then
        return url
    end

    local file_path = nil
    if vim.startswith(url, 'file:') then
        file_path = string.sub(url, #'file:' + 1)
    elseif vim.startswith(url, '/') or vim.startswith(url, '~') then
        file_path = url
    elseif is_windows() and url:match('^%a:[/\\]') then
        file_path = url
    end

    if file_path ~= nil then
        local file = vim.fs.abspath(file_path)
        if file_exists(file) then
            return 'file:' .. file
        else
            error("Bad config. File does not exists.\n --> internal_zellij_plugin.url = '" .. url .. "'")
        end
    end

    -- If we have come this far, the url is probably an alias.
    -- Let's allow it and hope for the best.
    return url
end

--- Walk through a list of well known directories and see if it can find the plugin file.
---@return string|nil
local function guess_url()
    local filename = 'smart-splits-backend-zellij-rs.wasm'

    local known_dirs = {} ---@type string[]

    local zellij_config_dir = vim.trim(vim.env.ZELLIJ_CONFIG_DIR or '')
    if zellij_config_dir ~= '' then
        table.insert(known_dirs, vim.fs.joinpath(zellij_config_dir, 'plugins'))
        table.insert(known_dirs, vim.fs.joinpath(zellij_config_dir))
    end

    local xdg_config_home = vim.trim(vim.env.XDG_CONFIG_HOME or '')
    if xdg_config_home ~= '' then
        table.insert(known_dirs, vim.fs.joinpath(xdg_config_home, 'zellij/plugins'))
        table.insert(known_dirs, vim.fs.joinpath(xdg_config_home, 'zellij'))
    end

    table.insert(known_dirs, '~/.config/zellij/plugins')
    table.insert(known_dirs, '~/.config/zellij')

    if is_macos() then
        table.insert(known_dirs, '~/Library/Application Support/org.Zellij-Contributors.Zellij/plugins')
        table.insert(known_dirs, '~/Library/Application Support/org.Zellij-Contributors.Zellij')
    end

    if is_windows() then
        table.insert(known_dirs, '%APPDATA%\\zellij\\plugins\\')
        table.insert(known_dirs, '%APPDATA%\\zellij\\')
        table.insert(known_dirs, '%APPDATA%\\Roaming\\zellij\\plugins\\')
        table.insert(known_dirs, '%APPDATA%\\Roaming\\zellij\\')
        table.insert(known_dirs, '%LOCALAPPDATA%\\zellij\\plugins\\')
        table.insert(known_dirs, '%LOCALAPPDATA%\\plugins\\')
    end

    if not is_windows() then
        table.insert(known_dirs, '/etc/zellij/plugins')
        table.insert(known_dirs, '/etc/zellij')
    end

    for _, dir in ipairs(known_dirs) do
        local file = vim.fs.abspath(vim.fs.joinpath(dir, filename))
        if file_exists(file) then
            return 'file:' .. file
        end
    end

    return nil
end

--- Find the url of the local build if it exists.
---@return string|nil
local function find_local_build_url()
    local repo = utils.repo_path()

    local release_build = repo .. '/rust/target/wasm32-wasip1/release/smart-splits-backend-zellij-rs.wasm'
    local debug_build = repo .. '/rust/target/wasm32-wasip1/debug/smart-splits-backend-zellij-rs.wasm'

    local release_stat = vim.uv.fs_stat(release_build)
    local debug_stat = vim.uv.fs_stat(debug_build)

    -- If both release and debug build exists, pick whichever was most recently modified.
    if release_stat and debug_stat then
        if release_stat.mtime.sec >= debug_stat.mtime.sec then
            return 'file:' .. release_build
        else
            return 'file:' .. debug_build
        end
    end

    if release_stat then
        return 'file:' .. release_build
    end

    if debug_stat then
        return 'file:' .. debug_build
    end

    return nil
end

---@type string|nil
local _plugin_url = nil

--- Find the name of the plugin
---@return string
function zellij_plugin.url()
    if _plugin_url ~= nil then
        return _plugin_url
    end

    local config_url = find_config_url()
    if config_url ~= nil then
        _plugin_url = config_url
        return _plugin_url
    end

    local local_build_url = find_local_build_url()
    if local_build_url ~= nil then
        _plugin_url = local_build_url
        return _plugin_url
    end

    local guessed_url = guess_url()
    if guessed_url ~= nil then
        _plugin_url = guessed_url
        return _plugin_url
    end

    return zellij_plugin.online_url()
end

--- Execute a command on our custom zellij plugin in /rust
---@param cmd_name string The name of the command in the plugin
---@param payload? string The argument for the command
---@param cmd_opts? string[]
---@param opts? vim.SystemOpts
---@return vim.SystemObj
local function simple_exec(cmd_name, payload, cmd_opts, opts)
    local plugin_url = zellij_plugin.url()
    if plugin_url == nil then
        error('FATAL: Did not find a valid url for the internal zellij plugin.')
    end

    local cmd = { zellij.bin_name(), 'action', 'pipe', '--plugin', plugin_url, '--name', cmd_name }

    cmd_opts = cmd_opts or {}
    if #cmd_opts > 0 then
        local cmd_opts_str = table.concat(cmd_opts, ',')
        vim.list_extend(cmd, { '--args', cmd_opts_str })
    end

    if payload ~= nil then
        vim.list_extend(cmd, { '--', payload })
    end

    return vim.system(cmd, opts)
end

function zellij_plugin.start()
    -- NOTE: This function may look messy, but it has intentionally been written like this to avoid a bunch of edge cases
    --       I'd advise against trying to refactor it before you understand all the edge cases it works around.

    -- Launch the plugin if it is not already running.
    -- Launching it like this will ensure it is rendered as as floating.
    -- This is nice if the plugin needs to ask the user for permission to run.
    simple_exec('version', nil, nil, { timeout = 50 })
    simple_exec('version', 'dummy-palyod', nil, { text = true }):wait(300)

    -- Now that the plugin is floating, let's restart it to force a clean slate.
    -- This improves stabiliy for end user. It prevents the plugin from ever being in a broken state when nvim launches.
    zellij_plugin.start_or_reload():wait(300)

    -- Warm up the plugin.
    -- We need to do this because the first call may not write to stdout.
    -- This is a known limitation in zellij v0.45.1
    simple_exec('version', nil, nil, { timeout = 100 })

    -- For some reason, we need to add a dummy paylod. Zellij may decide to not wait for the rust plugin to write to stdout if payload is empty.
    local result = simple_exec('version', 'dummy-palyod', nil, { text = true }):wait(300)
    local version = vim.trim(tostring(result.stdout))
    local is_fully_loaded = version ~= ''

    if not is_fully_loaded then
        -- Plugin asks the user to grant it permission to run. Make sure permissions form is visible.
        zellij.show_floating_panes()
        return
    end

    local backend_version = tostring(utils.backend_version())
    if version ~= backend_version then
        local msg = string.format(
            [[
Version mismatch: 
    - Smart splits backend version: %s
    - Custom zellij plugin version: %s
Consider updating either of the two.]],
            backend_version,
            version
        )
        vim.notify(msg, vim.log.levels.WARN)
    end
end

--- Execute a command on our custom zellij plugin in /rust
---@param cmd_name string The name of the command in the plugin
---@param payload? string The argument for the command
---@param cmd_opts? string[]
---@param opts? vim.SystemOpts
---@return string stdout
---@return integer code exit code
---@return string stderr
function zellij_plugin.exec(cmd_name, payload, cmd_opts, opts)
    opts = opts or { text = false }

    local plugin_url = zellij_plugin.url()
    if plugin_url == nil then
        error('FATAL: Did not find a valid url for the internal zellij plugin.')
    end

    local cmd = { zellij.bin_name(), 'action', 'pipe', '--plugin', plugin_url, '--name', cmd_name }

    cmd_opts = cmd_opts or {}
    if #cmd_opts > 0 then
        local cmd_opts_str = table.concat(cmd_opts, ',')
        vim.list_extend(cmd, { '--args', cmd_opts_str })
    end

    if payload ~= nil then
        vim.list_extend(cmd, { '--', payload })
    end

    local result = vim.system(cmd, opts):wait(400)

    local stdout = vim.trim(result.stdout or '')
    local stderr = vim.trim(result.stderr or '')

    if vim.startswith(stdout, 'ERROR:') then
        error('Encountered error in internal zellij plugin.\n    ' .. stdout)
    end

    if vim.startswith(stdout, 'PANIC!') then
        -- Plugin panicked. It's now in a broken state and needs to be restarted.
        zellij_plugin.start_or_reload()

        local panic_message = vim.trim(stdout:sub(#'PANIC!' + 1))
        if panic_message ~= '' then
            error('Panic in internal zellij plugin.\nReason: ' .. panic_message)
        else
            error('Panic in internal zellij plugin.')
        end
    end

    return stdout, result.code, stderr
end

---@return vim.SystemObj
function zellij_plugin.start_or_reload()
    return vim.system({ zellij.bin_name(), 'action', 'start-or-reload-plugin', zellij_plugin.url() })
end

---@param opts? vim.SystemOpts
---@return string
function zellij_plugin.version(opts)
    local options = vim.tbl_deep_extend('force', { text = true }, opts or {})

    -- For some reason, zellij will not wait for the rust plugin to write to stdout if payload is empty.
    -- We must therefore include a dummy payload
    local version = zellij_plugin.exec('version', 'dummy-payload', options)
    return vim.trim(version)
end

---@type string[]|nil
local _default_options = nil

---@return string[]
local function default_options()
    if _default_options ~= nil then
        return _default_options
    end

    _default_options = {}
    if config.options.fullscreen.block_nav == true then
        vim.list_extend(_default_options, { 'ignore-if-fullscreen=true' })
    end

    if config.options.fullscreen.state_after_nav ~= 'native' then
        vim.list_extend(_default_options, { 'fullscreen=' .. config.options.fullscreen.state_after_nav })
    end

    return _default_options
end

---@param direction SmartSplitsDirection
function zellij_plugin.move_focus(direction)
    local _, code = zellij_plugin.exec('move-focus', direction, default_options())
    return code == 0
end

---@param direction SmartSplitsDirection
function zellij_plugin.move_focus_or_tab(direction)
    local _, code = zellij_plugin.exec('move-focus-or-tab', direction, default_options())
    return code == 0
end

---@param direction SmartSplitsDirection
function zellij_plugin.move_focus_or_wrap(direction)
    local _, code = zellij_plugin.exec('move-focus-or-wrap', direction, default_options())
    return code == 0
end

---@param direction SmartSplitsDirection
function zellij_plugin.move_focus_or_tab_wrap(direction)
    local _, code = zellij_plugin.exec('move-focus-or-tab-or-wrap', direction, default_options())
    return code == 0
end

---@param direction SmartSplitsDirection
function zellij_plugin.move_focus_or_split(direction)
    local _, code = zellij_plugin.exec('move-focus-or-split', direction, default_options())
    return code == 0
end

---@param direction SmartSplitsDirection
function zellij_plugin.move_focus_or_tab_or_split(direction)
    local _, code = zellij_plugin.exec('move-focus-or-tab-or-split', direction, default_options())
    return code == 0
end

return zellij_plugin
