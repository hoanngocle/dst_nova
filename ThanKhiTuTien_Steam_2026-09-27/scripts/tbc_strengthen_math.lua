local M = {}

local function Floor(value, decimals)
    local scale = 10 ^ decimals
    return math.floor(value * scale) / scale
end

-- Solo's default (non-increase) weapon mode uses base 4. Most ranged
-- weapons do not gain raw weapon damage, except the two Solo dao-gam forms.
function M.Weapon(base, level, ranged, ranged_exception)
    if type(base) ~= "number" then return nil end
    if level <= 0 or (ranged and not ranged_exception) then return base end
    local raised = 4 * 2 ^ (level / 2)
    return Floor(math.max(raised, base + raised / 2), 1)
end

function M.Armor(base, level)
    if type(base) ~= "number" then return nil end
    if level <= 0 then return base end
    return math.min(0.9999, Floor(base + (1 - base) * (1 + level) / (10 + level), 4))
end

return M
