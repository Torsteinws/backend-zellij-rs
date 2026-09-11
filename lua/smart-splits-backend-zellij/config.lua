local M = {}

---@class SmartSplits.Zellij.Config
---@field move_cursor SmartSplits.Zellij.Config.Move
---@field fullscreen SmartSplits.Zellij.Config.Fullscreen
---@field split SmartSplits.Zellij.Config.Split

---@class SmartSplits.Zellij.Config.Move
---@field pane_or_tab boolean

---@class SmartSplits.Zellij.Config.Split
---@field left boolean
---@field right boolean
---@field up boolean
---@field down boolean

---@class SmartSplits.Zellij.Config.Fullscreen
---@field block_nav boolean
---@field state_after_nav 'exit'|'keep'|'native'

-- Same as above, but every field is nullable
---@class SmartSplits.Zellij.PartialConfig
---@field move_cursor? SmartSplits.Zellij.PartialConfig.Move
---@field fullscreen? SmartSplits.Zellij.PartialConfig.Fullscreen
---@field split? SmartSplits.Zellij.PartialConfig.Split

---@class SmartSplits.Zellij.PartialConfig.Move
---@field pane_or_tab? boolean

---@class SmartSplits.Zellij.PartialConfig.Split
---@field left? boolean
---@field right? boolean
---@field up? boolean
---@field down? boolean

---@class SmartSplits.Zellij.PartialConfig.Fullscreen
---@field block_nav? boolean
---@field state_after_nav? 'exit'|'keep'|'native'

---@type SmartSplits.Zellij.Config
M.defaults = {
    move_cursor = {
        pane_or_tab = false,
    },

    split = {
        left = true,
        right = true,
        up = true,
        down = true,
    },

    fullscreen = {
        block_nav = false,
        state_after_nav = 'native',
    },
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
