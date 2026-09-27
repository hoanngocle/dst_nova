
require "functions/helperfunctions"

---------------------------------------------------
-- HELPERS
---------------------------------------------------

local function ImageAssetPair(path)
    return {
        Asset("ATLAS", path .. ".xml"),
        Asset("IMAGE", path .. ".tex"),
    }
end

local function SoundAssetPair(path)
    return {
        Asset("SOUNDPACKAGE", path .. ".fev"),
        Asset("SOUND", path .. ".fsb"),
    }
end

---------------------------------------------------
-- SAFE INSERT (IMPORTANT PART)
---------------------------------------------------

local function is_array(t)
    return type(t) == "table" and t[1] ~= nil
end

local function insert_all(target, value)
    if is_array(value) then
        for _, v in ipairs(value) do
            insert_all(target, v)
        end
    else
        table.insert(target, value)
    end
end

---------------------------------------------------
-- BASE ASSETS
---------------------------------------------------

local assets = {}
insert_all(assets, ImageAssetPair("images/fx/fx3"))
insert_all(assets, ImageAssetPair("images/fx/fx5"))
insert_all(assets, ImageAssetPair("images/fx/fx6"))

insert_all(assets, ImageAssetPair("images/inventoryimages/placeholder"))
insert_all(assets, Asset("IMAGE", "images/colour_cubes/quagmire_cc.tex"))
insert_all(assets, Asset("IMAGE", "images/colour_cubes/lavaarena2_cc.tex"))

insert_all(assets, Asset("ATLAS", "images/inventoryimages/perk_tab.xml"))
insert_all(assets, ImageAssetPair("images/hud/background_lmod"))
insert_all(assets, ImageAssetPair("images/hud/background_info"))
insert_all(assets, ImageAssetPair("images/hud/reset_info"))
insert_all(assets, ImageAssetPair("images/hud/xpbar_empty"))
insert_all(assets, ImageAssetPair("images/hud/levelbadge"))
insert_all(assets, ImageAssetPair("images/hud/xpbar_filled"))
insert_all(assets, ImageAssetPair("images/button/perk"))
insert_all(assets, ImageAssetPair("images/button/perk_active"))
insert_all(assets, ImageAssetPair("images/button/button_bg"))
insert_all(assets, ImageAssetPair("images/button/button_bg_inactive"))
insert_all(assets, ImageAssetPair("images/button/achievement"))
insert_all(assets, ImageAssetPair("images/button/achievement_active"))
insert_all(assets, ImageAssetPair("images/button/checkbutton"))
insert_all(assets, ImageAssetPair("images/button/coinbutton"))
insert_all(assets, ImageAssetPair("images/button/config_act"))
insert_all(assets, ImageAssetPair("images/button/config_bg"))
insert_all(assets, ImageAssetPair("images/button/config_bigger"))
insert_all(assets, ImageAssetPair("images/button/config_smaller"))
insert_all(assets, ImageAssetPair("images/button/levelplus"))
insert_all(assets, ImageAssetPair("images/button/mainbutton_bg"))
insert_all(assets, ImageAssetPair("images/button/mainbutton_bg_achieve"))
insert_all(assets, ImageAssetPair("images/button/close"))
insert_all(assets, ImageAssetPair("images/button/playerimg/walter"))
insert_all(assets, ImageAssetPair("images/button/playerimg/wanda"))
insert_all(assets, ImageAssetPair("images/button/playerimg/warly"))
insert_all(assets, ImageAssetPair("images/button/playerimg/wathgrithr"))
insert_all(assets, ImageAssetPair("images/button/playerimg/waxwell"))
insert_all(assets, ImageAssetPair("images/button/playerimg/webber"))
insert_all(assets, ImageAssetPair("images/button/playerimg/wendy"))
insert_all(assets, ImageAssetPair("images/button/playerimg/wes"))
insert_all(assets, ImageAssetPair("images/button/playerimg/who"))
insert_all(assets, ImageAssetPair("images/button/playerimg/wickerbottom"))
insert_all(assets, ImageAssetPair("images/button/playerimg/willow"))
insert_all(assets, ImageAssetPair("images/button/playerimg/wilson"))
insert_all(assets, ImageAssetPair("images/button/playerimg/winona"))
insert_all(assets, ImageAssetPair("images/button/playerimg/wolfgang"))
insert_all(assets, ImageAssetPair("images/button/playerimg/wonkey"))
insert_all(assets, ImageAssetPair("images/button/playerimg/woodie"))
insert_all(assets, ImageAssetPair("images/button/playerimg/wormwood"))
insert_all(assets, ImageAssetPair("images/button/playerimg/wortox"))
insert_all(assets, ImageAssetPair("images/button/playerimg/wurt"))
insert_all(assets, ImageAssetPair("images/button/playerimg/wx78"))
insert_all(assets, ImageAssetPair("images/hud/close_button"))
insert_all(assets, ImageAssetPair("images/hud/main_button"))
insert_all(assets, ImageAssetPair("images/hud/small_bg"))
insert_all(assets, ImageAssetPair("images/hud/hint_bg"))
insert_all(assets, ImageAssetPair("images/hud/guide_button_huge"))
insert_all(assets, ImageAssetPair("images/hud/guide_button_big"))
insert_all(assets, ImageAssetPair("images/hud/guide_button"))
insert_all(assets, ImageAssetPair("images/hud/small_star"))
insert_all(assets, ImageAssetPair("images/hud/star"))
insert_all(assets, ImageAssetPair("images/hud/ach/ach_bg"))
insert_all(assets, ImageAssetPair("images/hud/ach/ach_info_bg"))
insert_all(assets, ImageAssetPair("images/hud/ach/ach_pin_button"))
insert_all(assets, ImageAssetPair("images/hud/ach/ach_hint_button"))
insert_all(assets, ImageAssetPair("images/hud/ach/ach_info_button"))
insert_all(assets, ImageAssetPair("images/hud/ach/ach_text_bg_1"))
insert_all(assets, ImageAssetPair("images/hud/ach/ach_text_bg_2"))
insert_all(assets, ImageAssetPair("images/hud/level/level_attr_button"))
insert_all(assets, ImageAssetPair("images/hud/level/level_bar"))
insert_all(assets, ImageAssetPair("images/hud/level/level_bar_bg"))
insert_all(assets, ImageAssetPair("images/hud/level/level_bar_fill"))
insert_all(assets, ImageAssetPair("images/hud/level/level_bg"))
insert_all(assets, ImageAssetPair("images/hud/main/main_ach_button"))
insert_all(assets, ImageAssetPair("images/hud/main/main_bar_fill"))
insert_all(assets, ImageAssetPair("images/hud/main/main_bg"))
insert_all(assets, ImageAssetPair("images/hud/main/main_bg_down_1"))
insert_all(assets, ImageAssetPair("images/hud/main/main_bg_down_2"))
insert_all(assets, ImageAssetPair("images/hud/main/main_bg_minimalist"))
insert_all(assets, ImageAssetPair("images/hud/main/main_bg_minimalist_down_2"))
insert_all(assets, ImageAssetPair("images/hud/main/main_bg_fill"))
insert_all(assets, ImageAssetPair("images/hud/main/main_level_button"))
insert_all(assets, ImageAssetPair("images/hud/main/main_perk_button"))
insert_all(assets, ImageAssetPair("images/hud/main/main_setting_button"))
insert_all(assets, ImageAssetPair("images/hud/main/main_task_button"))
insert_all(assets, ImageAssetPair("images/hud/main/main_trinket_2"))
insert_all(assets, ImageAssetPair("images/hud/main/ui_chasni_trinket_bg"))
insert_all(assets, ImageAssetPair("images/hud/main/main_zoom_bg"))
insert_all(assets, ImageAssetPair("images/hud/main/main_zoom_button_1"))
insert_all(assets, ImageAssetPair("images/hud/main/main_zoom_button_2"))
insert_all(assets, ImageAssetPair("images/hud/main/main_minimize_button"))
insert_all(assets, ImageAssetPair("images/hud/perk/perk_bg"))
insert_all(assets, ImageAssetPair("images/hud/perk/perk_text_bg_1"))
insert_all(assets, ImageAssetPair("images/hud/perk/perk_text_bg_2"))
insert_all(assets, ImageAssetPair("images/hud/task/task_bar"))
insert_all(assets, ImageAssetPair("images/hud/task/task_bar_acc"))
insert_all(assets, ImageAssetPair("images/hud/task/task_bar_bg"))
insert_all(assets, ImageAssetPair("images/hud/task/task_bar_fill"))
insert_all(assets, ImageAssetPair("images/hud/task/task_bg"))
insert_all(assets, ImageAssetPair("images/hud/task/task_check"))
insert_all(assets, ImageAssetPair("images/hud/task/task_check_bg"))
insert_all(assets, ImageAssetPair("images/hud/task/task_chest_close"))
insert_all(assets, ImageAssetPair("images/hud/task/task_chest_open"))
insert_all(assets, ImageAssetPair("images/hud/task/task_text_bg"))
insert_all(assets, ImageAssetPair("images/hud/activeskill/perk_bp"))
insert_all(assets, ImageAssetPair("images/hud/activeskill/perk_atom"))
insert_all(assets, ImageAssetPair("images/hud/activeskill/perk_trash"))
insert_all(assets, ImageAssetPair("images/hud/activeskill/perk_map"))

insert_all(assets, SoundAssetPair("sound/DLChasni"))
insert_all(assets, SoundAssetPair("sound/chasni_critter"))

insert_all(assets, Asset("ANIM", "anim/ui_largechest_5x5.zip"))
insert_all(assets, Asset("ANIM", "anim/ui_1x1.zip"))
insert_all(assets, Asset("ANIM", "anim/ui_chasni_trinket_1x1.zip"))
insert_all(assets, Asset("ANIM", "anim/ui_cookpot_2x4.zip"))

---------------------------------------------------
-- SINGLE PERK GROUPS
---------------------------------------------------

local groups = {
    ["klaussackbuilder"] = {
        ImageAssetPair("images/inventoryimages/klaussack"),
    },
    ["dencraft"] = {
        ImageAssetPair("images/prefabs/dens/nest"),
        ImageAssetPair("images/prefabs/dens/rabbit_hole"),
        ImageAssetPair("images/prefabs/dens/tallbirdnest"),
        ImageAssetPair("images/prefabs/dens/houndmound"),
        ImageAssetPair("images/prefabs/dens/molehill"),
        ImageAssetPair("images/prefabs/dens/catcoonden"),
        ImageAssetPair("images/prefabs/dens/monkeybarrel"),
        ImageAssetPair("images/prefabs/dens/slurtlehole"),
        ImageAssetPair("images/prefabs/dens/wasphive"),
        ImageAssetPair("images/prefabs/dens/walrus_camp"),
        ImageAssetPair("images/prefabs/dens/oceanvine_cocoon"),
        ImageAssetPair("images/prefabs/dens/spiderhole"),
        ImageAssetPair("images/prefabs/dens/moonspiderden"),
    },
    ["clustercraft"] = {
        ImageAssetPair("images/inventoryimages/cluster"),
    },
    ["multicraft"] = {
        ImageAssetPair("images/inventoryimages/multicraft"),
    },
    ["duppercritter"] = {
        ImageAssetPair("images/inventoryimages/chasni_critter"),
    },
    ["bosshunting"] = {
        ImageAssetPair("images/inventoryimages/tinker_tower_big"),

        Asset("ATLAS", "images/inventoryimages/watches_colour.xml"),
        Asset("ATLAS", "images/inventoryimages/watches_colour_icon.xml"),
        Asset("ATLAS", "images/inventoryimages/chasni_drawing.xml"),

        Asset("ANIM", "anim/frostbitten_overlay.zip"),
    },
    ["groundedscream"] = {
        ImageAssetPair("images/inventoryimages/cz_carrot_planted"),
    },
    ["expertwaxwell4"] = {
        Asset("ATLAS", "images/inventoryimages/chasni_spell_icons.xml"),
    },
    ["expertwendy2"] = {
        Asset("ANIM", "anim/chasni_abigail_vial_ui.zip"),
    },
    ["expertwendy3"] = {
        ImageAssetPair("images/hud/wendy_hud"),
        ImageAssetPair("images/hud/sisturn_button1"),
        ImageAssetPair("images/hud/sisturn_button2"),
    },
    ["expertwoodie1"] = {
        ImageAssetPair("images/hud/wortox_hud"),
        ImageAssetPair("images/hud/goose_button"),
        ImageAssetPair("images/hud/beaver_button"),
        ImageAssetPair("images/hud/moose_button"),
    },
    ["expertwillow4"] = {
        Asset("ANIM", "anim/chasni_spell_icons_willow.zip"),
    },
    ["expertwathg2"] = {
        Asset("ANIM", "anim/chasni_status_wathgrithr.zip"),
    },
    ["expertwinona1"] = {
        Asset("ANIM", "anim/player_wagstaff.zip"),
    },
    ["expertwalter3"] = {
        Asset("ANIM", "anim/player_actions_hand_lens.zip"),
        Asset("ANIM", "anim/player_actions_telescope.zip"),
    },
    ["expertwarly3"] = {
        Asset("ANIM", "anim/player_actions_panning.zip"),
    },
    ["expertwx1"] = {
        Asset("ANIM", "anim/chasni_status_wx.zip"),
        Asset("ANIM", "anim/chasni_status_wx_chest.zip"),
    },
    ["expertwx4"] = {
        Asset("ANIM", "anim/chasni_wx_chip.zip"),
        Asset("ANIM", "anim/chasni_status_wx_chip.zip"),
        Asset("ANIM", "anim/chasni_status_wx_chest_chip.zip"),
        Asset("ATLAS", "images/inventoryimages/chasni_chip.xml"),
    },
}

---------------------------------------------------
-- MULTI PERK GROUPS (UNCHANGED STRUCTURE)
---------------------------------------------------

local multi_groups = {
    --{
    --    perks = {"perk1", "perk2"},
    --    items = {
    --        ImageAssetPair("images/prefabs/dens/rabbit_hole"),
    --        ImageAssetPair("images/prefabs/dens/robin_egg"),
    --        ImageAssetPair("images/prefabs/dens/robin"),
    --        ImageAssetPair("images/prefabs/dens/robin_stone"),
    --    }
    --}
}

---------------------------------------------------
-- APPLY SINGLE PERK GROUPS
---------------------------------------------------

for perk, asset_list in pairs(groups) do
    if not chasni_getperkexcludeconfig(perk) then
        for _, v in ipairs(asset_list) do
            insert_all(assets, v)
        end
    end
end

---------------------------------------------------
-- APPLY MULTI PERK GROUPS
---------------------------------------------------

for _, group in ipairs(multi_groups) do
    if not chasni_getperkexcludeconfig(unpack(group.perks)) then
        for _, v in ipairs(group.items) do
            insert_all(assets, v)
        end
    end
end

---------------------------------------------------
---
---
--czcc("chasni_critter_fish_burn_a") ranged
--czcc("chasni_critter_fish_burn_b") ranged
--czcc("chasni_critter_fish_wet_a") ranged
--czcc("chasni_critter_fish_wet_b") ranged
--czcc("chasni_critter_light_off_a") aoe
--czcc("chasni_critter_light_off_b") aoe
--czcc("chasni_critter_light_on_a") aoe
--czcc("chasni_critter_light_on_b") aoe
--czcc("chasni_critter_mamo_a") aoe
--czcc("chasni_critter_mamo_b")
--czcc("chasni_critter_moo")
--czcc("chasni_critter_moodeng")
--czcc("chasni_critter_mosq_a") noattack
--czcc("chasni_critter_mosq_b")
--czcc("chasni_critter_puff_health_a") noattack
--czcc("chasni_critter_puff_health_b") noattack
--czcc("chasni_critter_puff_hunger_a") noattack
--czcc("chasni_critter_puff_hunger_b") noattack
--czcc("chasni_critter_puff_insanity_a") noattack
--czcc("chasni_critter_puff_insanity_b") noattack
--czcc("chasni_critter_puff_sanity_a") noattack
--czcc("chasni_critter_puff_sanity_b") noattack
--czcc("chasni_critter_raptor_a") noattack
--czcc("chasni_critter_raptor_b") ranged
--czcc("chasni_critter_wool_a") ranged
--czcc("chasni_critter_wool_b") ranged

--czcc("chasni_critter_seal_a") noattack
--czcc("chasni_critter_seal_b")
--czcc("chasni_critter_slug_star_a") noattack
--czcc("chasni_critter_slug_star_b") ranged
--czcc("chasni_critter_slug_xp_a") noattack
--czcc("chasni_critter_slug_xp_b") ranged
--czcc("chasni_critter_stego_a") repeat
--czcc("chasni_critter_worm_a")
--czcc("chasni_critter_worm_b")
return assets