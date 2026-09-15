--- Set up configurations
---@param opts? SmartSplits.ZellijRS.PartialConfig
local function setup(opts)
    local config = require('smart-splits-backend-zellij-rs.config')
    config.setup(opts)
end

--- Detect if zellij is available in the current environment
local function detect()
    local zellij = require('smart-splits-backend-zellij-rs.zellij')
    return zellij.is_running() and zellij.exists()
end

---@type SmartSplitsBackend
local M = {
    name = 'smart-splits-backend-zellij-rs',
    protocol_version = '3.0.0',
    detect = detect,
    move = require('smart-splits-backend-zellij-rs.move').try_move,
    resize = require('smart-splits-backend-zellij-rs.resize').resize,
    setup = setup,
    health = require('smart-splits-backend-zellij-rs.health').report,
}

return M
