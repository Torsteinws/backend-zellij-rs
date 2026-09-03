local M = {}

--- Cached path to the Zellij binary.
---@type string|nil
local _zellij_bin = nil

--- Finds the name of the Zellij binary.
---@return string|nil bin_name The name of the Zellij executable, or nil if not found.
function M.zellij_bin()
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

---@param args string[] command arguments
---@return string stdout
---@return integer code exit code
---@return string stderr
function M.zellij_exec(args)
    if #args == 0 then
        error('No command provided')
    end

    local zellij = M.zellij_bin()
    local cmd = vim.list_extend({ zellij }, args)
    local result = vim.system(cmd, { text = true }):wait()
    return result.stdout or '', result.code, result.stderr or ''
end

return M
