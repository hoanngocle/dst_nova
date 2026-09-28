require "functions/helperfunctions"

local prefabs = {
    "seffc",
    "simplefx",
    "light_fx",
    "shieldsbuff",
    "chasni_buff",
    "ground_ring",
    "new_trinkets",
    "trinketslot", -- Load old equipped containers so their contents can be returned.
    "clusteritem", -- Keep previously crafted items loadable.
    "multiitem",
}

local groups = {
    ["duppercritter"] = {
        "duppercritter/chasni_critters",
        "duppercritter/chasni_critters_proj",
        "duppercritter/chasni_critters_proj_complex",
        "duppercritter/chasni_critters_proj_special",
        "duppercritter/chasni_critters_buffauras",
        "duppercritter/chasni_critters_buffauras_vision",
        "duppercritter/chasni_critters_basicitems",
        "duppercritter/chasni_critter_botbomb",
        "duppercritter/chasni_pearl_bracelet",
        "duppercritter/chasni_pearl_amulet",
        "duppercritter/chasni_didgerizoo",
    },
    ["dencraft"] = {
        "dencraft_placer",
    },
    ["klaussackbuilder"] = {
        "klaussack_placer",
    },
    ["bosshunting"] = {
        "dirtpile_boss",
        "animal_track_boss",
        -->> mobs
        "mobs/plasmablob",
        "mobs/gronehog",
        "mobs/wargfant",
        "mobs/wargfant_firering",
        "mobs/snapdragon",
        "mobs/slip",
        "mobs/slipstor",
        "mobs/brrrd",
        "mobs/blackfly",
        "mobs/dungpile",
        "mobs/giantgrub",
        "mobs/weevole",
        "mobs/crocodog",
        "mobs/spidermonkey",
        "mobs/spidermonkey_creep",
        "mobs/hippopotamoose",
        "mobs/pangolden",
        "mobs/adultflytrap",
        "mobs/grabbingvine",
        "mobs/treeguard",
        "mobs/treeguard_coconut",
        "mobs/mandrakeman",
        "mobs/waterbishop",
        "mobs/poison_spider",
        "mobs/poison_mosquito",
        "mobs/poison_frog",
        "mobs/new_deer",
        "mobs/new_deer_fx",
        "mobs/new_deer_green_circle_fx",
        "mobs/new_deer_orange_circle_fx",
        "mobs/new_deer_yellow_circle_fx",
        "mobs/new_deer_purple_circle_fx",
        "mobs/new_deerantler",
        "mobs/new_klaussack",
        "mobs/new_klaus",
        "mobs/ancientherald",
        "mobs/ancientherald_firerain",
        "mobs/ancientherald_firerainimpact",
        "mobs/ancientherald_lavapool",
        "mobs/sealnado",
        "mobs/seal",
        "mobs/ancient_hulk",
        "mobs/ancient_robots",
        "mobs/ancient_robots_assembly",
        "mobs/new_crabking_claw",
        "mobs/new_crabking_claw_proj",
        "mobs/new_crabking_claw_buff",
        -->> ancient_hulk
        "laser",
        "laserring",
        "rock_basalt",
        -->> drops
        "rog/basicitems",
        "rog/chasni_poison_gland",
        "rog/snapdragon_flower",
        "rog/cocoontrees",
        "rog/new_seeds",
        -->> items
        "rog/woodenpigstatue",
        "rog/windconch",
        "rog/birdwhistle",
        "rog/tinker_house",
        "rog/upgraded_batbat",
        "rog/upgraded_minerhat",
        "rog/upgraded_shovel",
        "rog/upgraded_farmplot",
        "rog/medicalkit",
        "rog/armorgold",
        "rog/upgraded_fencerotator",
        "rog/upgraded_boat",
        "rog/oar_stopper",
        "rog/upgraded_amulet",
        "rog/upgraded_blueamulet",
        "rog/upgraded_catcoonhat",
        "rog/upgraded_whip",
        "rog/upgraded_treasurechest",
        "rog/slipscraft",
        "rog/trap_flytrap",
        "rog/crocpack",
        "rog/crockit",
        "rog/chasni_electricdart",
        "rog/rottenpack",
        "rog/repairkit",
        "rog/blob_lantern",
        "rog/volcanic_hat",
        "rog/arctic_hat",
        "rog/upgraded_featherhat",
        "rog/chasni_fans",
        "rog/pondstructionplans",
        "rog/upgraded_pond",
        "rog/upgraded_pond_plant",
        "rog/upgraded_icebox",
        "rog/water_crabamulet",
        "rog/phasebells",
        "rog/chasni_gas",
        "rog/upgraded_boomerang",
        "rog/hulkhat",
        "rog/hulkgloves",
        "rog/crabstaff_shadow",
        "rog/crabstaff_lunar",
        "rog/crabstaff_water",
        "rog/crabstaff_electric",
        "rog/crabstaff_electricturret",
        "rog/crabstaff_fire",
        "rog/crabstaff_ice",
        -->> char specific
        "wilson/gem_portal",
        "willow/food_heater",
        "wolfgang/new_dumbbells",
        "wx/solar_panel",
        "wx/gears_charged",
        "wx/shootgoggles",
        "woodie/axe_axe",
        "waxwell/books_voker",
        "wigfrid/warf_emitter",
        "wes/upgraded_balloons",
        "wes/upgraded_balloons_empty",
        "webber/webball",
        "webber/spider_mutators_perk",
        "wormwood/healingward",
        "wormwood/healingward_fire",
        "walter/scoutbadges",
        "wortox/soul_amulet",
        "winona/upgraded_greenamulet",
        "wendy/pipspook_staff",
        "wickerbottom/readingglasses",
        "warly/warlyphone",
        "warly/customer",
        "wurt/merm_hat",
        "wanda/watchpaint",
        -->> book_voker
        "chasni_invis",
        "rog/voker_alacrity",
        "rog/voker_icewall",
        "rog/voker_forgespirit",
        "rog/voker_tornado",
        -->> item's prefab
        "rog/dark_beeguard",
        "rog/chasni_kitcoon",
    },
    ["icyweed"] = {
        "icyweed",
    },

    ["expertwicker3"] = {
        "wickerbottom/books_perk",
        "wickerbottom/bookpack",
        "wickerbottom/new_book_buff",
    },
    ["expertwanda1"] = {
        "wanda/watchcase",
        "wanda/pocketwatches_perk",
        "wanda/wanda_clone",
    },
    ["expertwathg1"] = {
        "wigfrid/thunder_spear",
        "wigfrid/thunder_armor",
        "wigfrid/thunder_hat",
    },
    ["expertwathg2"] = {
        "wigfrid/battlesongs_perk",
        "wigfrid/battlesongsbuffs_perk",
        "wigfrid/battlesongsfx_perk",
        "wigfrid/songfolder",
    },
    ["expertwendy2"] = {
        "wendy/ghostly_elixirs_perk",
        "wendy/ghostly_elixirfx_perk",
    },
    ["expertwes2"] = {
        "wes/balloons_perk",
    },
    ["expertwebber2"] = {
        "webber/fluffyhouse",
        "webber/fluffy",
    },
    ["expertwebber3"] = {
        "webber/webbermasks",
        "webber/webbermask_spike",
        "webber/webbermask_spit",
    },
    ["expertwarly3"] = {
        "warly/fryingpan",
        "warly/chefhat",
        "warly/chefpackred",
        "warly/bentobox",
    },
    ["expertwarly4"] = {
        "warly/portablegriller",
        "warly/portablegriller_foods",
        "warly/new_food_buff",
    },
    ["expertwalter3"] = {
        "walter/magnifying_glass",
        "walter/campingbag",
        "walter/adventure_hat",
    },
    ["expertwalter4"] = {
        "walter/ammo_perk",
        "walter/slingshot_perk",
    },
    ["expertwurt1"] = {
        "wurt/water_spear",
        "wurt/water_hat",
    },
    ["expertwurt2"] = {
        "wurt/mermprotector",
    },
    ["expertwolf2"] = {
        "wolfgang/marbled_spear",
        "wolfgang/marbled_armor",
        "wolfgang/marbled_hat",
    },
    ["expertwillow3"] = {
        "willow/fire_rock",
        "willow/fire_hat",
        "willow/fire_spear",
        "willow/fire_armor",
        "willow/fire_staff",
        "willow/fire_staff_meteor",
    },
    ["expertwillow4"] = {
        "willow/fire_clone",
        "willow/flame_guard",
    },
    ["expertwaxwell3"] = {
        "waxwell/shadow_tools",
    },
    ["expertwaxwell4"] = {
        "waxwell/shadowtottem",
        "waxwell/shadowrealm",
        "waxwell/shadowwisp",
        "waxwell/shadowwisp_fire",
    },
    ["expertworm1"] = {
        "wormwood/nature_staff",
        "wormwood/nature_hat",
        "wormwood/wormwood_salve",
        "wormwood/brambletower",
        "wormwood/bramblechest",
        "wormwood/bramblefx_new",
    },
    ["expertworm2"] = {
        "wormwood/wormwood_poop_buff",
    },
    ["expertwortox3"] = {
        "wortox/hell_staff",
        "wortox/hell_hat",
        "wortox/hell_armor",
    },
    ["expertwx4"] = {
        "wx/new_wx78_scanner",
        "wx/chasni_wx78_foodbrick",
    },
    ["expertwinona1"] = {
        "winona/basefan",
        "winona/sprinkler",
        "winona/water_spray",
        "winona/water_pipe",
        "winona/rain_drop",
        "winona/city_lamp",
        "winona/pugalisk_trapdoor",
        "winona/materialmaker",
        "winona/telipad",
        "winona/telebrella",
        "winona/thumper",
        "winona/propelomatic",
        "winona/chronoflux",
        "winona/accomplishrine",
        "winona/crafterchest",
        "winona/chasni_winona_battery",
    },
    ["expertwinona2"] = {
        "winona/banner",
        "winona/moonbutterfly_fx",
    },
    ["expertwonk1"] = {
        "wonkey/wonkey_burrow",
    },
}

local multi_groups = {
    {
        perks = {"bosshunting", "robinegg"},
        items = {"robin_egg", "robin", "robin_stone"},
    }
}

-- handle single-perk groups
for perk, items in pairs(groups) do
    if not chasni_getperkexcludeconfig(perk) then
        for _, name in ipairs(items) do
            table.insert(prefabs, name)
        end
    end
end

-- handle multi-perk groups
for _, group in ipairs(multi_groups) do
    if not chasni_getperkexcludeconfig(unpack(group.perks)) then
        for _, name in ipairs(group.items) do
            table.insert(prefabs, name)
        end
    end
end

return prefabs

--return {
    --"uncontested/upgraded_redbluestaff",    --scrapped
    --"uncontested/upgraded_beehat",          --scrapped
--}
