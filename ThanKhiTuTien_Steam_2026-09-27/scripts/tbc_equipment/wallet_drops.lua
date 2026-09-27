-- Solo hh_player.DropSpecialGif: 10% common wallet item, plus independent
-- 1% / 30% / 50% rolls for each of the four equipment tools.
local M = {}

local TOOLS = {"ac_refreshStone", "ad_cleanStone"}

function M.Award(player, monster_class, rng)
    local wallet = player ~= nil and player.components ~= nil
        and player.components.tbc_equipment_wallet or nil
    if wallet == nil then return false end
    rng = rng or math.random
    local awarded = false
    local chance = monster_class == "boss" and .5
        or monster_class == "elite" and .3 or .01
    for _, id in ipairs(TOOLS) do
        if rng() <= chance then awarded = wallet:Add(id, 1) or awarded end
    end
    return awarded
end

return M
