local zellij = {}

--- Cached path to the Zellij binary.
---@type string|nil
local _zellij_bin = nil

--- Find the name of the Zellij binary.
---@return string|nil bin_name The name of the Zellij executable, or nil if not found.
function zellij.bin_name()
    if _zellij_bin ~= nil then
        return _zellij_bin
    end

    if vim.fn.executable('zellij') == 1 then
        _zellij_bin = 'zellij'
        return _zellij_bin
    end

    if vim.fn.executable('zellij.exe') == 1 then
        _zellij_bin = 'zellij.exe'
        return _zellij_bin
    end

    return nil
end

--- Checks if zellij exists in path
--- @return boolean
function zellij.exists()
    return zellij.bin_name() ~= nil
end

--- Check if zellij is currently running
--- @return boolean
function zellij.is_running()
    return vim.env.ZELLIJ ~= nil and #vim.env.ZELLIJ > 0
end

--- Execute a command with zellij
---@param args (string|integer)[] command arguments
---@param opts? vim.SystemOpts
---@return string stdout
---@return integer code exit code
---@return string stderr
function zellij.exec(args, opts)
    if #args == 0 then
        error('No command provided')
    end
    opts = opts or { text = false }

    local cmd = vim.list_extend({ zellij.bin_name() }, args)
    local result = vim.system(cmd, opts):wait()
    return result.stdout or '', result.code, result.stderr or ''
end

---@param direction SmartSplitsDirection
---@return boolean exit_status True if exit code is 0
function zellij.move_focus(direction)
    local _, code = zellij.exec({ 'action', 'move-focus', direction })
    return code == 0
end

---@param direction SmartSplitsDirection
---@return boolean exit_status True if exit code is 0
function zellij.move_focus_or_tab(direction)
    if direction == 'left' or direction == 'right' then
        local _, code = zellij.exec({ 'action', 'move_focus_or_tab', direction })
        return code == 0
    else
        return zellij.move_focus(direction)
    end
end

---@param pane_id integer|string
---@return boolean exit_status True if exit code is 0
function zellij.focus_pane_id(pane_id)
    local _, code = zellij.exec({ 'action', 'focus-pane-id', pane_id })
    return code == 0
end

--- Creates a new pane in the given direction
---@param direction 'right'|'down' Zellij only creates panes right or down
---@return boolean exit_status True if exit code is 0
function zellij.new_pane(direction)
    local _, code = zellij.exec({ 'action', 'new-pane', '--direction', direction })
    return code == 0
end

--- Moves the current pane in the given direction
---@param direction SmartSplitsDirection
---@return boolean exit_status True if exit code is 0
function zellij.move_pane(direction)
    local _, code = zellij.exec({ 'action', 'move-pane', direction })
    return code == 0
end

---@class ZellijPane
---@field id integer Pane id (unique per pane/plugin type)
---@field is_plugin boolean
---@field is_focused boolean
---@field is_fullscreen boolean
---@field is_floating boolean
---@field is_suppressed boolean
---@field title string
---@field exited boolean
---@field exit_status integer|nil
---@field is_held boolean
---@field pane_x integer
---@field pane_content_x integer
---@field pane_y integer
---@field pane_content_y integer
---@field pane_rows integer
---@field pane_content_rows integer
---@field pane_columns integer
---@field pane_content_columns integer
---@field cursor_coordinates_in_pane [integer, integer]|nil     Cursor position in the pane, nil if not applicable
---@field terminal_command string|nil                           Command running in a terminal pane
---@field plugin_url string|nil                                 WASM plugin URL (e.g. "zellij:strider" or "file:/path/to/plugin.wasm")
---@field is_selectable boolean                                 False for non-interactive UI elements like the status/tab bar
---@field index_in_pane_group table<string, integer>            Client-id (stringified) -> index, for panes staged in a group; empty table when not grouped
---@field default_fg string|nil                                 Hex ("#00e000") or rgb ("rgb:00/e0/00") foreground override
---@field default_bg string|nil                                 Hex or rgb background override
---@field tab_id integer
---@field tab_position integer
---@field tab_name string
---@field pane_command string|nil
---@field pane_cwd string|nil

---@class ZellijTerminalPane : ZellijPane
---@field is_plugin false
---@field pane_command string
---@field pane_cwd string

---@class ZellijPluginPane : ZellijPane
---@field is_plugin true
---@field plugin_url string

---@alias ZellijPaneEntry ZellijTerminalPane|ZellijPluginPane

---@return ZellijPaneEntry[]
function zellij.list_panes()
    local json, code, stderr = zellij.exec({ 'action', 'list-panes', '--json' }, { text = true })
    if code ~= 0 then
        error("'zellij action list-panes --json' exited with code=" .. code .. '\n' .. stderr)
    end

    return vim.json.decode(json, { luanil = { object = true } })
end

return zellij
