local Rewards = {}

Rewards.MILESTONES = {1, 2, 4, 6}

local season_data = {
    spring = {
        seed = "xd_lc_lmg_seed", gem = "yellowgem", boss = "goose_feather",
        basic = {{prefab="cutgrass", amount=15}, {prefab="twigs", amount=15}, {prefab="petals", amount=10}},
    },
    summer = {
        seed = "xd_lc_cyh_seed", gem = "orangegem", boss = "dragon_scales",
        basic = {{prefab="ice", amount=20}, {prefab="nitre", amount=10}, {prefab="rocks", amount=10}},
    },
    autumn = {
        seed = "xd_lc_qfx_seed", gem = "greengem", boss = "bearger_fur",
        basic = {{prefab="log", amount=20}, {prefab="cutgrass", amount=15}, {prefab="rocks", amount=10}},
    },
    winter = {
        seed = "xd_lc_hsc_seed", gem = "bluegem", boss = "deerclops_eyeball",
        basic = {{prefab="log", amount=20}, {prefab="charcoal", amount=10}, {prefab="cutgrass", amount=10}},
    },
}

local tier_entries = {
    [1] = {
        {id="restore50", weight=1}, {id="bandage2", weight=1},
        {id="perogies3", weight=1}, {id="season_basic", weight=1},
    },
    [2] = {
        {id="xp75", weight=2}, {id="lingshi1_20", weight=3},
        {id="seed3", weight=2}, {id="season_basic", weight=2},
    },
    [4] = {
        {id="xp150", weight=2}, {id="lingshi1_40", weight=3},
        {id="lingshi2_2", weight=2}, {id="seed5_gem1", weight=1},
    },
    [6] = {
        {id="xp250", weight=3}, {id="lingshi2_3", weight=3},
        {id="lingshi3_1", weight=1}, {id="seed8", weight=2}, {id="bossmat1", weight=1},
    },
}

local labels = {
    restore50 = "Hồi 50 Máu, 50 Tỉnh táo và 50 Độ no",
    bandage2 = "2 Băng mật ong",
    perogies3 = "3 Bánh xếp",
    season_basic = "Gói nguyên liệu theo mùa",
    xp75 = "75 EXP", xp150 = "150 EXP", xp250 = "250 EXP",
    lingshi1_20 = "20 Linh thạch hạ phẩm", lingshi1_40 = "40 Linh thạch hạ phẩm",
    lingshi2_2 = "2 Linh thạch trung phẩm", lingshi2_3 = "3 Linh thạch trung phẩm",
    lingshi3_1 = "1 Linh thạch thượng phẩm",
    seed3 = "3 Hạt linh thảo theo mùa", seed5_gem1 = "5 Hạt linh thảo và 1 Ngọc theo mùa",
    seed8 = "8 Hạt linh thảo theo mùa", bossmat1 = "1 Vật liệu boss theo mùa",
}

local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = Copy(child) end
    return result
end

local function Items(...)
    return {...}
end

local function Build(id, season)
    local data = season_data[season]
    if data == nil then return nil end
    local star = (id == "xp250" or id == "lingshi2_3" or id == "lingshi3_1" or id == "seed8" or id == "bossmat1") and 1 or nil
    if id == "restore50" then return {stats={health=50, sanity=50, hunger=50}} end
    if id == "bandage2" then return {items=Items({prefab="bandage", amount=2})} end
    if id == "perogies3" then return {items=Items({prefab="perogies", amount=3})} end
    if id == "season_basic" then return {items=Copy(data.basic)} end
    if id == "xp75" then return {xp=75} end
    if id == "xp150" then return {xp=150} end
    if id == "xp250" then return {xp=250, star=star} end
    if id == "lingshi1_20" then return {items=Items({prefab="xd_lingshi1", amount=20})} end
    if id == "lingshi1_40" then return {items=Items({prefab="xd_lingshi1", amount=40})} end
    if id == "lingshi2_2" then return {items=Items({prefab="xd_lingshi2", amount=2})} end
    if id == "lingshi2_3" then return {items=Items({prefab="xd_lingshi2", amount=3}), star=star} end
    if id == "lingshi3_1" then return {items=Items({prefab="xd_lingshi3", amount=1}), star=star} end
    if id == "seed3" then return {items=Items({prefab=data.seed, amount=3})} end
    if id == "seed5_gem1" then return {items=Items({prefab=data.seed, amount=5}, {prefab=data.gem, amount=1})} end
    if id == "seed8" then return {items=Items({prefab=data.seed, amount=8}), star=star} end
    if id == "bossmat1" then return {items=Items({prefab=data.boss, amount=1}), star=star} end
    return nil
end

local function BundleIsValid(bundle, prefab_exists)
    if type(bundle) ~= "table" then return false end
    if type(prefab_exists) ~= "function" then return true end
    for _, item in ipairs(bundle.items or {}) do
        if not prefab_exists(item.prefab) then return false end
    end
    return true
end

function Rewards.Get(id, season)
    return Copy(Build(id, season))
end

function Rewards.FallbackId(milestone)
    if milestone == 1 then return "restore50" end
    if milestone == 2 then return "xp75" end
    if milestone == 4 then return "xp150" end
    if milestone == 6 then return "xp250" end
    return nil
end

function Rewards.IsAllowed(id, milestone)
    if type(id) ~= "string" or tier_entries[milestone] == nil then return false end
    for _, entry in ipairs(tier_entries[milestone]) do
        if entry.id == id then return true end
    end
    return false
end

function Rewards.Eligible(season, milestone, prefab_exists)
    if season_data[season] == nil or tier_entries[milestone] == nil then return {} end
    local result = {}
    for _, entry in ipairs(tier_entries[milestone]) do
        local bundle = Build(entry.id, season)
        if BundleIsValid(bundle, prefab_exists) then result[#result + 1] = Copy(entry) end
    end
    return result
end

function Rewards.Roll(season, milestone, random_fn, prefab_exists)
    random_fn = random_fn or math.random
    local eligible = Rewards.Eligible(season, milestone, prefab_exists)
    if #eligible == 0 then
        local fallback = Rewards.FallbackId(milestone)
        if fallback == nil then return nil, nil end
        return fallback, Rewards.Get(fallback, season)
    end
    local total = 0
    for _, entry in ipairs(eligible) do total = total + entry.weight end
    local chosen = random_fn(1, total)
    if type(chosen) ~= "number" or chosen < 1 or chosen > total then chosen = 1 end
    local cursor = 0
    for _, entry in ipairs(eligible) do
        cursor = cursor + entry.weight
        if chosen <= cursor then return entry.id, Rewards.Get(entry.id, season) end
    end
    local fallback = eligible[1].id
    return fallback, Rewards.Get(fallback, season)
end

function Rewards.Describe(id, season)
    local label = labels[id]
    if label == nil or season_data[season] == nil then return nil end
    if tier_entries[6] then
        for _, entry in ipairs(tier_entries[6]) do
            if entry.id == id then return "1 Star + " .. label end
        end
    end
    return label
end

return Rewards
