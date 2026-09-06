--- Set up configurations
---@param opts? SmartSplits.Zellij.PartialConfig
local function setup(opts)
    local config = require('smart-splits-backend-zellij.config')
    config.setup(opts)
end

--- Detect if zellij is available in the current environment
local function detect()
    local zellij = require('smart-splits-backend-zellij.zellij')
    return zellij.is_running() and zellij.exists()
end

---@type SmartSplitsBackend
local M = {
    name = 'smart-splits-backend-zellij',
    protocol_version = 3,
    detect = detect,
    move = require('smart-splits-backend-zellij.move').try_move,
    resize = require('smart-splits-backend-zellij.resize').resize,
    setup = setup,
    split = require('smart-splits-backend-zellij.split').split,
}

return M
