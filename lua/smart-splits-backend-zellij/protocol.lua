---@alias SmartSplitsDirection 'left'|'right'|'up'|'down'

---@class SmartSplitsBackendMoveOpts

---@alias SmartSplitsBackendMove fun(direction: SmartSplitsDirection, opts?: SmartSplitsBackendMoveOpts):boolean

---@class SmartSplitsBackendResizeOpts

---@alias SmartSplitsBackendResize fun(direction: SmartSplitsDirection, opts?: SmartSplitsBackendResizeOpts):boolean

---@class SmartSplitsBackendSplitOpts

---@alias SmartStplitsBackendSplit fun(direction: SmartSplitsDirection, opts?: SmartSplitsBackendSplitOpts):boolean

---@class SmartSplitsBackend
---@field name string
---@field protocol_version number
---@field detect fun():boolean
---@field move SmartSplitsBackendMove
---@field resize? SmartSplitsBackendResize
---@field split? SmartStplitsBackendSplit
---@field setup? fun()
---@field health? fun()
