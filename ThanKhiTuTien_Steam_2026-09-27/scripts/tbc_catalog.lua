local Defs = require("tbc_affix/defs")
local Roll = require("tbc_affix/roll")

local M = {}

M.affixes = Defs.by_code

function M.RollAffix(level, rng, eligible)
    return Roll.Choose(level, rng, eligible)
end

return M
