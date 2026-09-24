local zellij = require('smart-splits-backend-zellij-rs.zellij')
local zellij_plugin = require('smart-splits-backend-zellij-rs.zellij_plugin')

local M = {}

function M.report()
    if zellij.exists() then
        vim.health.ok('Found ' .. zellij.version())
    else
        vim.health.error('zellij not found on PATH')
    end

    if zellij.is_running() then
        vim.health.ok("Found session '" .. vim.env.ZELLIJ_SESSION_NAME .. "'")
    else
        vim.health.error('Not in a zellij session.')
        return
    end

    local plugin_url = zellij_plugin.url()

    if not plugin_url then
        vim.health.error('Custom zellij plugin not found')
        return
    end

    local plugin_version = zellij_plugin.version()
    if plugin_version ~= '' then
        vim.health.ok('Custom zellij plugin is loaded and has permissions to run.')
    else
        vim.health.error(
            'Custom zellij plugin does not have permissions to run. Restart zellij to launch permissions form.'
        )
    end
end

function M.check()
    vim.health.start('backend-zellij')
    M.report()
end

return M
