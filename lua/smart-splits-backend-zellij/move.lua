local utils = require('smart-splits-backend-zellij.utils')
local zellij = require('smart-splits-backend-zellij.zellij')
local config = require('smart-splits-backend-zellij.config')

local M = {}

---@param direction SmartSplitsDirection
---@return boolean did_move
local function move_focus_or_tab_or_wrap(direction)
    local panes = zellij.list_panes()

    -- If move_focus_or_tab is true, and there exists multiple tabs, we don't care about wraping.
    if config.options.move_focus_or_tab == true and (direction == 'left' or direction == 'right') then
        for _, pane in ipairs(panes) do
            if pane.tab_position > 0 then
                return zellij.move_focus_or_tab(direction)
            end
        end
    end

    -- Find current pane
    local current_pane ---@type ZellijTerminalPane|nil
    local current_pane_id = tonumber(vim.env.ZELLIJ_PANE_ID)
    for _, pane in ipairs(panes) do
        if pane.id == current_pane_id and pane.is_plugin == false then
            current_pane = pane
            break
        end
    end
    if current_pane == nil then
        return false -- TODO: Throw error?
    end

    -- Find panes in current tab
    local candidates = {} ---@type ZellijTerminalPane[]
    for _, pane in ipairs(panes) do
        if
            pane.tab_id == current_pane.tab_id
            and pane ~= current_pane
            and pane.is_plugin == false
            and pane.is_floating == false
            and pane.is_selectable == true
        then
            table.insert(candidates, pane)
        end
    end
    if #candidates == 0 then
        return false -- Nothing to do, no other panes in tab
    end

    -- Check if we can do a normal move instead of a wrap around
    local origin = current_pane
    for _, target in ipairs(candidates) do
        local delta = 0

        if direction == 'left' then
            delta = origin.pane_x - target.pane_x
        elseif direction == 'right' then
            delta = target.pane_x - origin.pane_x
        elseif direction == 'up' then
            delta = origin.pane_y - target.pane_y
        elseif direction == 'down' then
            delta = target.pane_y - origin.pane_y
        end

        if delta > 0 then
            return zellij.move_focus(direction)
        end
    end

    -- Find all panes that borders the diametrical opposing edge
    local opposing_panes = {} --@type ZellijTerminalPane[]
    local largest_delta = 0
    local wrap_direction = utils.reverse(direction)
    for _, target in ipairs(candidates) do
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

    if #opposing_panes == 0 then
        return false -- TODO: Should not happen. Throw error?
    end

    if #opposing_panes == 1 then
        return zellij.focus_pane_id(opposing_panes[1].id)
    end

    -- We now have multiple panes to choose from. Each are equidistant from the current pane.
    -- Let's pick the pane that has the smallest curssor distance on the pependicular axis.
    local cursor_x = current_pane.pane_x + current_pane.cursor_coordinates_in_pane[1]
    local cursor_y = current_pane.pane_y + current_pane.cursor_coordinates_in_pane[2]
    local best_pane ---@type ZellijTerminalPane
    local smallest_delta = 99999999999
    for _, target in ipairs(opposing_panes) do
        local delta = 99999999999
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

    if best_pane == nil then
        return false -- TODO: Should not happen. Trow error?
    end

    return zellij.focus_pane_id(best_pane.id)
end

---@type SmartSplitsBackendMove
function M.move(direction, opts)
    if opts.wrap == true then
        return move_focus_or_tab_or_wrap(direction)
    elseif config.options.move_focus_or_tab == true then
        zellij.move_focus_or_tab(direction)
        return true
    else
        zellij.move_focus(direction)
        return true
    end
end

return M
