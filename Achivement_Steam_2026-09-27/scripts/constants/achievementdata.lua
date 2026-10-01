local files = {
    "food",
    "life",
    "hurt",
    "work",
    "have",
    "stat",
    "vile",
    "slay",
    "duel",
    "boss",
    "misc",
    "mile",
    "task",
}

local ach_lists = {}
local removed_achievements = require "constants/removedachievements"

for _, name in ipairs(files) do
    local data = require("constants/achievements/" .. name)
    for k, v in pairs(data) do
        if not removed_achievements[k] then
            ach_lists[k] = v
        end
    end
end

for _, achievement in ipairs(require "constants/novaachievements") do
    assert(ach_lists[achievement.id] == nil, "Duplicate achievement: " .. achievement.id)
    ach_lists[achievement.id] = {
        current = achievement.current,
        coinget = achievement.coinget,
        type = achievement.type,
        persistent = achievement.persistent,
    }
end

return ach_lists
-- dont use FlatIdent
