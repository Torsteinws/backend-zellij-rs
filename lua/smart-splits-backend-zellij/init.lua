local function detect()
    return vim.env.ZELLIJ ~= nil
end

---@type SmartSplitsBackend
local M = {
    name = 'smart-splits-backend-zellij',
    protocol_version = 3,
    detect = detect,
    move = require('smart-splits-backend-zellij.move').move,
    -- resize = require("smart-splits-backend-zellij.resize").resize,
    -- split = require("smart-splits-backend-zellij.split").split,
}

return M
