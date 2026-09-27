local ach_tab_counts = {
    food = 7, life = 2, hurt = 8, work = 14, have = 3, stat = 9,
    vile = 4, slay = 9, duel = 12, boss = 13, misc = 8, mile = 11
}
local ach_tab_names = { "food", "life", "hurt", "work", "have", "stat", "vile", "slay", "duel", "boss", "misc", "mile" }

local perk_tab_counts = {
    attributes = 18, abilities = 19, crafting = 15, global = 11
}
local perk_tab_names = { "attributes", "abilities", "crafting", "global" }

local ach_names = {
    -- Food 7
    "supereat", "eathot", "eatcold", "eatmandrake", "eatguardianhorn", "eatnightberry", "eatmonsterlasagna",
    --Life 2
    "death", "reviveamulet",
    --Hurt 8
     "pacifist", "damagedeal", "tank", "dmgnodmg", "burn", "freeze", "drown", "lightning",
    --Work 14
    "plantmaster", "fishmaster", "pickmaster", "chopmaster", "minemaster", "cookmaster", "buildmaster", "honeymaster", "jerkymaster", "flowermaster", "fertilizemaster", "fertilizebigmaster", "wallmaster", "picktumbleweed",
    --Have 3
    "equipingkrampussack", "luckyrabbit", "iridescentgems",
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
if #nova_achievements > 0 then
    ach_tab_counts.nova = #nova_achievements
    table.insert(ach_tab_names, "nova")
    for _, achievement in ipairs(nova_achievements) do
        table.insert(ach_names, achievement.id)
    end
end

local perk_names = {
    -- Attributes [speedup, absorbup, damageup]
    "hungerup", "healthup", "sanityup", "healthregenup", "hungerrateup", "sanityregenup", "planarabsorbup", "planardamageup", "criticalup", "criticaldmgup", "lifestealup", "fireflylightup", "scaleup", "xpmultup", "repairitemup", "repairmagiup", "repairfoodup", "krampussackup",
    -- Ability [sharemap, strongergrip] christmastbulb
    "nomoist", "icemaster", "firemaster", "fastworker", "minefaster", "chopfaster", "fishfaster", "cookfaster", "warlychef", "trinketowner", "doublehealed", "doublepick", "doubledrop", "doubleworkdrop", "buildcheaper", "supercritter", "blueprintextractor", "itemmerger", "itemcleaner",
    -- Crafting [carpentercraft]
    "ancientstation", "lunarcraft", "pearlcraft", "rabbitkingcraft", "crittercraft", "madsciencecraft", "eventcraft", "carnivalcraft", "klaussackbuilder", "bossitemcraft", "dencraft", "trinketcraft", "clustercraft", "multicraft", "duppercritter",
    -- Global []
    "eternalcage", "eternalicebox", "eternalthermal", "easyfarm", "easybeef", "icyweed", "bosshunting", "stackinfinite", "insightinfinite", "groundedscream", "riftcontroller"
}
local perk_character_exceptions = {
    healthup = { wanda = true },
    healthregenup = { wanda = true },
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
        trinketowner = get_hideperk_value("trinketowner"),
        expertwoodie1 = true,
        expertwendy3 = true,
        trinket = get_hideperk_value("trinketowner"),
        trinket = get_hideperk_value("trinketowner"),
        trinket = get_hideperk_value("trinketowner"),
        trinket = get_hideperk_value("trinketowner"),
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
