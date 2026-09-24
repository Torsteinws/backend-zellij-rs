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

local function activate()
    local zellij_plugin = require('smart-splits-backend-zellij-rs.zellij_plugin')
    local ok, result = pcall(zellij_plugin.start)
    if not ok then
        vim.notify('FATAL: Failed to start internal zellij plugin.\nReason:' .. tostring(result), vim.log.levels.ERROR)
    end
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
    activate = activate,
}

return M
