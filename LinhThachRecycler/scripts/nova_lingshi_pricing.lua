local DEFAULT_UNITS = 1 -- 0.5 Hạ Phẩm Linh Thạch

-- Values are integer half-stones. Keep this table separate from machine logic
-- so balance changes do not require touching transaction code.
local VALUES = {
    -- Very common renewable materials: 0.5 stone.
    cutgrass = 1,
    twigs = 1,
    rocks = 1,
    flint = 1,
    petals = 1,
    petals_evil = 1,
    ash = 1,
    pinecone = 1,
    seeds = 1,
    spoiled_food = 1,

    -- Common materials and loot: 1 stone.
    log = 2,
    nitre = 2,
    goldnugget = 2,
    charcoal = 2,
    cutreeds = 2,
    silk = 2,
    houndstooth = 2,
    pigskin = 2,
    manrabbit_tail = 2,
    beefalowool = 2,
    boards = 2,
    cutstone = 2,
    rope = 2,
    moonrocknugget = 2,
    nightmarefuel = 2,

    -- Harder materials: 2-3 stones.
    redgem = 4,
    bluegem = 4,
    purplegem = 6,
    orangegem = 6,
    yellowgem = 6,
    greengem = 6,
    thulecite = 6,
    gears = 6,
    livinglog = 6,
    moonstorm_spark = 6,

    -- Rare and boss loot: 5-20 stones.
    royal_jelly = 10,
    shadowheart = 16,
    dragon_scales = 20,
    deerclops_eyeball = 20,
    bearger_fur = 20,
    shroom_skin = 20,
    malbatross_beak = 24,
    minotaurhorn = 30,
    klaus_sack = 30,
    purebrilliance = 32,
    horrorfuel = 32,
    alterguardianhatshard = 40,
}

local PROTECTED = {
    nova_lingshi_recycler = true,
    eye_bone = true,
    hutch_fishbowl = true,
    lavae_egg = true,
    lavae_egg_cracked = true,
    moonrockseed = true,
    terrarium = true,
    atrium_key = true,
    archive_lockbox = true,
    wagstaff_tool_1 = true,
    wagstaff_tool_2 = true,
    wagstaff_tool_3 = true,
    wagstaff_tool_4 = true,
    wagstaff_tool_5 = true,
}

local REASON = {
    INVALID = "Vật phẩm không hợp lệ",
    CURRENCY = "Không thể tái luyện Linh Thạch",
    PROTECTED = "Vật phẩm nhiệm vụ được bảo vệ",
    CONTAINER_NOT_EMPTY = "Hãy lấy hết đồ bên trong trước",
    PROFITABLE_RECIPE = "Công thức này có thể tạo lãi",
}

local function PositiveInteger(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value then
        return fallback
    end
    return math.max(0, math.floor(value))
end

local function GetRawUnitValue(prefab)
    return VALUES[prefab] or DEFAULT_UNITS
end

local function GetDurabilityPercent(item)
    local percent = nil
    local components = item.components

    if components.finiteuses ~= nil then
        percent = components.finiteuses:GetPercent()
    elseif components.armor ~= nil then
        percent = components.armor:GetPercent()
    elseif components.fueled ~= nil then
        percent = components.fueled:GetPercent()
    end

    if percent == nil then
        return 1
    end
    return math.max(0, math.min(1, percent))
end

local function ApplyDurability(item, base_units)
    return math.max(1, math.floor(base_units * GetDurabilityPercent(item)))
end

local function RecipeCreatesProfit(prefab, all_recipes)
    if type(all_recipes) ~= "table" then
        return false
    end

    local output_unit_value = GetRawUnitValue(prefab)
    for _, recipe in pairs(all_recipes) do
        local product = recipe.product or recipe.name
        if product == prefab and type(recipe.ingredients) == "table" and #recipe.ingredients > 0 then
            local output_count = math.max(1, PositiveInteger(recipe.numtogive, 1))
            local output_units = output_unit_value * output_count
            local input_units = 0

            for _, ingredient in ipairs(recipe.ingredients) do
                local amount = math.max(1, PositiveInteger(ingredient.amount, 1))
                input_units = input_units + GetRawUnitValue(ingredient.type) * amount
            end

            if output_units > input_units then
                return true
            end
        end
    end
    return false
end

local function Reject(reason)
    return {
        accepted = false,
        units = 0,
        count = 0,
        reason = reason,
    }
end

local function GetItemQuote(item, all_recipes)
    if item == nil or not item:IsValid() or item.prefab == nil then
        return Reject(REASON.INVALID)
    end

    local prefab = item.prefab
    if string.match(prefab, "^xd_lingshi%d+$") ~= nil then
        return Reject(REASON.CURRENCY)
    end
    if PROTECTED[prefab] or item:HasTag("irreplaceable") then
        return Reject(REASON.PROTECTED)
    end
    if item.components.container ~= nil and not item.components.container:IsEmpty() then
        return Reject(REASON.CONTAINER_NOT_EMPTY)
    end

    all_recipes = all_recipes or rawget(_G, "AllRecipes")
    if RecipeCreatesProfit(prefab, all_recipes) then
        return Reject(REASON.PROFITABLE_RECIPE)
    end

    local count = 1
    if item.components.stackable ~= nil then
        count = math.max(1, PositiveInteger(item.components.stackable:StackSize(), 1))
    end

    local unit_value = ApplyDurability(item, GetRawUnitValue(prefab))
    local units = unit_value * count
    return {
        accepted = true,
        units = units,
        count = count,
        reason = nil,
    }
end

return {
    DEFAULT_UNITS = DEFAULT_UNITS,
    VALUES = VALUES,
    PROTECTED = PROTECTED,
    REASON = REASON,
    GetRawUnitValue = GetRawUnitValue,
    GetItemQuote = GetItemQuote,
    RecipeCreatesProfit = RecipeCreatesProfit,
}
