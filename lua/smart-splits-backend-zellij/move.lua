local utils = require('smart-splits-backend-zellij.utils')
local zellij = require('smart-splits-backend-zellij.zellij')
local config = require('smart-splits-backend-zellij.config')

local M = {}

---@class ZellijState
---@field current_pane? ZellijTerminalPane
---@field panes? ZellijPaneEntry[]
---@field current_tab_panes ZellijTerminalPane[]

---@type ZellijState
local cache = {} ---@diagnostic disable-line: missing-fields

--- Get the current zellij pane
---@return ZellijPaneEntry[]
local function get_all_panes()
    if cache.panes == nil then
        cache.panes = zellij.list_panes()
    end
    return cache.panes
end

--- Get a list of all zellij panes in the current session
---@return ZellijTerminalPane
local function get_current_pane()
    if cache.current_pane ~= nil then
        return cache.current_pane
    end

    local current_pane_id = tonumber(vim.env.ZELLIJ_PANE_ID)
    local panes = get_all_panes()
    for _, pane in ipairs(panes) do
        if pane.id == current_pane_id and pane.is_plugin == false then
            cache.current_pane = pane
            break
        end
    end
    utils.assert(cache.current_pane ~= nil, 'Failed to find the current pane.')

    return cache.current_pane
end

local function get_current_tab_panes()
    if cache.current_tab_panes ~= nil then
        return cache.current_tab_panes
    end

    local panes = get_all_panes()
    local current_pane = get_current_pane()
    cache.current_tab_panes = {} ---@type ZellijTerminalPane[]
    for _, pane in ipairs(panes) do
        if
            pane.tab_id == current_pane.tab_id
            and pane.is_plugin == false
            and pane.is_floating == false
            and pane.is_selectable == true
        then
            table.insert(cache.current_tab_panes, pane)
        end
    end

    return cache.current_tab_panes
end

local function invalidate_cache()
    cache = {} ---@diagnostic disable-line: missing-fields
end

--- Check if interval a = [a_start, a_start + a_length) overlaps
--- interval b = [b_start, b_start + b_length).
---@param a_start integer start coordinate of interval a
---@param a_length integer length of interval a
---@param b_start integer start coordinate of interval b
---@param b_length integer length of interval b
---@return boolean
local function intervals_overlap(a_start, a_length, b_start, b_length)
    local a_end = a_start + a_length
    local b_end = b_start + b_length
    return a_start < b_end and b_start < a_end
end

--- Check if two panes overlap on a given axis.
---@param a ZellijTerminalPane
---@param b ZellijTerminalPane
---@param axis "x-axis"|"y-axis"
---@return boolean
local function axis_overlap(a, b, axis)
    if axis == 'x-axis' then
        return intervals_overlap(a.pane_x, a.pane_columns, b.pane_x, b.pane_columns)
    else
        return intervals_overlap(a.pane_y, a.pane_rows, b.pane_y, b.pane_rows)
    end
end

--- Check if there exists any neighboring panes in the given direction
---@param origin ZellijTerminalPane The origin pane
---@param panes ZellijPaneEntry[] The panes to test
---@param direction SmartSplitsDirection The direction to look
---@return boolean
local function has_neighbor(origin, panes, direction)
    for _, target in ipairs(panes) do
        if
            target.id == origin.id
            or target.tab_id ~= origin.tab_id
            or target.is_plugin == true
            or target.is_floating == true
            or target.is_suppressed == true
        then
            goto continue -- Invalid target, skip
        end

        local in_direction = false -- True if the the pane is in the given direction
        local is_aligned = false -- True if the pane has any overlaping coordinates on the perpendicular axis

        if direction == 'left' then
            in_direction = origin.pane_x > target.pane_x
            is_aligned = axis_overlap(origin, target, 'y-axis')
        elseif direction == 'right' then
            in_direction = target.pane_x > origin.pane_x
            is_aligned = axis_overlap(origin, target, 'y-axis')
        elseif direction == 'up' then
            in_direction = origin.pane_y > target.pane_y
            is_aligned = axis_overlap(origin, target, 'x-axis')
        elseif direction == 'down' then
            in_direction = target.pane_y > origin.pane_y
            is_aligned = axis_overlap(origin, target, 'x-axis')
        end

        if in_direction and is_aligned then
            return true
        end

        ::continue::
    end

    return false
end

---@param direction SmartSplitsDirection
---@return boolean did_move
local function move_or_wrap(direction)
    local current_pane = get_current_pane()
    local panes = get_current_tab_panes()
    if #panes <= 1 then
        return false -- Nothing to do, no other panes in tab
    end

    if has_neighbor(current_pane, panes, direction) then
        return zellij.move_focus(direction)
    end

    -- Find all panes that borders the diametrical opposing edge
    local origin = current_pane
    local opposing_panes = {} --@type ZellijTerminalPane[]
    local largest_delta = 0
    local wrap_direction = utils.reverse(direction)
    for _, target in ipairs(panes) do
        local delta = 0
        if wrap_direction == 'left' then
            delta = origin.pane_x - target.pane_x
        elseif wrap_direction == 'right' then
            delta = target.pane_x + target.pane_columns - origin.pane_x
        elseif wrap_direction == 'up' then
            delta = origin.pane_y - target.pane_y
        elseif wrap_direction == 'down' then
            delta = target.pane_y + target.pane_rows - origin.pane_y
        end

        if delta > largest_delta then
            largest_delta = delta
            opposing_panes = { target }
        elseif delta == largest_delta then
            table.insert(opposing_panes, target)
        end
    end
    utils.assert(#opposing_panes > 0, 'Failed to find an opposing pane.')

    if #opposing_panes == 1 then
        return zellij.focus_pane_id(opposing_panes[1].id)
    end

    -- We now have multiple panes to choose from. Each are equidistant from the current pane.
    -- Let's pick the pane that has the smallest curssor distance on the pependicular axis.
    local cursor_x = current_pane.pane_x + current_pane.cursor_coordinates_in_pane[1]
    local cursor_y = current_pane.pane_y + current_pane.cursor_coordinates_in_pane[2]
    local best_pane ---@type ZellijTerminalPane
    local smallest_delta = 99999
    for _, target in ipairs(opposing_panes) do
        local delta = 99999
        if direction == 'left' or direction == 'right' then
            delta = math.abs(cursor_y - target.pane_y - target.cursor_coordinates_in_pane[2])
        elseif direction == 'up' or direction == 'down' then
            delta = math.abs(cursor_x - target.pane_x - target.cursor_coordinates_in_pane[1])
        end

        if delta < smallest_delta then
            smallest_delta = delta
            best_pane = target
        end
    end
    utils.assert(best_pane ~= nil, 'Failed to pick the best pane out of multiple options')

    return zellij.focus_pane_id(best_pane.id)
end

---@param direction SmartSplitsDirection
---@return boolean
local function split_and_focus(direction)
    local current_pane = get_current_pane()

    -- Split does not work with fullscreen - it messes up the coordinates of the panes.
    -- This is possibly a bug in zellij v0.45.0
    if current_pane.is_fullscreen == true then
        zellij.toggle_fullscreen()
        invalidate_cache()
        current_pane = get_current_pane()
    end

    local panes = get_current_tab_panes()
    if has_neighbor(current_pane, panes, direction) then
        return zellij.move_focus(direction)
    end

    if direction == 'right' then
        return zellij.new_pane('right') ~= nil
    elseif direction == 'down' then
        return zellij.new_pane('down') ~= nil
    elseif direction == 'left' then
        -- Zellij does not support creating panes to the left.
        -- We must create one to the right and then swap position.
        local new_pane_id = zellij.new_pane('right')
        return new_pane_id ~= nil and zellij.move_pane('left', new_pane_id)
    elseif direction == 'up' then
        -- Same as above. Create new pane down, then swap
        local new_pane_id = zellij.new_pane('down')
        return new_pane_id ~= nil and zellij.move_pane('up', new_pane_id)
    else
        assert(false, 'Failed to split pane.') -- We should never arrive here.
        return false
    end
end

local function try_move_or_tab(direction)
    local panes = get_all_panes()
    -- we can only move to the next tab if the navigation is in a horizontal direction
    -- and if the current session has more than 1 tabs.
    if direction == 'left' or direction == 'right' then
        for _, pane in ipairs(panes) do
            if pane.tab_position > 0 then
                return zellij.move_focus_or_tab(direction)
            end
        end
    end
    return false
end

local last_move_time = 0

---@type SmartSplitsBackendMove
local function move(direction, opts)
    if config.options.disable_nav_when_zoomed == true and get_current_pane().is_fullscreen == true then
        return false
    end

    local move_or_tab = config.options.move_focus_or_tab == true

    if opts.at_edge == 'wrap' then
        -- We need to be careful about when we call `try_move_focus_or_tab`.
        -- It fetches (and caches) the current zellij layout – which is performance expensive.
        -- However, the wrap function also needs to fetch the current zellij layout.
        -- It will hit the cache and neglect the performance cost.
        if move_or_tab and try_move_or_tab(direction) then
            return true
        else
            return move_or_wrap(direction)
        end
    end

    -- Split causes a bunch of side effect to the zellij state.
    -- This gets difficult to mannage if the user spams the navigations keys.
    -- We avoid a plethora of edge casess by just not allowing split to be called if
    -- there is less than 500 ms since the last key press.
    if opts.at_edge == 'split' and vim.uv.now() - last_move_time > 500 then
        if move_or_tab and try_move_or_tab(direction) then
            return true
        else
            return split_and_focus(direction)
        end
    end

    if move_or_tab then
        return zellij.move_focus_or_tab(direction) -- Fast move - fire and forget
    end

    return zellij.move_focus(direction) -- Fast move - fire and forget
end

---@type SmartSplitsBackendMove
function M.try_move(direction, opts)
    invalidate_cache()
    local ok, result = pcall(move, direction, opts)
    invalidate_cache()
    if not ok then
        vim.notify(tostring(result), vim.log.levels.ERROR)
        return false
    end
    last_move_time = vim.uv.now()
    return result
end

return M
