-- Sáu tiện ích cố định được tách từ Phàm Nhân Tu Tiên.
Assets = {}

modimport("main/ttk_stacksize.lua")
modimport("main/ttk_qualityoflife.lua")
modimport("main/ttk_smarter_flingomatic.lua")

GLOBAL.ManifestManager:AddFileToModManifest(modname, "scripts/ttk_inventorysort.lua")
require("ttk_inventorysort").Install(env, {
    backpackCategory = GetModConfigData("ttk_backpack_category"),
})

modimport("main/ttk_inventory45.lua")
modimport("main/ttk_inventory45_compat.lua")

modimport("main/ttk_moreplantables.lua")
modimport("main/ttk_smart_minisign.lua")
GLOBAL.ManifestManager:AddFileToModManifest(modname, "scripts/ttk_item_detail.lua")
GLOBAL.ManifestManager:AddFileToModManifest(modname, "scripts/ttk_xd_hover.lua")
GLOBAL.ManifestManager:AddFileToModManifest(modname, "scripts/ttk_player_detail.lua")
local PlayerDetail = require("ttk_player_detail")
AddPlayerPostInit(function(inst) PlayerDetail.Attach(inst, GLOBAL) end)
modimport("main/ttk_item_detail.lua")
