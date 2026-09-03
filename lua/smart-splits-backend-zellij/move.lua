local utils = require('smart-splits-backend-zellij.utils')
local config = require('smart-splits-backend-zellij.config')

---@type SmartSplitsBackendMove
local function move(direction)
    local move_verb = 'move-focus'
    if config.options.move_focus_or_tab == true and (direction == 'left' or direction == 'right') then
        move_verb = 'move-focus-or-tab'
    end

    local _, code = utils.zellij_exec({ 'action', move_verb, direction })
    return code == 0
end

return {
    move = move,
}
