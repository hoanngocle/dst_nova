local Defs = require("tbc_affix/defs")
local Stone = require("tbc_affix/stone")

local assets = {
    Asset("ANIM", "anim/hh_items.zip"),
    Asset("ANIM", "anim/hh_vat_pham_ground_so_1.zip"),
    Asset("ANIM", "anim/hh_phuc_lac_duoc.zip"),
    Asset("ATLAS", "images/vat_pham_inventory_so_1.xml"),
    Asset("IMAGE", "images/vat_pham_inventory_so_1.tex"),
    Asset("ATLAS", "images/hh_icon/hh_items.xml"),
    Asset("IMAGE", "images/hh_icon/hh_items.tex"),
    Asset("ATLAS", "images/phuc_lac_duoc_inventory.xml"),
    Asset("IMAGE", "images/phuc_lac_duoc_inventory.tex"),
    Asset("ATLAS", "images/inventoryimages/ttk_refreshstone.xml"),
    Asset("IMAGE", "images/inventoryimages/ttk_refreshstone.tex"),
    Asset("ATLAS", "images/inventoryimages/ttk_cleanstone.xml"),
    Asset("IMAGE", "images/inventoryimages/ttk_cleanstone.tex"),
}
for _, row in ipairs(Defs.rows) do
    local atlas = "images/tbc_affixes/" .. row.image_id .. ".xml"
    assets[#assets + 1] = Asset("ATLAS", atlas)
    assets[#assets + 1] = Asset("IMAGE", "images/tbc_affixes/" .. row.image_id .. ".tex")
    RegisterInventoryItemAtlas(atlas, row.image_id .. ".tex")
end

local material_atlas = "images/vat_pham_inventory_so_1.xml"
local effect_atlas = "images/hh_icon/hh_items.xml"
local potion_atlas = "images/phuc_lac_duoc_inventory.xml"
local refresh_atlas = "images/inventoryimages/ttk_refreshstone.xml"
local clean_atlas = "images/inventoryimages/ttk_cleanstone.xml"
local definitions = {
    wb_enhancegem = { icon = "da_cuong_hoa_inventory", atlas = material_atlas, anim = "idle_da_cuong_hoa", stack = true },
    hh_effect_stone = { icon = "hh_effect_stone", atlas = effect_atlas, anim = "idle", stack = false },
    hh_effect_tally = { icon = "giay_thuoc_tinh_inventory", atlas = material_atlas, anim = "idle_giay_thuoc_tinh", stack = true },
    hh_remove_stone = { icon = "luc_bao_thach_inventory", atlas = material_atlas, anim = "idle_luc_bao_thach", stack = true },
    hh_essence = { icon = "linh_thach_inventory", atlas = material_atlas, anim = "idle_linh_thach", stack = true },
    ac_refreshstone = { icon = "ttk_refreshstone", atlas = refresh_atlas, anim = "idle", stack = true },
    ad_cleanstone = { icon = "ttk_cleanstone", atlas = clean_atlas, anim = "idle", world_symbol = "hh_remove_stone", stack = true },
    nn_magicpaper = { icon = "bua_ma_thuat_inventory", atlas = material_atlas, anim = "idle_giay_thuoc_tinh", stack = true },
    wb_strengthen_strengthen_protectpaper = { icon = "bua_bao_ve_inventory", atlas = material_atlas, anim = "idle_giay_thuoc_tinh", stack = true },
    nn_liquidluck = { icon = "phuc_lac_duoc_1_inventory", atlas = potion_atlas, anim = "idle_phuc_lac_duoc_1", bank = "hh_phuc_lac_duoc", luck = 1 },
    nn_liquidluck_2 = { icon = "phuc_lac_duoc_2_inventory", atlas = potion_atlas, anim = "idle_phuc_lac_duoc_2", bank = "hh_phuc_lac_duoc", luck = 2 },
    nn_liquidluck_3 = { icon = "phuc_lac_duoc_3_inventory", atlas = potion_atlas, anim = "idle_phuc_lac_duoc_3", bank = "hh_phuc_lac_duoc", luck = 3 },
    wb_strengthen_clearpaper = { icon = "papyrus", anim = "idle_giay_thuoc_tinh" },
}
for level = 6, 12 do
    definitions["wb_strengthen_strengthen_" .. level .. "_levelpaper"] = {
        icon = "sketch", anim = "idle_giay_thuoc_tinh",
    }
end

local function MakeItem(prefab, definition)
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        MakeInventoryPhysics(inst)
        local bank = definition.bank or (definition.anim == "idle" and "hh_items" or "hh_vat_pham_ground_so_1")
        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(bank)
        inst.AnimState:PlayAnimation(definition.anim, true)
        if definition.world_symbol ~= nil then
            inst.AnimState:OverrideSymbol("hh_remove_stone", bank, definition.world_symbol)
        end
        if prefab == "hh_effect_stone" then Stone.Init(inst) end
        MakeInventoryFloatable(inst, "small", 0.1, 0.8)
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then return inst end
        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = definition.icon
        inst.components.inventoryitem.atlasname = definition.atlas or "images/inventoryimages.xml"
        if definition.stack then
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
        end
        if definition.luck ~= nil then
            inst:AddComponent("edible")
            inst.components.edible.foodtype = FOODTYPE.GOODIES
            inst.components.edible.hungervalue = 0
            inst.components.edible.healthvalue = 0
            inst.components.edible.sanityvalue = definition.luck * 5
            inst.components.edible.oneaten = function(_, eater)
                local luck = eater.components ~= nil and eater.components.tbc_luck or nil
                if luck ~= nil then
                    local applied = luck:Apply(definition.luck)
                    if eater.components.talker ~= nil then
                        eater.components.talker:Say(applied and "Phúc Lạc Dược đã có hiệu lực"
                            or "Đang có Phúc Lạc Dược mạnh hơn")
                    end
                end
            end
        end
        if prefab == "hh_effect_stone" then Stone.AttachServer(inst) end
        return inst
    end
    if definition.atlas ~= nil then
        RegisterInventoryItemAtlas(definition.atlas, definition.icon .. ".tex")
    end
    return Prefab(prefab, fn, assets)
end

local prefabs = {}
for id, definition in pairs(definitions) do
    prefabs[#prefabs + 1] = MakeItem(id, definition)
end
return unpack(prefabs)
