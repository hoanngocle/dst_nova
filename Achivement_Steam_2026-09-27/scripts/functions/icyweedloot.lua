local Data = require("constants/icyweedloot")
local Loot = {}

local allowed = {[Data.fallback.prefab] = true, [Data.emergency.prefab] = true}
for _, row in ipairs(Data.rows) do allowed[row.prefab] = true end

local function Copy(row)
    return {prefab = row.prefab, min = row.min, max = row.max,
        weight = row.weight, group = row.group}
end

function Loot.PreparePool(prefab_exists, stack_supported)
    local function Supported(row)
        return prefab_exists(row.prefab) and stack_supported(row.prefab)
    end
    local fallback = Supported(Data.fallback) and Data.fallback or Data.emergency
    local pool = {guaranteed = Copy(Supported(Data.guaranteed) and Data.guaranteed or fallback),
        rows = {}, total = 0}
    for _, row in ipairs(Data.rows) do
        local resolved = Copy(Supported(row) and row or fallback)
        resolved.weight, resolved.group = row.weight, row.group
        pool.rows[#pool.rows + 1] = resolved
        pool.total = pool.total + row.weight
    end
    return pool
end

local function Amount(row, random_int)
    return row.min == row.max and row.min or random_int(row.min, row.max)
end

function Loot.Roll(pool, random_int)
    random_int = random_int or math.random
    local rewards = {{prefab = pool.guaranteed.prefab, amount = Amount(pool.guaranteed, random_int)}}
    for _ = 1, 2 do
        local point = random_int(1, pool.total)
        for _, row in ipairs(pool.rows) do
            point = point - row.weight
            if point <= 0 then
                rewards[#rewards + 1] = {prefab = row.prefab, amount = Amount(row, random_int)}
                break
            end
        end
    end
    return rewards
end

function Loot.NormalizeSaved(data)
    if type(data) ~= "table" or data.version ~= Data.version
        or type(data.rewards) ~= "table" or #data.rewards ~= 3 then return nil end
    local rewards = {}
    for index = 1, 3 do
        local row = data.rewards[index]
        if type(row) ~= "table" or not allowed[row.prefab]
            or type(row.amount) ~= "number" or row.amount < 1 or row.amount > 8
            or row.amount ~= math.floor(row.amount) then return nil end
        rewards[index] = {prefab = row.prefab, amount = row.amount}
    end
    return rewards
end

return Loot
