local ach_tab_counts = {
    food = 7, life = 2, hurt = 8, work = 14, have = 2, stat = 9,
    vile = 4, slay = 9, duel = 12, boss = 13, misc = 8, mile = 11
}
local ach_tab_names = { "food", "life", "hurt", "work", "have", "stat", "vile", "slay", "duel", "boss", "misc", "mile" }

local perk_tab_counts = {
    attributes = 11, abilities = 14, crafting = 12, global = 7
}
local perk_tab_names = { "attributes", "abilities", "crafting", "global" }

local base_ach_names = {
    -- Food 7
    "supereat", "eathot", "eatcold", "eatmandrake", "eatguardianhorn", "eatnightberry", "eatmonsterlasagna",
    --Life 2
    "death", "reviveamulet",
    --Hurt 8
     "pacifist", "damagedeal", "tank", "dmgnodmg", "burn", "freeze", "drown", "lightning",
    --Work 14
    "plantmaster", "fishmaster", "pickmaster", "chopmaster", "minemaster", "cookmaster", "buildmaster", "honeymaster", "jerkymaster", "flowermaster", "fertilizemaster", "fertilizebigmaster", "wallmaster", "picktumbleweed",
    --Have 2
    "equipingkrampussack", "iridescentgems",
    --Stat 9
    "fullsanity", "fullhunger", "sanitymaxwell", "nosanity", "lunacy", "starve", "icebody", "firebody", "moistbody",
    --Vile 4
    "killbutterfly", "killbird", "killgloomer", "killchester",
    --Slay 9
    "lightninggoat", "beefalo", "koalefant", "horrorhound", "werepig", "beardlord", "snurtle", "mosling", "birchnut",
    --Duel 12
    "lavae", "spiderqueen", "pengul", "tentapillar", "seaweed", "grassgator", "ewecus", "ghost", "gnarwail", "rockjaw", "bigworm", "soloyourself",
    --Boss 13
    "santaklaus", "dragonflybeequeen", "malbatrosscrabking", "shadowpieche", "ancientguardianancientfuelweaver", "celestialchampion", "celestialscion", "guardtower", "werepigs", "toadstool", "twinterror", "seasonboss", "mutationboss",
    --Misc 8
    "opentreasure", "piratechest", "sitting", "sacrificecotl", "sewing", "wither", "minemoon", "aquarium",
    --Mile 11
    "intogame", "starspent", "didtask", "oldage", "walkalot", "stopalot", "caveage", "waterage", "rider", "walkturf", "complete"
}

local nova_achievements = require "constants/novaachievements"
local nova_group_tab = {
    survival = "life", food = "food", collection = "have",
    labor = "work", crafting = "work", farming = "work",
    combat = "slay", boss = "boss", level_rank = "mile",
    seasonal = "mile", gacha_shop = "misc",
}
local added_by_tab = {}
for _, achievement in ipairs(nova_achievements) do
    local tab = nova_group_tab[achievement.group]
    assert(tab and ach_tab_counts[tab], "Unknown achievement group: " .. tostring(achievement.group))
    added_by_tab[tab] = added_by_tab[tab] or {}
    table.insert(added_by_tab[tab], achievement.id)
end

local ach_names = {}
local base_index = 1
for _, tab in ipairs(ach_tab_names) do
    local base_count = ach_tab_counts[tab]
    for _ = 1, base_count do
        table.insert(ach_names, base_ach_names[base_index])
        base_index = base_index + 1
    end
    for _, id in ipairs(added_by_tab[tab] or {}) do
        table.insert(ach_names, id)
    end
    ach_tab_counts[tab] = base_count + #(added_by_tab[tab] or {})
end
assert(base_index == #base_ach_names + 1, "Base achievement tab counts do not match their list")

local perk_names = {
    -- Attributes [speedup, absorbup, damageup]
    "hungerup", "healthup", "sanityup", "planarabsorbup", "planardamageup", "criticalup", "criticaldmgup", "lifestealup", "fireflylightup", "scaleup", "xpmultup",
    -- Ability [sharemap, strongergrip] christmastbulb
    "nomoist", "icemaster", "firemaster", "fastworker", "minefaster", "chopfaster", "fishfaster", "cookfaster", "warlychef", "doublehealed", "doublepick", "doubledrop", "doubleworkdrop", "buildcheaper",
    -- Crafting [carpentercraft]
    "ancientstation", "lunarcraft", "pearlcraft", "rabbitkingcraft", "crittercraft", "madsciencecraft", "eventcraft", "carnivalcraft", "klaussackbuilder", "bossitemcraft", "dencraft", "duppercritter",
    -- Global []
    "eternalcage", "eternalthermal", "easyfarm", "icyweed", "bosshunting", "groundedscream", "riftcontroller"
}
local perk_character_exceptions = {
    healthup = { wanda = true },
    lifestealup = { wanda = true },
    strongergrip = { wurt = true },
    warlychef = { warly = true },
}

local hideperk_config = TUNING.CHASNI_CONFIG and TUNING.CHASNI_CONFIG.HIDEPERK or {}
local function get_hideperk_value(key)
    return hideperk_config[key] or false
end

local function create_perk(name, exception, only)
    local final_exception = exception or {}
    final_exception.all = get_hideperk_value(string.upper(name))
    return {
        name = name,
        exception = final_exception,
        only = only
    }
end

local perk_list = {}
for _, name in ipairs(perk_names) do
    table.insert(perk_list, create_perk(name, perk_character_exceptions[name]))
end
local function generate_table(names, counts)
    local result = {}
    local start_index = 1
    for _, name in ipairs(names) do
        table.insert(result, {
            name = name,
            count = counts[name],
            start = start_index
        })
        start_index = start_index + counts[name]
    end
    return result
end

return {
    ach_tab = generate_table(ach_tab_names, ach_tab_counts),
    ach_list = ach_names,

    --completeamount = self.owner.currentcomplete:value(),
    perk_tab = generate_table(perk_tab_names, perk_tab_counts),
    perk_list = perk_list,
    ui_hidden_list = {
        trinketowner = get_hideperk_value("TRINKETOWNER"),
        expertwoodie1 = true,
        expertwendy3 = true,
        trinket = get_hideperk_value("TRINKETOWNER"),
    }
}
--example data :
--[[
tabs = {
    ["name"] = "food",
    ["count"] = 5,
    ["start"] = 1,
},
perk_list {
    name = name,
    exception = exception or { all = get_hideperk_value(string.upper(name)) },
    only = only
}
]]--
