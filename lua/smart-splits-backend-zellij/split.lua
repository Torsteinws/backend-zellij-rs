local utils = require('smart-splits-backend-zellij.utils')
local zellij = require('smart-splits-backend-zellij.zellij')
local config = require('smart-splits-backend-zellij.config')

---@param panes ZellijPaneEntry[]
---@return ZellijTerminalPane
local function find_current_pane(panes)
    local current_id = tonumber(vim.env.ZELLIJ_PANE_ID)
    local current_pane ---@type ZellijTerminalPane
    for _, pane in ipairs(panes) do
        if pane.id == current_id and pane.is_plugin == false then
            current_pane = pane
            break
        end
    end
    utils.assert(current_pane ~= nil, 'Failed to find the current pane.')
    return current_pane
end

---@type SmartStplitsBackendSplit
local function split(direction)
    local panes = zellij.list_panes()
    local current_pane = find_current_pane(panes)

    if config.options.disable_nav_when_zoomed == true then
        if current_pane.is_fullscreen == true then
            return false
        end
    end

    -- Check if we can do a normal move instead of a split
    local origin = current_pane
    for _, target in ipairs(panes) do
        local delta = -99999
        if target == origin or target.tab_id ~= origin.tab_id or target.is_plugin == true then
            -- Invalid target, skip
        elseif direction == 'left' then
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

    if direction == 'right' then
        return zellij.new_pane('right')
    elseif direction == 'down' then
        return zellij.new_pane('down')
    elseif direction == 'left' then
        -- Zellij does not support creating panes to the left.
        -- We must create one to the right and then swap position.
        local ok = zellij.new_pane('right')
        if ok then
            return zellij.move_pane('left')
        end
    elseif direction == 'up' then
        -- Same as above: zellij does not support creating panes above
        local ok = zellij.new_pane('down')
        if ok then
            return zellij.move_pane('up')
        end
    end

    return false
end

return {
    split = split,
}
