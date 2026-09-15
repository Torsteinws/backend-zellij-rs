local zellij = require('smart-splits-backend-zellij-rs.zellij')

---@type SmartSplitsBackendResize
local function resize(direction)
    local _, code = zellij.exec({ 'action', 'resize', 'increase', direction })
    return code == 0
end

return {
    resize = resize,
}
