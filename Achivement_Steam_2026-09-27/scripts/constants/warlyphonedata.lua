local food_easy = {
    "frogglebunwich", "butterflymuffin", "taffy", "fishsticks", "honeynuggets", "honeyham", "kabobs", "baconeggs", "meatballs", "bonestew", "perogies", "turkeydinner",
    "ratatouille", "jammypreserves", "fruitmedley", "monsterlasagna", "trailmix", "hotchili", "bananapop", "frozenbananadaiquiri", "bananajuice", "californiaroll",
    "meatysalad", "sweettea", "figatoni", "figkabab", "frognewton", "bunnystew", "justeggs", "veggieomlet", "talleggs",
}
local food_hard = {
    "pumpkincookie", "stuffedeggplant", "dragonpie", "mandrakesoup", "fishtacos", "powcake", "unagi", "flowersalad", "icecream", "watermelonicle", "guacamole", "jellybean",
    "potatotornado", "mashedpotatoes", "asparagussoup", "vegstinger", "ceviche", "salsa", "pepperpopper", "seafoodgumbo", "surfnturf", "lobsterbisque", "barnaclepita", "barnaclesushi",
    "barnaclinguine", "barnaclestuffedfishhead", "leafloaf", "leafymeatburger", "leafymeatsouffle", "shroomcake", "koalefig_trunk", 
}
local food_insane = {
    "mandrakesoup", "waffles", "lobsterdinner", 
}
local food_warly = { 
    "nightmarepie", "glowberrymousse", "frogfishbowl", "dragonchilisalad", "gazpacho", "potatosouffle", "monstertartare", "freshfruitcrepes", "bonesoup", "moqueca",
}
local food_expertwarly4 = {
    "chasni_mooncake", "chasni_balut", "chasni_popcorn", "chasni_brigadeiro", "chasni_tumpeng", "chasni_kyivcake", "chasni_empanadas", "chasni_kimchi", "chasni_anzac", "chasni_mopane",
}
local spices = {
    "spice_chili", "spice_garlic", "spice_sugar", "spice_salt",
    "", "", "", "", "", "", "", "", "", ""
}
local reward_easy = {
    { prefab = "seeds", count = 20 },
    { prefab = "beardhair", count = 10 },
    { prefab = "tentaclespots", count = 10 },
    { prefab = "slurper_pelt", count = 10 },
    { prefab = "coontail", count = 10 },
    { prefab = "driftwood_log", count = 10 },
    { prefab = "milkywhites", count = 10 },
    { prefab = "glommerfuel", count = 10 },
    { prefab = "gunpowder", count = 10 },

    { prefab = "walrus_tusk", count = 8 },
    { prefab = "steelwool", count = 8 },
    { prefab = "townportaltalisman", count = 6 },
    { prefab = "malbatross_feather", count = 4 },
    { prefab = "trunk_summer", count = 6 },
    { prefab = "trunk_winter", count = 4 },
    { prefab = "gnarwail_horn", count = 3 },
    { prefab = "lightninggoathorn", count = 5 },
    { prefab = "goatmilk", count = 5 },
    { prefab = "trunk_winter", count = 4 },
    { prefab = "messagebottleempty", count = 5 },

    { prefab = "corn", count = 10 },
    { prefab = "potato", count = 10 },
    { prefab = "tomato", count = 10 },
    { prefab = "asparagus", count = 7 },
    { prefab = "eggplant", count = 7 },
    { prefab = "pumpkin", count = 7 },
    { prefab = "watermelon", count = 7 },
    { prefab = "dragonfruit", count = 5 },
    { prefab = "durian", count = 5 },
    { prefab = "garlic", count = 5 },
    { prefab = "onion", count = 5 },
    { prefab = "pepper", count = 5 },
    { prefab = "pomegranate", count = 5 },

    { prefab = "nitre", count = 10 },
    { prefab = "marble", count = 10 },
    { prefab = "goldnugget", count = 10 },
    { prefab = "moonrocknugget", count = 8 },
    { prefab = "moonglass", count = 8 },
    { prefab = "thulecite", count = 6 },
    { prefab = "redgem", count = 4 },
    { prefab = "bluegem", count = 4 },
    { prefab = "purplegem", count = 3 },
}
local reward_hard = {
    { prefab = "deerclops_eyeball", count = 3 },
    { prefab = "dragon_scales", count = 3 },
    { prefab = "shroom_skin", count = 3 },
    { prefab = "mandrake", count = 3 },
    { prefab = "bearger_fur", count = 6 },
    { prefab = "royal_jelly", count = 6 },
    { prefab = "goose_feather", count = 8 },
    { prefab = "malbatross_beak", count = 2 },
    { prefab = "butter", count = 2 },
    { prefab = "gears", count = 4 },

    { prefab = "greengem", count = 5 },
    { prefab = "dreadstone", count = 6 },
    { prefab = "horrorfuel", count = 6 },
    { prefab = "voidcloth", count = 5 },
    { prefab = "purebrilliance", count = 4 },
    { prefab = "alterguardianhatshard", count = 1 },
    { prefab = "lunarplant_husk", count = 3 },

    { prefab = "wagpunk_bits", count = 10 },
    { prefab = "redgem", count = 12 },
    { prefab = "bluegem", count = 12 },
    { prefab = "purplegem", count = 9 },
    { prefab = "yellowgem", count = 5 },
    { prefab = "greengem", count = 5 },
    { prefab = "orangegem", count = 5 },
    { prefab = "opalpreciousgem", count = 2 },
}
local reward_boss = {
    { prefab = "chasni_poison_gland", count = 3 },
    { prefab = "chasni_exort_feather", count = 2 },
    { prefab = "chasni_quas_feather", count = 2 },
    { prefab = "chasni_grub_jaw", count = 2 },
    { prefab = "chasni_grub_skull", count = 2 },
    { prefab = "chasni_snapdragon_petal", count = 2 },
    { prefab = "chasni_hippo_skin", count = 2 },
    { prefab = "chasni_hippo_antler", count = 2 },
    { prefab = "chasni_wargfant_tooth", count = 2 },
    { prefab = "chasni_wargfant_fur", count = 2 },
    { prefab = "chasni_slipstor_fur", count = 2 },
    { prefab = "chasni_crocodog_skin", count = 2 },
    { prefab = "chasni_pangolden_scale", count = 2 },
    { prefab = "chasni_plasmablob_blob", count = 2 },
    { prefab = "chasni_palmtreeguard_log", count = 2 },
    { prefab = "chasni_gas", count = 2 },
    { prefab = "dug_trap_flytrap", count = 2 },
    { prefab = "chasni_cocoontreeseed", count = 2 },
    { prefab = "chasni_snapdragon_seed", count = 2 },
    { prefab = "jellybean_red", count = 2 },
    { prefab = "jellybean_green", count = 1 },
    { prefab = "jellybean_yellow", count = 1 },
    { prefab = "chasni_hulk_metalbit", count = 1 },
    { prefab = "chasni_crab_fireorgan", count = 1 },
    { prefab = "chasni_crab_iceorgan", count = 1 },
    { prefab = "chasni_crab_waterorgan", count = 1 },
    { prefab = "chasni_crab_electricorgan", count = 1 },
    { prefab = "chasni_crab_lunarorgan", count = 1 },
    { prefab = "chasni_crab_shadoworgan", count = 1 },
    { prefab = "chasni_ancient_remnant", count = 1 },
    { prefab = "chasni_seal_fur", count = 1 },
}
local gofood_dest = {
    "multiplayer_portal", "multiplayer_portal_moonrock", "pigking", "moonbase", "oasislake", "critterlab", "beequeenhive", "hermitcrab",
    "statueglommer", "statuemaxwell", "monkeyqueen", "charlie_stage_post", "dragonfly", "antlion",
    "wormhole", "cave_entrance_open", "cave_entrance", "walrus_camp",
}
local gofood_dest_cave = {
    "multiplayer_portal", "multiplayer_portal_moonrock", "atrium_gate", "archive_switch", "minotaur", "minotaurchest", "daywalker",
    "ancient_altar", "ancient_altar_broken", "toadstool_cap", "cave_exit", "tentacle_pillar_hole", "tentacle_pillar", "archive_lockbox_dispencer",
}
return {food_easy = food_easy, food_hard = food_hard, food_insane = food_insane, food_warly = food_warly, food_expertwarly4 = food_expertwarly4, spices = spices, 
        reward_easy = reward_easy, reward_hard = reward_hard, reward_boss = reward_boss,
        gofood_dest = gofood_dest, gofood_dest_cave = gofood_dest_cave}