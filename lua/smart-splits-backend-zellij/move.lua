local utils = require('smart-splits-backend-zellij.utils')
---
---@type SmartSplitsBackendMove
local function move(direction)
    local _, code = utils.zellij_exec({ 'action', 'move-focus', direction })
    return code == 0
end

return {
    move = move,
}
