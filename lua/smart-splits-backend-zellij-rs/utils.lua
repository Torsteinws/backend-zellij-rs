local M = {}

local opposite_directions = {
    left = 'right',
    right = 'left',
    up = 'down',
    down = 'up',
}

function M.reverse(direction)
    return opposite_directions[direction]
end

local bugreport_url = 'https://github.com/smart-splits-nvim/smart-splits-backend-zellij-rs/issues'
function M.assert(condition, message)
    assert(
        condition,
        string.format('%s\nThis should never happen. Please create a bugreport at:\n%s', message, bugreport_url)
    )
end

function M.error(message)
    M.assert(false, message)
end

---@param path string
---@return string|nil content
---@return string|nil error
function M.read_file(path)
    local file = io.open(path, 'r')
    if not file then
        return nil, 'Could not open file: ' .. path
    end

    local content = file:read('*a')
    file:close()

    return content
end

---@return string path Absolute path to this repository
function M.repo_path()
    local current_file = debug.getinfo(1, 'S').source:sub(2)
    return vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(current_file)))
end

---@return string|nil version
function M.backend_version()
    local version_file = vim.fs.abspath(vim.fs.joinpath(M.repo_path(), 'VERSION'))
    local version = M.read_file(version_file)
    if version ~= nil then
        return vim.trim(version)
    else
        return nil
    end
end

return M
