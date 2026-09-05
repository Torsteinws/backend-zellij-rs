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

return M
