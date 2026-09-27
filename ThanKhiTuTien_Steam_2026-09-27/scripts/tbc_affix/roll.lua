local Defs = require("tbc_affix/defs")

local M = {}

local weights = {
    { 40, 30, 18, 9, 3 },    -- Luyện Khí
    { 32, 28, 23, 12, 5 },   -- Trúc Cơ
    { 24, 25, 27, 17, 7 },   -- Kết Đan
    { 16, 21, 30, 24, 9 },   -- Nguyên Anh
    { 10, 15, 35, 30, 10 },  -- Hóa Thần
}

local tier_index = { I = 1, II = 2, III = 3, IV = 4, V = 5 }

function M.Realm(level)
    if type(level) ~= "number" or level < 0 or level > 15 or level ~= math.floor(level) then return 1 end
    if level >= 12 then return 5 end
    if level >= 9 then return 4 end
    if level >= 6 then return 3 end
    if level >= 3 then return 2 end
    return 1
end

local function Pick(rng, n)
    if n < 1 then return nil end
    local index = rng(n)
    if type(index) ~= "number" or index ~= math.floor(index) or index < 1 or index > n then return nil end
    return index
end

local function EligibleFamilies(eligible)
    local groups = {}
    for _, family in ipairs(Defs.families) do
        local selected = {}
        for _, row in ipairs(Defs.by_family[family]) do
            if eligible == nil or eligible(row) then selected[#selected + 1] = row end
        end
        if #selected > 0 then groups[#groups + 1] = selected end
    end
    return groups
end

local function ChooseTier(rows, realm, rng)
    local by_tier = {}
    for _, row in ipairs(rows) do
        if tier_index[row.tier] == nil then return rows end
        local index = tier_index[row.tier]
        by_tier[index] = by_tier[index] or {}
        by_tier[index][#by_tier[index] + 1] = row
    end

    local total = 0
    for index = 1, 5 do
        if by_tier[index] ~= nil then total = total + weights[realm][index] end
    end
    local pick = Pick(rng, total)
    if pick == nil then return nil end
    local cumulative = 0
    for index = 1, 5 do
        if by_tier[index] ~= nil then
            cumulative = cumulative + weights[realm][index]
            if pick <= cumulative then return by_tier[index] end
        end
    end
    return nil
end

-- rng(n) returns an integer in [1,n]. No random values are consumed on an empty pool.
function M.Choose(level, rng, eligible)
    rng = rng or math.random
    local groups = EligibleFamilies(eligible)
    local family_index = Pick(rng, #groups)
    if family_index == nil then return nil, nil end
    local options = ChooseTier(groups[family_index], M.Realm(level), rng)
    if options == nil then return nil, nil end
    local row_index = Pick(rng, #options)
    if row_index == nil then return nil, nil end
    local row = options[row_index]
    if row.fixed then return row.code, 0 end
    local count = math.floor((row.max - row.min) / row.step) + 1
    local value_index = Pick(rng, count)
    if value_index == nil then return nil, nil end
    return row.code, row.min + (value_index - 1) * row.step
end

return M
