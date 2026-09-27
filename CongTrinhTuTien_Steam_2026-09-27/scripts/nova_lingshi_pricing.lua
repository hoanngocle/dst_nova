local DEFAULT_UNITS = 10 -- 5 Hạ Phẩm Linh Thạch
local ATTRIBUTE_STONE_TIERS = require("nova_attribute_stone_tiers")
local ATTRIBUTE_STONE_UNITS = {
    I = 40, II = 100, III = 200, IV = 400, V = 800,
    UTILITY = 200,
}

-- Values are integer half-stones. Keep this table separate from machine logic
-- so balance changes do not require touching transaction code.
local VALUES = {
    -- Very common renewable materials: 1 stone.
    cutgrass = 2,
    twigs = 2,
    rocks = 2,
    flint = 2,
    petals = 2,
    petals_evil = 2,
    ash = 2,
    pinecone = 2,
    seeds = 2,
    spoiled_food = 2,

    -- Wilson can transmute 1 meat into 2 small meats. Keep both redeemable
    -- without letting the conversion increase the recycler balance.
    meat = 10,
    smallmeat = 5,

    -- Common materials and loot: 2 stones when no recipe overrides them.
    log = 4,
    nitre = 4,
    goldnugget = 4,
    charcoal = 4,
    cutreeds = 4,
    silk = 4,
    houndstooth = 4,
    pigskin = 4,
    manrabbit_tail = 4,
    beefalowool = 4,

    -- Common crafted materials retain their fallback values.
    boards = 10,
    cutstone = 10,
    rope = 10,

    -- Magical materials and gems: 10 stones.
    moonrocknugget = 20,
    nightmarefuel = 20,
    redgem = 20,
    bluegem = 20,
    purplegem = 20,
    orangegem = 20,
    yellowgem = 20,
    greengem = 20,
    thulecite = 20,

    -- Scarce materials: 25 stones.
    gears = 50,
    livinglog = 50,
    moonstorm_spark = 50,
    royal_jelly = 50,
    shadowheart = 50,

    -- Boss loot: 100 stones.
    dragon_scales = 200,
    deerclops_eyeball = 200,
    bearger_fur = 200,
    shroom_skin = 200,

    -- Exceptional loot: 200 stones.
    malbatross_beak = 400,
    minotaurhorn = 400,
    klaus_sack = 400,
    purebrilliance = 400,
    horrorfuel = 400,
    alterguardianhatshard = 400,

    -- Vanilla rare drops without ordinary crafting recipes.
    walrus_tusk = 50,
    steelwool = 50,
    mandrake = 50,
    horn = 50,
    lightninggoathorn = 50,

    armorsnurtleshell = 200,
    lunarplant_husk = 200,
    voidcloth = 200,
    dreadstone = 200,
    eyemaskhat = 200,

    krampus_sack = 400,
    armorskeleton = 400,
    skeletonhat = 400,
    hivehat = 400,
    shieldofterror = 400,

    -- Curated Tu Tiên drops. Prefab names are verified against the mod's
    -- STRINGS.NAMES entries; these must never fall through to the default.
    xd_bysp = 200, -- Mảnh Bản Nguyên
    xd_spider_leg = 200, -- Tà Sát Bộ Túc
    xd_mgqg = 200, -- Ma Quái Kiềm Cốt
    xd_baihu_skin = 400, -- Cẩm Mao Hổ Bì
    xd_qlr = 400, -- Kỳ Lân Nhung
    xd_fs = 400, -- Phượng Tủy
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

local function IsTraderRecipe(recipe)
    return recipe.actionstr == "WANDERINGTRADERSHOP"
        or (type(recipe.name) == "string"
            and string.match(recipe.name, "^wanderingtradershop_") ~= nil)
end

local function ResolveUnitValue(prefab, all_recipes, visiting)
    if type(prefab) ~= "string" or prefab == "" then
        return nil
    end
    if visiting[prefab] then
        return nil
    end

    if type(all_recipes) ~= "table" then
        return VALUES[prefab] or DEFAULT_UNITS
    end

    visiting[prefab] = true
    local best = nil
    for _, recipe in pairs(all_recipes) do
        local product = recipe.product or recipe.name
        -- Transmutations can form cycles (for example meat <-> smallmeat),
        -- so they cannot establish an item's intrinsic price. They are still
        -- checked for profit in RecipeCreatesProfit below.
        local is_transmutation = type(recipe.name) == "string"
            and string.match(recipe.name, "^transmute_") ~= nil
        if not IsTraderRecipe(recipe) and not is_transmutation and product == prefab
            and type(recipe.ingredients) == "table" and #recipe.ingredients > 0 then
            local output_count = math.max(1, PositiveInteger(recipe.numtogive, 1))
            local input_units = 0
            local valid = true
            for _, ingredient in ipairs(recipe.ingredients) do
                local amount = PositiveInteger(ingredient.amount, 0)
                local ingredient_units = ResolveUnitValue(ingredient.type, all_recipes, visiting)
                if amount == 0 or ingredient_units == nil then
                    valid = false
                    break
                end
                input_units = input_units + ingredient_units * amount
            end
            if valid then
                local per_item = math.max(1, math.floor(input_units / output_count))
                best = best == nil and per_item or math.min(best, per_item)
            end
        end
    end
    visiting[prefab] = nil
    return best or VALUES[prefab] or DEFAULT_UNITS
end

local function GetRawUnitValue(prefab, all_recipes)
    return ResolveUnitValue(prefab, all_recipes, {})
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

local function GetAttributeStoneUnits(item)
    if item._tbc_stone_invalid or item._tbc_code == nil then
        return nil
    end
    local code = item._tbc_code:value()
    local tier = ATTRIBUTE_STONE_TIERS[code]
    return ATTRIBUTE_STONE_UNITS[tier]
end

local function RecipeCreatesProfit(prefab, all_recipes)
    if type(all_recipes) ~= "table" then
        return false
    end

    local output_unit_value = GetRawUnitValue(prefab, all_recipes)
    for _, recipe in pairs(all_recipes) do
        local product = recipe.product or recipe.name
        if not IsTraderRecipe(recipe) and product == prefab
            and type(recipe.ingredients) == "table" and #recipe.ingredients > 0 then
            local output_count = math.max(1, PositiveInteger(recipe.numtogive, 1))
            local output_units = output_unit_value * output_count
            local input_units = 0

            for _, ingredient in ipairs(recipe.ingredients) do
                -- Character/stat ingredients and malformed mod recipes have
                -- no item prefab to value. Reject their output conservatively.
                if type(ingredient.type) ~= "string" or ingredient.type == "" then
                    return true
                end
                local amount = math.max(1, PositiveInteger(ingredient.amount, 1))
                local ingredient_units = GetRawUnitValue(ingredient.type, all_recipes)
                if ingredient_units == nil then
                    return true
                end
                input_units = input_units + ingredient_units * amount
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
    if prefab == "hh_essence" or string.match(prefab, "^xd_lingshi%d+$") ~= nil then
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

    local base_units = GetRawUnitValue(prefab, all_recipes)
    if prefab == "hh_effect_stone" then
        base_units = GetAttributeStoneUnits(item) or base_units
    end
    local unit_value = ApplyDurability(item, base_units)
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
