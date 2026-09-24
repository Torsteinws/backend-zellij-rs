local zellij = require('smart-splits-backend-zellij-rs.zellij')
local zellij_plugin = require('smart-splits-backend-zellij-rs.zellij_plugin')

local M = {}

function M.report()
    if zellij.exists() then
        vim.health.ok('Found ' .. zellij.version())
    else
        vim.health.error('zellij not found on PATH')
        return
    end

    if zellij.is_running() then
        vim.health.ok("Found session '" .. vim.env.ZELLIJ_SESSION_NAME .. "'")
    else
        vim.health.error('Not in a zellij session.')
        return
    end

    local url_ok, plugin_url = pcall(zellij_plugin.url)
    if not url_ok then
        local err = tostring(plugin_url)
        vim.health.error(err)
        return
    elseif plugin_url == nil then
        vim.health.error(
            'Url to custom zellij plugin was not resolved.\n         Consider changing the config: internal_zellij_plugin.url'
        )
        return
    else
        vim.health.ok(
            "Url to custom zellij plugin seems to be valid.\n      internal_zellij_plugin.url = '" .. plugin_url .. "'"
        )
    end

    local version_ok, plugin_version = pcall(zellij_plugin.version)
    if not version_ok then
        local err = tostring(plugin_version)
        vim.health.error(
            'A fatal error occured when trying to communicate with the internal zellij plugin.\nReason: '
                .. err
                .. '\n Plugin url: '
                .. plugin_url
        )
        return
    elseif plugin_version ~= '' then
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
