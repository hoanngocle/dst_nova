local G = GLOBAL
local Rules = require("tbc_rules")
local Catalog = require("tbc_catalog")
local Defs = require("tbc_affix/defs")
local Stone = require("tbc_affix/stone")
local Slots = require("tbc_affix/slots")
local Coordinator = require("tbc_affix/coordinator")
local EquipmentContainers = require("tbc_equipment/containers")
local EquipmentOperations = require("tbc_equipment/operations")
local EquipmentInstall = require("tbc_equipment/install")
local EquipmentWalletDrops = require("tbc_equipment/wallet_drops")
local FastAct = require("tbc_equipment/fast_act")
require("tbc_equipment/compat").SetRpcNamespace(modname)
local DetailHooks = require("tbc_detail_hooks")
local Combat = require("tbc_combat")
local MonsterScaling = require("tbc_monster_scaling")
local achievement_enabled = G.KnownModIndex ~= nil
    and G.KnownModIndex:IsModEnabled("Achivement") or false
local standalone_scaling_enabled = G.KnownModIndex ~= nil
    and G.KnownModIndex:IsModEnabled("TuTienMonsterScaling") or false
local solo_hover_enabled = G.KnownModIndex ~= nil
    and G.KnownModIndex:IsModEnabled("workshop-3780347550") or false
local utility_detail_enabled = G.KnownModIndex ~= nil
    and G.KnownModIndex:IsModEnabled("TienIchTuTien") or false
G.TTK_EQUIPMENT_DETAIL_SOURCE = {
    max_affixes = Defs.MAX_SLOTS,
    by_code = Defs.by_code,
    solo_by_code = require("tbc_equipment/solo_defs").Affixes,
    value_text = Defs.ValueText,
    description = Stone.Description,
    stone_detail = Stone.Detail,
    stone_colour = Stone.Colour,
    weapon_preview = require("tbc_strengthen_effects").Preview,
}

PrefabFiles = { "tbc_items", "tbc_forge", "tbc_equipment_container", "tbc_suit_build",
    "tbc_strengthen_shadow", "tbc_strengthen_light" }

Assets = {
    Asset("ATLAS", "images/lo_ren.xml"), Asset("IMAGE", "images/lo_ren.tex"),
    Asset("ATLAS", "images/vat_pham_inventory_so_1.xml"), Asset("IMAGE", "images/vat_pham_inventory_so_1.tex"),
    Asset("ATLAS", "images/inventoryimages/ttk_huyen_tinh_cuc_pham.xml"),
    Asset("IMAGE", "images/inventoryimages/ttk_huyen_tinh_cuc_pham.tex"),
    Asset("ATLAS", "images/hh_icon/hh_items.xml"), Asset("IMAGE", "images/hh_icon/hh_items.tex"),
    Asset("ATLAS", "images/phuc_lac_duoc_inventory.xml"), Asset("IMAGE", "images/phuc_lac_duoc_inventory.tex"),
    Asset("ATLAS", "images/ttk_forge/frame.xml"), Asset("IMAGE", "images/ttk_forge/frame.tex"),
    Asset("ATLAS", "images/ttk_forge/controls.xml"), Asset("IMAGE", "images/ttk_forge/controls.tex"),
    Asset("ATLAS", "images/ttk_forge/strengthen.xml"), Asset("IMAGE", "images/ttk_forge/strengthen.tex"),
    Asset("ATLAS", "images/ttk_forge/close_icon.xml"), Asset("IMAGE", "images/ttk_forge/close_icon.tex"),
    Asset("ATLAS", "images/ttk_forge/equipment_buttons/add.xml"),
    Asset("IMAGE", "images/ttk_forge/equipment_buttons/add.tex"),
    Asset("ATLAS", "images/ttk_forge/equipment_buttons/remove.xml"),
    Asset("IMAGE", "images/ttk_forge/equipment_buttons/remove.tex"),
    Asset("ATLAS", "images/ttk_forge/equipment_buttons/reroll.xml"),
    Asset("IMAGE", "images/ttk_forge/equipment_buttons/reroll.tex"),
}
for _, name in ipairs({ "inherit", "reroll", "line1", "line2", "line3", "line4", "line5", "clean" }) do
    local path = "images/ttk_forge/suit_buttons/" .. name
    Assets[#Assets + 1] = Asset("ATLAS", path .. ".xml")
    Assets[#Assets + 1] = Asset("IMAGE", path .. ".tex")
end
AddMinimapAtlas("images/lo_ren.xml")
Assets[#Assets + 1] = Asset("ATLAS", "images/hh_icon/hh_suit_build.xml")
Assets[#Assets + 1] = Asset("IMAGE", "images/hh_icon/hh_suit_build.tex")
AddMinimapAtlas("images/hh_icon/hh_suit_build.xml")

-- Carry the two existing standalone sword sets in this mod. Their prefab IDs
-- stay stable so previously saved weapons continue to load.
if modimport ~= nil then
    for _, path in ipairs({
        "scripts/tbc_combat.lua", "scripts/tbc_combat_math.lua",
        "scripts/tbc_strengthen_effects.lua",
        "scripts/components/chasnicritchancer.lua",
        "scripts/ttk_lucnguyen_combat.lua", "scripts/ttk_lucnguyen_rules.lua",
        "scripts/ttk_elemental_combat.lua", "scripts/ttk_weapon_damage.lua",
        "scripts/ttk_tinhlakiem_repair.lua",
        "scripts/ttk_skins.lua", "scripts/combat/hh_combat_context.lua",
        "scripts/prefabs/lucmachthankiem_defs.lua",
        "scripts/util/lucmachthankiem_solo.lua",
        "scripts/components/lucmachthankiem_recharge.lua",
    }) do
        G.ManifestManager:AddFileToModManifest(modname, path)
    end
    modimport("main/ttk_elemental_swords.lua")
    modimport("main/ttk_tinhlakiem.lua")
    modimport("main/ttk_lucnguyenkiemdong.lua")
    modimport("main/ttk_vankiemquytong.lua")
    modimport("main/lucmachthankiem.lua")
    modimport("main/ttk_weapon_solo.lua")
    modimport("main/ttk_solo_six.lua")
    modimport("main/tbc_damagefx.lua")
end

local function GetRealmWorld()
    local world = G.TheWorld
    return world ~= nil and world.components ~= nil
        and world.components.realm_monster_world or nil
end

local function ObserveRealmPlayer(inst)
    if not inst:IsValid() then return end
    local realm = inst.components ~= nil and inst.components.xd_level or nil
    local world = GetRealmWorld()
    if realm == nil or world == nil then return end

    world:SetMaxLevel(realm.level)
    if realm._tbc_realm_wrapped then return end
    realm._tbc_realm_wrapped = true
    local original = realm.SetLevel
    realm.SetLevel = function(self, ...)
        local results = { original(self, ...) }
        local component = GetRealmWorld()
        if component ~= nil then component:SetMaxLevel(self.level) end
        return G.unpack(results)
    end
end

if not standalone_scaling_enabled then
    AddPrefabPostInit("world", function(inst)
        if not inst.ismastersim then return end
        inst:AddComponent("realm_monster_world")
        inst:DoTaskInTime(0, function()
            local original = inst.components.xd_worldlevel
            if original ~= nil then
                inst.components.realm_monster_world:SetMaxLevel(
                    original:GetWorldLevel())
            end
        end)
        inst:DoPeriodicTask(5, function()
            local original = inst.components.xd_worldlevel
            if original ~= nil then
                inst.components.realm_monster_world:SetMaxLevel(
                    original:GetWorldLevel())
            end
            for _, player in ipairs(G.AllPlayers or {}) do
                ObserveRealmPlayer(player)
            end
        end)
    end)
    AddPlayerPostInit(function(inst)
        if G.TheWorld == nil or not G.TheWorld.ismastersim then return end
        inst:DoTaskInTime(0, ObserveRealmPlayer)
        inst:DoTaskInTime(1, ObserveRealmPlayer)
    end)
end

if AddComponentPostInit ~= nil then
    Combat.RegisterSpDamage()
    if solo_hover_enabled then DetailHooks.InstallSoloBuffRows(AddComponentPostInit) end
    AddComponentPostInit("combat", function(component)
        if G.TheWorld.ismastersim then
            Combat.Install(component, achievement_enabled)
        end
    end)
end
local containers = require("containers")
containers.params.tbc_forge = {
    widget = {
        slotpos = {
            G.Vector3(-198, 50, 0),
            G.Vector3(-250, -95, 0),
            G.Vector3(-145, -95, 0),
            G.Vector3(-40, -95, 0),
        }, pos = G.Vector3(0, 0, 0), top_align_tip = 50,
        animbank = "ui_bundle_2x2", animbuild = "ui_bundle_2x2",
    },
    openlimit = 1,
    usespecificslotsforitems = true,
    type = "cooker",
    itemtestfn = function(_, item, slot)
        if item == nil then return false end
        if slot == 2 or (slot == nil and item.prefab == "nn_magicpaper") then
            return item.prefab == "nn_magicpaper"
        end
        if slot == 3 or (slot == nil and item.prefab == "wb_strengthen_strengthen_protectpaper") then
            return item.prefab == "wb_strengthen_strengthen_protectpaper"
        end
        if slot == 4 or (slot == nil and item.prefab == "wb_enhancegem") then
            return item.prefab == "wb_enhancegem"
        end
        return (slot == 1 or slot == nil) and ((item.components ~= nil and item.components.tbc_upgrade ~= nil)
            or (item.replica ~= nil and item.replica.equippable ~= nil
                and (item:HasTag("weapon") or item:HasTag("armor") or item:HasTag("tbc_upgradeable"))))
    end,
}
containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, 4)
EquipmentContainers.RegisterParams(containers, G.Vector3)

if not G.TheNet:IsDedicated() then
    require("tbc_ui_hooks").Install(AddClassPostConstruct, modname)
    DetailHooks.Install(AddClassPostConstruct, G.STRINGS.NAMES,
        solo_hover_enabled, utility_detail_enabled)
end

local names = {
    wb_enhancegem = "Huyền Tinh Cực Phẩm",
    ttk_huyen_tinh_ha_pham = "Huyền Tinh Hạ Phẩm",
    ttk_huyen_tinh_trung_pham = "Huyền Tinh Trung Phẩm",
    ttk_huyen_tinh_thuong_pham = "Huyền Tinh Thượng Phẩm",
    hh_effect_stone = "Đá Thuộc Tính",
    hh_effect_tally = "Giấy Thuộc Tính",
    hh_remove_stone = "Lục Bảo Thạch",
    hh_essence = "Linh Thạch",
    ac_refreshstone = "Đá Đổi Thuộc Tính",
    ad_cleanstone = "Đá Tẩy Thuộc Tính",
    nn_magicpaper = "Bùa Giữ Cấp",
    wb_strengthen_strengthen_protectpaper = "Bùa Bảo Vệ",
    tbc_forge = "Lò Rèn Trang Bị",
    tbc_suit_build = "Hợp Thành Đài",
    nn_liquidluck = "Phúc Lạc Dược I",
    nn_liquidluck_2 = "Phúc Lạc Dược II",
    nn_liquidluck_3 = "Phúc Lạc Dược III",
    wb_strengthen_clearpaper = "Cuộn Tẩy Tủy",
}
for level = 6, 12 do
    names["wb_strengthen_strengthen_" .. level .. "_levelpaper"] = "Cuộn Cường Hóa +" .. level
end
for id, name in pairs(names) do
    G.STRINGS.NAMES[string.upper(id)] = name
    G.STRINGS.CHARACTERS.GENERIC.DESCRIBE[string.upper(id)] = name
end
G.STRINGS.RECIPE_DESC.TBC_FORGE = "Đặt vũ khí hoặc giáp vào lò để cường hóa"
G.STRINGS.RECIPE_DESC.TBC_SUIT_BUILD = "Kế thừa, tẩy và ngẫu luyện trang bị"

local function SyncEquipmentWallet(player)
    local wallet = player.components ~= nil and player.components.tbc_equipment_wallet or nil
    if wallet == nil or SendModRPCToClient == nil or CLIENT_MOD_RPC == nil
        or CLIENT_MOD_RPC[modname] == nil
        or CLIENT_MOD_RPC[modname].tbc_equipment_wallet == nil
        or player.userid == nil then return end
    for id, count in pairs(wallet.items) do
        SendModRPCToClient(CLIENT_MOD_RPC[modname].tbc_equipment_wallet,
            player.userid, id, count)
    end
end

if AddClientModRPCHandler ~= nil then
    AddClientModRPCHandler(modname, "tbc_equipment_client_value", function(key, value)
        local player = G.ThePlayer
        if player == nil then return end
        if key == "hh_fast_act" then
            player._tbc_solo_fast_act = value == true
        elseif key == "hh_atk_speed" then
            player._tbc_solo_attack_speed = G.tonumber(value) or 0
        end
    end)
    AddClientModRPCHandler(modname, "tbc_equipment_wallet", function(id, count)
        local player = G.ThePlayer
        if player == nil or type(id) ~= "string" or type(count) ~= "number" then return end
        player._tbc_wallet = player._tbc_wallet or {}
        player._tbc_wallet[id] = count
        player:PushEvent("tbc_wallet_dirty")
    end)
end

AddPlayerPostInit(function(inst)
    if G.TheWorld.ismastersim then
        Coordinator.WatchPlayer(inst)
        if inst.components.tbc_luck == nil then inst:AddComponent("tbc_luck") end
        if inst.components.tbc_equipment_wallet == nil then inst:AddComponent("tbc_equipment_wallet") end
        if inst.components.tbc_player_effects == nil then inst:AddComponent("tbc_player_effects") end
        inst:ListenForEvent("tbc_wallet_dirty", SyncEquipmentWallet)
        if achievement_enabled and inst.components.chasnicritchancer == nil then
            inst:AddComponent("chasnicritchancer")
        end
    end
end)

local function Say(player, message)
    local talker = player ~= nil and player.components ~= nil and player.components.talker or nil
    if talker ~= nil then talker:Say(message) end
end

AddModRPCHandler(modname, "tbc_equipment_use", function(player, box, operation, arg)
    if not G.TheWorld.ismastersim or player == nil or box == nil
        or not box:IsValid() or (box.prefab ~= "tbc_equipment_box"
            and box.prefab ~= "tbc_suit_build") then return end
    local ok, reason = EquipmentOperations.Execute(player, box, operation, arg)
    if not ok and reason ~= nil then
        local add_messages = {
            MISSING_EQUIPMENT_OR_STONE = "Cần đặt trang bị và đá/giấy thuộc tính vào hai ô.",
            MISSING_UPGRADE_COMPONENT = "Trang bị này không hỗ trợ đá thuộc tính.",
            AFFIX_ADD_FAILED = "Không thể thêm đá: sai loại, trùng thuộc tính hoặc đã đủ 3 dòng.",
            INVALID_AFFIX_STONE = "Đá thuộc tính chưa có thông tin hợp lệ.",
            INVALID_AFFIX_MATERIAL = "Vật liệu này không dùng để thêm thuộc tính.",
            NO_ELIGIBLE_AFFIX = "Không có thuộc tính phù hợp với trang bị này.",
        }
        local clean_messages = {
            INVALID_AFFIX_INDEX = "Dòng này chưa có thuộc tính.",
            MISSING_CLEAN_STONE = "Cần 1 Đá Tẩy Thuộc Tính trong túi Solo hoặc túi đồ.",
            MISSING_EQUIPMENT = "Đặt trang bị vào ô trước.",
        }
        Say(player, operation == "affix_add" and (add_messages[reason] or reason)
            or operation == "affix_clean" and (clean_messages[reason] or reason)
            or reason)
    end
    if ok then
        SyncEquipmentWallet(player)
        if operation == "affix_add" then Say(player, "Đã thêm thuộc tính vào trang bị.") end
        if operation == "affix_remove" then Say(player, "Đã tẩy ngẫu nhiên một dòng thuộc tính.") end
        if operation == "affix_reroll" then Say(player, "Đã đổi giá trị thuộc tính.") end
        if operation == "affix_clean" then Say(player, "Đã tẩy dòng " .. arg .. ".") end
        if operation == "inherit" then Say(player, "Đã kế thừa thuộc tính trang bị.") end
        if operation == "stone_reroll" then Say(player, "Đã ngẫu luyện Đá Thuộc Tính.") end
    end
end)

local function ConsumeOne(item)
    if item.components ~= nil and item.components.stackable ~= nil then
        local one = item.components.stackable:Get()
        if one ~= nil then one:Remove() end
    else
        item:Remove()
    end
end

local function ApplyItem(act)
    local player, item, target = act.doer, act.invobject, act.target
    if not G.TheWorld.ismastersim or player == nil or item == nil or target == nil
        or not player:IsValid() or not target:IsValid()
        or player.components.inventory == nil then return false end
    local upgrade = target.components ~= nil and target.components.tbc_upgrade or nil
    local station = act.tbc_station
    if upgrade == nil then
        return false
    end
    local owner = target.components.inventoryitem ~= nil and target.components.inventoryitem.owner or nil
    if station ~= nil then
        local container = station.components ~= nil and station.components.container or nil
        if not station:IsValid() or station.prefab ~= "tbc_forge" or container == nil
            or not container.openlist[player] or container:GetItemInSlot(1) ~= target
            or owner ~= station or player:GetDistanceSqToInst(station) > 16 then return false end
    elseif owner ~= nil and owner ~= player then
        return false
    elseif owner == nil and player.GetDistanceSqToInst ~= nil
        and player:GetDistanceSqToInst(target) > 16 then
        return false
    end
    local inventory = player.components.inventory
    local id = item.prefab
    local scroll_level = G.tonumber(string.match(id or "", "^wb_strengthen_strengthen_(%d+)_levelpaper$"))
    if scroll_level ~= nil and scroll_level >= 6 and scroll_level <= 12 then
        if upgrade.level ~= scroll_level - 1 then
            Say(player, "Cuộn +" .. scroll_level .. " cần trang bị đang ở +" .. (scroll_level - 1))
            return false
        end
        upgrade:SetLevel(scroll_level)
        ConsumeOne(item)
        Say(player, "Cường hóa tất thành +" .. scroll_level)
        return true
    elseif id == "wb_strengthen_clearpaper" then
        if upgrade.level == 0 then Say(player, "Trang bị chưa cường hóa") return false end
        upgrade:SetLevel(0)
        ConsumeOne(item)
        Say(player, "Đã đưa cấp cường hóa về 0")
        return true
    elseif id == "wb_enhancegem" then
        local cost = Rules.StrengthenCost(upgrade.level)
        if cost == nil then Say(player, "Trang bị đã cường hóa tối đa +16") return false end
        local container = station ~= nil and station.components.container or nil
        if container ~= nil then
            local stackable = item.components ~= nil and item.components.stackable or nil
            if container:GetItemInSlot(4) ~= item or stackable == nil or stackable:StackSize() < cost then
                Say(player, "Không đủ Huyền Tinh Cực Phẩm trong ô: cần " .. cost)
                return false
            end
        elseif not inventory:Has(id, cost) then
            Say(player, "Không đủ Huyền Tinh Cực Phẩm: cần " .. cost)
            return false
        end
        local protect_item = container ~= nil and container:GetItemInSlot(3) or nil
        local magic_item = container ~= nil and container:GetItemInSlot(2) or nil
        local protect = container ~= nil
            and protect_item ~= nil and protect_item.prefab == "wb_strengthen_strengthen_protectpaper"
            or container == nil and inventory:Has("wb_strengthen_strengthen_protectpaper", 1)
        local magic = container ~= nil
            and magic_item ~= nil and magic_item.prefab == "nn_magicpaper"
            or container == nil and inventory:Has("nn_magicpaper", 1)
        if container ~= nil then
            local spent = item.components.stackable:Get(cost)
            if spent ~= nil then spent:Remove() end
        else
            inventory:ConsumeByName(id, cost)
        end
        local luck = player.components.tbc_luck ~= nil and player.components.tbc_luck:GetBonus() or 0
        local level, success, destroyed = Rules.ResolveStrengthen(upgrade.level, math.random(), protect, magic, luck)
        if not success then
            if protect and upgrade.level >= 9 then
                if container ~= nil then
                    ConsumeOne(protect_item)
                else
                    inventory:ConsumeByName("wb_strengthen_strengthen_protectpaper", 1)
                end
            end
            if magic and upgrade.level >= 5 and (upgrade.level < 9 or protect) then
                if container ~= nil then
                    ConsumeOne(magic_item)
                else
                    inventory:ConsumeByName("nn_magicpaper", 1)
                end
            end
        end
        if destroyed then
            target:Remove()
            Say(player, "Cường hóa thất bại, trang bị bị phá hủy")
            return true
        end
        upgrade:SetLevel(level)
        Say(player, success and ("Cường hóa thành công +" .. level)
            or ("Cường hóa thất bại, còn +" .. level))
        return true
    elseif id == "hh_effect_stone" then
        Stone.OnReceived(item, player)
        local affix, value = Stone.Read(item)
        if not upgrade:AddAffix(affix, value) then
            Say(player, "Đá Thuộc Tính không phù hợp hoặc đã đầy")
            return false
        end
        ConsumeOne(item)
        Say(player, "Đã gắn " .. Defs.Format(affix, value))
        return true
    elseif id == "hh_effect_tally" then
        local realm = player.components.xd_level
        local level = realm ~= nil and realm.level or nil
        local affix, value = Catalog.RollAffix(level, nil, function(row)
            return Slots.CanAdd(target, upgrade.affixes, row)
        end)
        if affix == nil or not upgrade:AddAffix(affix, value) then
            Say(player, "Trang bị đã đầy thuộc tính") return false
        end
        ConsumeOne(item)
        Say(player, "Đã thêm " .. Defs.Format(affix, value))
        return true
    elseif id == "hh_remove_stone" then
        if not upgrade:RemoveRandomAffix() then Say(player, "Trang bị chưa có thuộc tính") return false end
        ConsumeOne(item)
        Say(player, "Đã xóa ngẫu nhiên một thuộc tính")
        return true
    elseif id == "ac_refreshstone" then
        if not upgrade:RerollAffix() then Say(player, "Trang bị chưa có thuộc tính") return false end
        ConsumeOne(item)
        Say(player, "Đã đổi giá trị các thuộc tính")
        return true
    elseif id == "ad_cleanstone" then
        local index = act.tbc_affix_index or #upgrade.affixes
        if not upgrade:RemoveAffixAt(index) then Say(player, "Trang bị chưa có thuộc tính") return false end
        ConsumeOne(item)
        Say(player, "Đã tẩy thuộc tính số " .. index)
        return true
    end
    return false
end

local apply = AddAction("TBC_APPLY", "Cường hóa / thuộc tính", ApplyItem)
apply.rmb = true
apply.priority = 5
AddComponentAction("USEITEM", "inventoryitem", function(item, doer, target, actions)
    if target == nil or not ((target.replica ~= nil and target.replica.equippable ~= nil)
        or (target.components ~= nil and target.components.equippable ~= nil)
        or target:HasTag("tbc_upgradeable")) then return end
    local id = item.prefab
    if id == "wb_enhancegem" or id == "wb_strengthen_clearpaper"
        or (string.match(id or "", "^wb_strengthen_strengthen_%d+_levelpaper$") ~= nil)
        or id == "hh_effect_stone" or id == "hh_effect_tally"
        or id == "hh_remove_stone" or id == "ac_refreshstone" or id == "ad_cleanstone" then
        table.insert(actions, G.ACTIONS.TBC_APPLY)
    end
end)
AddStategraphActionHandler("wilson", G.ActionHandler(apply, "give"))
AddStategraphActionHandler("wilson_client", G.ActionHandler(apply, "give"))
if AddStategraphPostInit ~= nil then
    for _, graph in ipairs({"wilson", "wilson_client"}) do
        AddStategraphPostInit(graph, function(sg)
            FastAct.WrapStategraph(sg,
                {G.ACTIONS.PICK, G.ACTIONS.TAKEITEM, G.ACTIONS.HARVEST})
        end)
    end
end

local function ForgeUse(player, station, operation)
    if not G.TheWorld.ismastersim or player == nil or station == nil or not station:IsValid()
        or station.prefab ~= "tbc_forge" or player.components.inventory == nil
        or operation ~= "strengthen" then return false end
    local container = station.components.container
    if container == nil or not container.openlist[player] or player:GetDistanceSqToInst(station) > 16 then return false end
    local target = container:GetItemInSlot(1)
    local upgrade = target ~= nil and target.components.tbc_upgrade or nil
    if upgrade == nil then Say(player, "Đặt trang bị vào ô Lò Rèn") return false end
    local material = container:GetItemInSlot(4)
    if material == nil or material.prefab ~= "wb_enhancegem" then
        Say(player, "Đặt Huyền Tinh Cực Phẩm vào ô của Lò Rèn")
        return false
    end
    local ok = ApplyItem({ doer = player, invobject = material, target = target,
        tbc_station = station })
    if station:IsValid() and station.TBCUpdateState ~= nil then station:TBCUpdateState() end
    return ok
end
AddModRPCHandler(modname, "forge_use", function(player, station, operation)
    ForgeUse(player, station, operation)
end)
AddPrefabPostInit("tbc_forge", function(inst)
    if G.TheWorld.ismastersim then inst.TBCUse = ForgeUse end
end)

local function KillCredit(source, depth)
    if source == nil or depth > 3 then return nil end
    if source:HasTag("player") then return source end
    local components = source.components or {}
    if components.projectile ~= nil and components.projectile.attacker ~= nil then
        return KillCredit(components.projectile.attacker, depth + 1)
    end
    if components.follower ~= nil and components.follower.leader ~= nil then
        return KillCredit(components.follower.leader, depth + 1)
    end
    if components.inventoryitem ~= nil and components.inventoryitem.owner ~= nil then
        return KillCredit(components.inventoryitem.owner, depth + 1)
    end
    return nil
end

local function MonsterClass(inst)
    if inst:HasTag("epic") then return "boss" end
    local hp = inst.components.health.maxhealth or 0
    return hp >= 500 and "elite" or "common"
end

AddPrefabPostInitAny(function(inst)
    DetailHooks.Attach(inst, G.net_string)
    if not G.TheWorld.ismastersim then return end
    local c = inst.components
    if c == nil then return end
    if c.equippable ~= nil and c.inventoryitem ~= nil and c.stackable == nil
        and c.tbc_upgrade == nil then
        inst:AddComponent("tbc_upgrade")
        inst:AddTag("tbc_upgradeable")
    end
    EquipmentInstall.AttachItem(inst)
    if not utility_detail_enabled then
        DetailHooks.AttachSpecial(inst, G.STRINGS.NAMES)
    end
    if c.health == nil or inst:HasTag("player") or inst:HasTag("structure") then return end
    local day_eligible = c.combat ~= nil and not inst:HasTag("companion")
    local loot_eligible = inst:HasTag("monster") or inst:HasTag("epic")
        or string.sub(inst.prefab or "", 1, 3) == "xd_"
    if not standalone_scaling_enabled or not day_eligible then MonsterScaling.WatchHealth(inst) end
    if not day_eligible then
        inst._tbc_monster_base_kind = MonsterClass(inst)
        inst._tbc_monster_kind = "realm_only"
        inst._tbc_monster_days = G.TheWorld.state ~= nil
            and G.TheWorld.state.cycles or 0
        inst:DoTaskInTime(0, function(mob)
            if not mob:IsValid() then return end
            local world = GetRealmWorld()
            MonsterScaling.ApplyMonster(mob, "realm_only",
                mob._tbc_monster_days, world ~= nil and world.max_level or 0)
        end)
        return
    end
    local kind = MonsterClass(inst)
    if not standalone_scaling_enabled then
        inst._tbc_monster_kind = kind
        inst._tbc_monster_days = G.TheWorld.state ~= nil
            and G.TheWorld.state.cycles or 0
    end
    inst:DoTaskInTime(0, function(mob)
        if not mob:IsValid() or mob._tbc_scaled then return end
        mob._tbc_scaled = true
        local days = G.TheWorld.state ~= nil and G.TheWorld.state.cycles or 0
        if standalone_scaling_enabled then
            local hp_mult, damage_mult = Rules.MonsterMultipliers(kind, days)
            local health = mob.components.health
            local current = health:GetPercent()
            health:SetMaxHealth(health.maxhealth * hp_mult)
            health:SetPercent(current)
            local combat = mob.components.combat
            if type(combat.defaultdamage) == "number" then
                combat.defaultdamage = combat.defaultdamage * damage_mult
            end
        else
            local world = GetRealmWorld()
            local level = world ~= nil and world.max_level or 0
            MonsterScaling.ApplyMonster(mob, kind, days, level)
        end
    end)
    if not loot_eligible then return end
    inst:ListenForEvent("death", function(mob, data)
        local killer = KillCredit(data ~= nil and data.afflicter or nil, 0)
        if mob._tbc_looted or killer == nil then return end
        mob._tbc_looted = true
        local loot = Rules.RollLoot(kind)
        for _, id in ipairs(loot) do
            if mob.components.lootdropper ~= nil then
                mob.components.lootdropper:SpawnLootPrefab(id, mob:GetPosition())
            else
                local item = G.SpawnPrefab(id)
                if item ~= nil then item.Transform:SetPosition(mob.Transform:GetWorldPosition()) end
            end
        end
        EquipmentWalletDrops.Award(killer, kind)
    end)
end)

local material_atlas = "images/vat_pham_inventory_so_1.xml"
local potion_atlas = "images/phuc_lac_duoc_inventory.xml"
local recipe_ingredient_icons = {
    hh_effect_tally = { material_atlas, "giay_thuoc_tinh_inventory.tex" },
    hh_remove_stone = { material_atlas, "luc_bao_thach_inventory.tex" },
    hh_essence = { material_atlas, "linh_thach_inventory.tex" },
    wb_enhancegem = { "images/inventoryimages/ttk_huyen_tinh_cuc_pham.xml", "ttk_huyen_tinh_cuc_pham.tex" },
    nn_liquidluck = { potion_atlas, "phuc_lac_duoc_1_inventory.tex" },
    nn_liquidluck_2 = { potion_atlas, "phuc_lac_duoc_2_inventory.tex" },
}
local function ModIngredient(prefab, amount)
    local icon = recipe_ingredient_icons[prefab]
    return G.Ingredient(prefab, amount, icon[1], nil, icon[2])
end

for _, tier in ipairs({ "ha", "trung", "thuong" }) do
    local id = "ttk_huyen_tinh_" .. tier .. "_pham"
    local atlas = "images/inventoryimages/" .. id .. ".xml"
    recipe_ingredient_icons[id] = { atlas, id .. ".tex" }
    Assets[#Assets + 1] = Asset("ATLAS", atlas)
    Assets[#Assets + 1] = Asset("IMAGE", "images/inventoryimages/" .. id .. ".tex")
end
G.STRINGS.RECIPE_DESC.TTK_HUYEN_TINH_TRUNG_PHAM = "Ghép 5 Huyền Tinh Hạ Phẩm thành 1 Trung Phẩm."
G.STRINGS.RECIPE_DESC.TTK_HUYEN_TINH_THUONG_PHAM = "Ghép 4 Huyền Tinh Trung Phẩm thành 1 Thượng Phẩm."
G.STRINGS.NAMES.TTK_HUYEN_TINH_CUC_PHAM_FUSION = "Huyền Tinh Cực Phẩm"
G.STRINGS.RECIPE_DESC.TTK_HUYEN_TINH_CUC_PHAM_FUSION = "Ghép 3 Huyền Tinh Thượng Phẩm thành 1 Cực Phẩm."
AddRecipe2("ttk_huyen_tinh_trung_pham", { ModIngredient("ttk_huyen_tinh_ha_pham", 5) },
    G.TECH.NONE, { numtogive = 1, atlas = "images/inventoryimages/ttk_huyen_tinh_trung_pham.xml",
        image = "ttk_huyen_tinh_trung_pham.tex" }, { "REFINE" })
AddRecipe2("ttk_huyen_tinh_thuong_pham", { ModIngredient("ttk_huyen_tinh_trung_pham", 4) },
    G.TECH.NONE, { numtogive = 1, atlas = "images/inventoryimages/ttk_huyen_tinh_thuong_pham.xml",
        image = "ttk_huyen_tinh_thuong_pham.tex" }, { "REFINE" })
AddRecipe2("ttk_huyen_tinh_cuc_pham_fusion", { ModIngredient("ttk_huyen_tinh_thuong_pham", 3) },
    G.TECH.NONE, { product = "wb_enhancegem", numtogive = 1,
        atlas = "images/inventoryimages/ttk_huyen_tinh_cuc_pham.xml",
        image = "ttk_huyen_tinh_cuc_pham.tex" }, { "REFINE" })

AddRecipe2("tbc_forge", { G.Ingredient("cutstone", 4), G.Ingredient("goldnugget", 4), G.Ingredient("boards", 2) },
    G.TECH.SCIENCE_TWO, { placer = "tbc_forge_placer", atlas = "images/lo_ren.xml", image = "lo_ren.tex" }, { "STRUCTURES" })
AddRecipe2("tbc_suit_build", { G.Ingredient("cutstone", 4), G.Ingredient("goldnugget", 6), G.Ingredient("boards", 4) },
    G.TECH.SCIENCE_TWO, { placer = "tbc_suit_build_placer",
        atlas = "images/hh_icon/hh_suit_build.xml", image = "hh_suit_build.tex" }, { "STRUCTURES" })
AddRecipe2("hh_essence", { ModIngredient("hh_effect_tally", 1), ModIngredient("hh_remove_stone", 2) },
    G.TECH.NONE, { numtogive = 1, atlas = "images/vat_pham_inventory_so_1.xml", image = "linh_thach_inventory.tex" }, { "REFINE" })
AddRecipe2("wb_enhancegem", { G.Ingredient("opalpreciousgem", 1), ModIngredient("hh_essence", 8) },
    G.TECH.NONE, { numtogive = 8, atlas = "images/inventoryimages/ttk_huyen_tinh_cuc_pham.xml", image = "ttk_huyen_tinh_cuc_pham.tex" }, { "REFINE" })
AddRecipe2("nn_magicpaper", { G.Ingredient("goldnugget", 3), G.Ingredient("nightmarefuel", 2), ModIngredient("wb_enhancegem", 6) },
    G.TECH.NONE, { atlas = "images/vat_pham_inventory_so_1.xml", image = "bua_ma_thuat_inventory.tex" }, { "REFINE" })
AddRecipe2("wb_strengthen_strengthen_protectpaper",
    { G.Ingredient("goldnugget", 3), G.Ingredient("nightmarefuel", 2), ModIngredient("wb_enhancegem", 10) },
    G.TECH.NONE, { atlas = "images/vat_pham_inventory_so_1.xml", image = "bua_bao_ve_inventory.tex" }, { "REFINE" })
AddRecipe2("nn_liquidluck", { G.Ingredient("vegstinger", 1), ModIngredient("wb_enhancegem", 1) },
    G.TECH.SCIENCE_TWO, { atlas = "images/phuc_lac_duoc_inventory.xml", image = "phuc_lac_duoc_1_inventory.tex" }, { "REFINE" })
AddRecipe2("nn_liquidluck_2", { ModIngredient("nn_liquidluck", 3), G.Ingredient("purebrilliance", 1) },
    G.TECH.SCIENCE_TWO, { atlas = "images/phuc_lac_duoc_inventory.xml", image = "phuc_lac_duoc_2_inventory.tex" }, { "REFINE" })
AddRecipe2("nn_liquidluck_3", { ModIngredient("nn_liquidluck_2", 3), G.Ingredient("purebrilliance", 2) },
    G.TECH.SCIENCE_TWO, { atlas = "images/phuc_lac_duoc_inventory.xml", image = "phuc_lac_duoc_3_inventory.tex" }, { "REFINE" })
AddRecipe2("wb_strengthen_clearpaper", { G.Ingredient("papyrus", 2), G.Ingredient("nightmarefuel", 2), ModIngredient("wb_enhancegem", 2) },
    G.TECH.SCIENCE_TWO, { atlas = "images/inventoryimages.xml", image = "papyrus.tex" }, { "REFINE" })
