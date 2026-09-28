local M = {}
M.BASE_HEALTH_MULTIPLIERS = { common = 3, elite = 2.5, boss = 2 }

function M.BaseHealthMultiplier(kind)
    return M.BASE_HEALTH_MULTIPLIERS[kind] or M.BASE_HEALTH_MULTIPLIERS.common
end

function M.StrengthenCost(level)
    if type(level) ~= "number" or level < 0 or level >= 16 then return nil end
    return math.floor(level) + 1
end

function M.StrengthenProbability(level, bonus)
    local next_level = M.StrengthenCost(level)
    if next_level == nil then return 0 end
    return math.min(1, 1.1 * (0.85 ^ next_level) + math.max(0, bonus or 0))
end

function M.ResolveStrengthen(level, roll, protect, magic, bonus)
    local next_level = M.StrengthenCost(level)
    if next_level == nil then return level, false, false end
    local probability = M.StrengthenProbability(level, bonus)
    if roll < probability then return next_level, true, false end
    if level < 5 then return level, false, false end
    local destroyed = level >= 9 and not protect
    local preserved = magic and (level < 9 or protect)
    return preserved and level or level - 1, false, destroyed
end

function M.MonsterMultipliers(kind, days)
    local scale = {
        common = { 1.25, 1.15 },
        elite = { 1.5, 1.25 },
        boss = { 1.75, 1.35 },
    }
    local row = scale[kind] or scale.common
    local capped_days = math.min(math.max(days or 0, 0), 200)
    return M.BaseHealthMultiplier(kind) * (row[1] + capped_days * 0.01),
        row[2] + (2 - row[2]) * capped_days / 200
end

function M.RollLoot(kind, rng)
    rng = rng or math.random
    local result = {}
    local function chance(value, prefab)
        if rng() < value then result[#result + 1] = prefab end
    end
    local stone_chance = kind == "boss" and 0.25 or kind == "elite" and 0.05 or 0.01
    if rng() < stone_chance then
        local stone_count = 1
        if kind == "elite" then
            stone_count = rng() < 0.6 and 2 or 3
        elseif kind == "boss" then
            local roll = rng()
            stone_count = roll < 0.4 and 1
                or roll < 0.7 and 2
                or roll < 0.9 and 3 or 4
        end
        for _ = 1, stone_count do
            result[#result + 1] = "hh_effect_stone"
        end
    end

    local crystal_chance = kind == "boss" and 1 or kind == "elite" and 0.5
        or kind == "common" and 0.05 or 0
    if rng() < crystal_chance then
        local roll = rng()
        local prefab, count
        if kind == "common" then
            prefab = roll < 0.8 and "ttk_huyen_tinh_ha_pham" or "ttk_huyen_tinh_trung_pham"
            count = 1
        elseif kind == "elite" then
            if roll < 0.5 then
                prefab, count = "ttk_huyen_tinh_ha_pham", 2
            elseif roll < 0.85 then
                prefab, count = "ttk_huyen_tinh_ha_pham", 3
            elseif roll < 0.95 then
                prefab, count = "ttk_huyen_tinh_trung_pham", 1
            else
                prefab, count = "ttk_huyen_tinh_trung_pham", 2
            end
        else -- boss: the reward percentages total 100%.
            if roll < 0.25 then
                prefab, count = "ttk_huyen_tinh_ha_pham", 3
            elseif roll < 0.5 then
                prefab, count = "ttk_huyen_tinh_trung_pham", 1
            elseif roll < 0.75 then
                prefab, count = "ttk_huyen_tinh_trung_pham", 2
            elseif roll < 0.85 then
                prefab, count = "ttk_huyen_tinh_trung_pham", 3
            elseif roll < 0.95 then
                prefab, count = "ttk_huyen_tinh_thuong_pham", 1
            else
                prefab, count = "ttk_huyen_tinh_thuong_pham", 2
            end
        end
        for _ = 1, count do
            result[#result + 1] = prefab
        end
    end

    if rng() < 0.15 then
        result[#result + 1] = rng() < 0.5 and "hh_effect_tally" or "hh_remove_stone"
    end
    local tool_chance = kind == "boss" and 0.5 or kind == "elite" and 0.3 or 0.01
    chance(tool_chance, "ac_refreshstone")
    chance(tool_chance, "ad_cleanstone")
    if kind == "boss" then
        local scroll_chances = { 0.02, 0.01, 0.005, 0.001, 0.0001, 0.00001, 0.000001 }
        for level = 6, 12 do
            chance(scroll_chances[level - 5], "wb_strengthen_strengthen_" .. level .. "_levelpaper")
        end
    end
    return result
end

return M
