local zellij = require('smart-splits-backend-zellij-rs.zellij')
local config = require('smart-splits-backend-zellij-rs.config')

local M = {}

local last_move_time = 0

--- Entrypoint for fast moves
---@param direction SmartSplitsDirection
---@return boolean
local function handle_native_move(direction)
    local move_or_tab = config.options.move_cursor.pane_or_tab == true
    if move_or_tab then
        return zellij.move_focus_or_tab(direction)
    else
        return zellij.move_focus(direction)
    end
end

--- Entrypoint for normal moves
---@param direction SmartSplitsDirection
---@return boolean
local function handle_normal_move(direction)
    return false
end

--- Entrypoint for split moves
---@param direction SmartSplitsDirection
---@return boolean
local function handle_split(direction)
    if
        (config.options.split.left == false and direction == 'left')
        or (config.options.split.right == false and direction == 'right')
        or (config.options.split.up == false and direction == 'up')
        or (config.options.split.down == false and direction == 'down')
    then
        return handle_normal_move(direction)
    end

    -- Split causes a bunch of side effect to the zellij state.
    -- This gets difficult to mannage if the user spams the navigations keys.
    -- We avoid a plethora of edge casess by just not allowing split to be called if
    -- there is less than 500 ms since the last key press.
    if vim.uv.now() - last_move_time <= 500 then
        return handle_normal_move(direction)
    end

    return false
end

--- Entrypoint for wrap moves
---@param direction SmartSplitsDirection
---@return boolean
local function handle_wrap(direction)
    return false
end

---@type SmartSplitsBackendMove
local function handle_move(direction, opts)
    local is_native_behavior = config.options.fullscreen.block_nav == false
        and config.options.fullscreen.state_after_nav == 'native'

    if opts.at_edge == 'stop' and is_native_behavior then
        return handle_native_move(direction)
    elseif opts.at_edge == 'wrap' then
        return handle_wrap(direction)
    elseif opts.at_edge == 'split' then
        return handle_split(direction)
    else
        return handle_normal_move(direction)
    end
end

---@type SmartSplitsBackendMove
function M.try_move(direction, opts)
    local ok, result = pcall(handle_move, direction, opts)
    if not ok then
        vim.notify(tostring(result), vim.log.levels.ERROR)
        return false
    end
    last_move_time = vim.uv.now()
    return result
end

return M
