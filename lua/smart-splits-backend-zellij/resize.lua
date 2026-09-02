local utils = require('smart-splits-backend-zellij.utils')

---@type SmartSplitsBackendResize
local function resize(direction)
    local _, code = utils.zellij_exec({ 'action', 'resize', 'increase', direction })
    return code == 0
end

return {
    resize = resize,
}
