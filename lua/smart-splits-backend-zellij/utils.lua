local M = {}

---@param args string[] command arguments
---@return string stdout
---@return integer code exit code
---@return string stderr
function M.zellij_exec(args)
    if #args == 0 then
        error('No command provided')
    end

    local cmd = vim.list_extend({ 'zellij' }, args)
    local result = vim.system(cmd, { text = true }):wait()
    return result.stdout or '', result.code, result.stderr or ''
end

return M
