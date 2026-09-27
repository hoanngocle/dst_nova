-- Standalone build intentionally ships the default six sword presentations.
local M = {}

function M.GetEquipPresentation(inst, default_build, default_symbol)
    return default_build, default_symbol
end

return M
