local zellij = {}

--- Cached path to the Zellij binary.
---@type string|nil
local _zellij_bin = nil

--- Find the name of the Zellij binary.
---@return string|nil bin_name The name of the Zellij executable, or nil if not found.
function zellij.bin_name()
    if _zellij_bin ~= nil then
        return _zellij_bin
    end

    if vim.fn.executable('zellij') == 1 then
        _zellij_bin = 'zellij'
        return _zellij_bin
    end

    if vim.fn.executable('zellij.exe') == 1 then
        _zellij_bin = 'zellij.exe'
        return _zellij_bin
    end

    return nil
end

--- Checks if zellij exists in path
--- @return boolean
function zellij.exists()
    return zellij.bin_name() ~= nil
end

--- Check if zellij is currently running
--- @return boolean
function zellij.is_running()
    return vim.env.ZELLIJ ~= nil and #vim.env.ZELLIJ > 0
end

--- Execute a command with zellij
---@param args (string|integer)[] command arguments
---@param opts? vim.SystemOpts
---@return string stdout
---@return integer code exit code
---@return string stderr
function zellij.exec(args, opts)
    if #args == 0 then
        error('No command provided')
    end
    opts = opts or { text = false }

    local cmd = vim.list_extend({ zellij.bin_name() }, args)
    local result = vim.system(cmd, opts):wait()
    return result.stdout or '', result.code, result.stderr or ''
end

--- Get the output of zellij --version
---@return string sdtout
function zellij.version()
    local result = zellij.exec({ '--version' }, { text = true })
    return vim.trim(result)
end

---@param direction SmartSplitsDirection
---@return boolean exit_status True if exit code is 0
function zellij.move_focus(direction)
    local _, code = zellij.exec({ 'action', 'move-focus', direction })
    return code == 0
end

---@param direction SmartSplitsDirection
---@return boolean exit_status True if exit code is 0
function zellij.move_focus_or_tab(direction)
    if direction == 'left' or direction == 'right' then
        local _, code = zellij.exec({ 'action', 'move-focus-or-tab', direction })
        return code == 0
    else
        return zellij.move_focus(direction)
    end
end

return zellij
