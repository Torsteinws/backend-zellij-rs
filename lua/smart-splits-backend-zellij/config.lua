local M = {}

---@class SmartSplits.Zellij.Config
---@field move_focus_or_tab boolean

-- Same as above, but every field is nullable
---@class SmartSplits.Zellij.PartialConfig
---@field move_focus_or_tab? boolean

---@type SmartSplits.Zellij.Config
M.defaults = {
    move_focus_or_tab = false,
}

---@type SmartSplits.Zellij.Config
M.options = vim.deepcopy(M.defaults)

---@param opts? SmartSplits.Zellij.PartialConfig
function M.setup(opts)
    opts = opts or {}
    M.options = vim.tbl_deep_extend('force', M.defaults, opts)
    return M.options
end

return M
