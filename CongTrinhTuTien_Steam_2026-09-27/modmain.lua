-- Keep the prefab and RPC IDs from the separate mods so existing saves can
-- continue using their placed buildings after switching to this bundle.
Assets = {}
PrefabFiles = { "ttt_portal_gcsz_skin" }

for _, filename in GLOBAL.ipairs({
    "scripts/ttt_portal_skin.lua",
    "scripts/prefabs/ttt_portal_gcsz_skin.lua",
    "main/ttk_portal.lua",
    "main/ttk_lingshi_recycler.lua",
    "scripts/nova_lingshi_pricing.lua",
    "scripts/prefabs/nova_lingshi_recycler.lua",
    "anim/ttk_spirit_workshop.zip",
    "images/ttk_spirit_workshop/icon.xml",
    "images/ttk_spirit_workshop/icon.tex",
    "main/ttk_treasure.lua",
    "main/ttk_thien_nghich_chau.lua",
    "main/ttk_fsct.lua",
    "scripts/prefabs/ttk_fsct.lua",
    "anim/ttk_fsct.zip",
    "images/map_icons/ttk_fsct.xml",
    "images/map_icons/ttk_fsct.tex",
    "scripts/nova_treasure_logic.lua",
    "scripts/nova_treasure_rewards.lua",
    "scripts/prefabs/nova_treasure_scroll.lua",
    "scripts/prefabs/nova_treasure_site.lua",
    "anim/hh_items.zip",
    "anim/hh_vat_pham_ground_so_1.zip",
    "images/hh_icon/hh_items.xml",
    "images/hh_icon/hh_items.tex",
    "images/vat_pham_inventory_so_1.xml",
    "images/vat_pham_inventory_so_1.tex",
}) do
    GLOBAL.ManifestManager:AddFileToModManifest(modname, filename)
end

local eternal_fire_structures = {
    "deluxe_firepit", "endo_firepit", "heat_star", "ice_star",
}
local eternal_fire_prefabs = {
    "deluxe_firepit", "deluxe_firepit_fire", "endo_firepit", "endo_firepit_fire",
    "heat_star", "heat_star_flame", "ice_star", "ice_star_flame",
}
for _, name in GLOBAL.ipairs(eternal_fire_prefabs) do
    GLOBAL.ManifestManager:AddFileToModManifest(modname, "scripts/prefabs/" .. name .. ".lua")
    GLOBAL.ManifestManager:AddFileToModManifest(modname, "anim/" .. name .. ".zip")
end
for _, name in GLOBAL.ipairs(eternal_fire_structures) do
    for _, suffix in GLOBAL.ipairs({ "xml", "tex" }) do
        GLOBAL.ManifestManager:AddFileToModManifest(modname, "images/inventoryimages/" .. name .. "." .. suffix)
        GLOBAL.ManifestManager:AddFileToModManifest(modname, "minimap/" .. name .. "." .. suffix)
    end
end

GLOBAL.require("ttt_portal_skin").Install(env)
modimport("main/ttk_portal.lua")
modimport("main/ttk_lingshi_recycler.lua")
modimport("main/ttk_treasure.lua")
modimport("main/ttk_thien_nghich_chau.lua")
modimport("main/ttk_fsct.lua")
modimport("main/ttk_eternal_fire.lua")

-- Super Wall DST keeps its prefab and world-save IDs. Its source modmain
-- assigns new Assets and PrefabFiles tables, so merge those back afterwards.
GLOBAL.ManifestManager:AddFileToModManifest(modname, "scripts/ttk_superwall_files.lua")
for _, filename in GLOBAL.ipairs(GLOBAL.require("ttk_superwall_files")) do
    GLOBAL.ManifestManager:AddFileToModManifest(modname, filename)
end
local existing_assets, existing_prefabs = Assets, PrefabFiles
modimport("main/ttk_superwall.lua")
local superwall_assets, superwall_prefabs = Assets, PrefabFiles
Assets, PrefabFiles = existing_assets, existing_prefabs
for _, asset in GLOBAL.ipairs(superwall_assets) do
    Assets[#Assets + 1] = asset
end
for _, prefab in GLOBAL.ipairs(superwall_prefabs) do
    PrefabFiles[#PrefabFiles + 1] = prefab
end

-- Carpet registers its 15 PY_CARPET tile IDs in modworldgenmain.lua.
-- Its source modmain assigns a new Assets table, so append those assets here.
GLOBAL.ManifestManager:AddFileToModManifest(modname, "scripts/ttk_carpet_files.lua")
for _, filename in GLOBAL.ipairs(GLOBAL.require("ttk_carpet_files")) do
    GLOBAL.ManifestManager:AddFileToModManifest(modname, filename)
end
local existing_carpet_assets = Assets
modimport("main/ttk_carpet.lua")
local carpet_assets = Assets
Assets = existing_carpet_assets
for _, asset in GLOBAL.ipairs(carpet_assets) do
    Assets[#Assets + 1] = asset
end
