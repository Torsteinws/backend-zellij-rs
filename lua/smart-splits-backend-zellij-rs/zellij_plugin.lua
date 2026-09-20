local zellij = require('smart-splits-backend-zellij-rs.zellij')
local config = require('smart-splits-backend-zellij-rs.config')

local zellij_plugin = {}

local function repo_path()
    local current_file = debug.getinfo(1, 'S').source:sub(2)
    return vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(current_file)))
end

---@type string|nil
local _plugin_url = nil

--- Find the name of the plugin
---@return string|nil
local function plugin_url()
    if _plugin_url ~= nil then
        return _plugin_url
    end

    local repo = repo_path()

    local release_build = repo .. '/rust/target/wasm32-wasip1/release/smart-splits-backend-zellij-rs.wasm'
    local debug_build = repo .. '/rust/target/wasm32-wasip1/debug/smart-splits-backend-zellij-rs.wasm'

    local release_stat = vim.uv.fs_stat(release_build)
    local debug_stat = vim.uv.fs_stat(debug_build)

    -- If both release and debug build exists, pick whichever was most recently modified.
    if release_stat and debug_stat then
        if release_stat.mtime.sec >= debug_stat.mtime.sec then
            _plugin_url = 'file:' .. release_build
            return _plugin_url
        else
            _plugin_url = 'file:' .. debug_build
            return _plugin_url
        end
    end

    if release_stat then
        _plugin_url = 'file:' .. release_build
        return _plugin_url
    end

    if debug_stat then
        _plugin_url = 'file:' .. debug_build
        return _plugin_url
    end

    return nil
end

zellij_plugin.is_running = false

function zellij_plugin.start_or_reload()
    local result = vim.system({ 'zellij', 'action', 'start-or-reload-plugin', plugin_url() }):wait(1000)
    zellij_plugin.is_running = result.code == 0
    return zellij_plugin.is_running
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

    print(plugin_url())
    local cmd = { zellij.bin_name(), 'action', 'pipe', '--plugin', plugin_url(), '--name', cmd_name }

    cmd_opts = cmd_opts or {}
    if #cmd_opts > 0 then
        local cmd_opts_str = table.concat(cmd_opts, ',')
        vim.list_extend(cmd, { '--args', cmd_opts_str })
    end

    if payload ~= nil then
        vim.list_extend(cmd, { '--', payload })
    end

    local result = vim.system(cmd, opts):wait(1000)
    return result.stdout or '', result.code, result.stderr or ''
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
