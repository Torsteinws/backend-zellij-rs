local M = {}

---@class SmartSplits.ZellijRS.Config
---@field move_cursor SmartSplits.ZellijRS.Config.Move
---@field fullscreen SmartSplits.ZellijRS.Config.Fullscreen
---@field split SmartSplits.ZellijRS.Config.Split

---@class SmartSplits.ZellijRS.Config.Move
---@field pane_or_tab boolean

---@class SmartSplits.ZellijRS.Config.Split
---@field left boolean
---@field right boolean
---@field up boolean
---@field down boolean

---@class SmartSplits.ZellijRS.Config.Fullscreen
---@field block_nav boolean
---@field state_after_nav 'exit'|'keep'|'native'

-- Same as above, but every field is nullable
---@class SmartSplits.ZellijRS.PartialConfig
---@field move_cursor? SmartSplits.ZellijRS.PartialConfig.Move
---@field fullscreen? SmartSplits.ZellijRS.PartialConfig.Fullscreen
---@field split? SmartSplits.ZellijRS.PartialConfig.Split

---@class SmartSplits.ZellijRS.PartialConfig.Move
---@field pane_or_tab? boolean

---@class SmartSplits.ZellijRS.PartialConfig.Split
---@field left? boolean
---@field right? boolean
---@field up? boolean
---@field down? boolean

---@class SmartSplits.ZellijRS.PartialConfig.Fullscreen
---@field block_nav? boolean
---@field state_after_nav? 'exit'|'keep'|'native'

---@type SmartSplits.ZellijRS.Config
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

---@type SmartSplits.ZellijRS.Config
M.options = vim.deepcopy(M.defaults)

---@param opts? SmartSplits.ZellijRS.PartialConfig
function M.setup(opts)
    opts = opts or {}
    M.options = vim.tbl_deep_extend('force', M.defaults, opts)
    return M.options
end

return M
