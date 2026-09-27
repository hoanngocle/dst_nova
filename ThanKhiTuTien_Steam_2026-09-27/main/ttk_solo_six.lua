local G = GLOBAL
local defs = require("tbc_solo_weapons/defs")

table.insert(PrefabFiles, "tbc_solo_six")
table.insert(PrefabFiles, "tbc_solo_original_fx")
table.insert(PrefabFiles, "tbc_solo_original_particles")
table.insert(PrefabFiles, "tbc_solo_original_weapon_fx")
table.insert(PrefabFiles, "tbc_solo_original_fire_fx")

-- Original Hắc Ảnh Kiếm flame recolour hook from Solo Leveling.
local function InstallPurpleFlameBuild(prefab)
    AddPrefabPostInit(prefab, function(inst)
        if not G.TheWorld.ismastersim or inst.SetFXOwner == nil then return end
        local old = inst.SetFXOwner
        inst.SetFXOwner = function(fx, owner, ...)
            old(fx, owner, ...)
            if owner ~= nil and owner._hh_daogam2_purple_build then
                fx.AnimState:SetBuild("hh_purple_warg_mutated_breath_fx")
            end
        end
    end)
end
InstallPurpleFlameBuild("warg_mutated_breath_fx")
InstallPurpleFlameBuild("warg_mutated_ember_fx")

local descriptions = {
    hh_daogam = "Ba vệt chém phụ, Tam Ảnh Trảm; nhấn R gọi Thiên Phạt Quỷ Vương.",
    hh_daogam2 = "Kiếm kiêm khiên, gọi xúc tu; nhấn R đỡ đòn Hắc Ảnh.",
    hh_daogam3 = "Đánh đôi phép thuật; nhấn R để bắn loạt phép.",
    hh_daogam4 = "Thiêu đốt kẻ địch; nhấn R tạo Hỏa Ngục Tinh Vũ.",
    hh_daogam5 = "Nhấn R để lướt tối đa ba lần liên tiếp.",
    hh_daogam6 = "Nhấn R để đổi giữa kiếm, rìu, cúp, xẻng và cuốc.",
}

local recipes = {
    hh_daogam = {{"nightmarefuel", 12}, {"thulecite", 8}, {"redgem", 2}},
    hh_daogam2 = {{"nightmarefuel", 12}, {"thulecite", 8}, {"purplegem", 2}},
    hh_daogam3 = {{"nightmarefuel", 10}, {"purplegem", 4}, {"livinglog", 4}},
    hh_daogam4 = {{"nightmarefuel", 10}, {"redgem", 4}, {"livinglog", 4}},
    hh_daogam5 = {{"nightmarefuel", 12}, {"purplegem", 4}, {"moonrocknugget", 12}},
    hh_daogam6 = {{"nightmarefuel", 12}, {"thulecite", 8}, {"livinglog", 8}},
}

for _, id in ipairs({"hh_daogam", "hh_daogam2", "hh_daogam3", "hh_daogam4", "hh_daogam5", "hh_daogam6"}) do
    local def = defs[id]
    local upper = string.upper(id)
    G.STRINGS.NAMES[upper] = def.name
    G.STRINGS.RECIPE_DESC[upper] = descriptions[id]
    G.STRINGS.CHARACTERS.GENERIC.DESCRIBE[upper] = descriptions[id]
    local icon_name = id == "hh_daogam6" and "hh_daogam6_sword.tex" or id .. ".tex"
    RegisterInventoryItemAtlas(def.icon, icon_name)
    if id == "hh_daogam6" then
        for _, mode in ipairs({"axe", "pickaxe", "shovel", "hoe"}) do
            RegisterInventoryItemAtlas(def.icon, "hh_daogam6_" .. mode .. ".tex")
        end
    end
    local ingredients = {}
    for _, entry in ipairs(recipes[id]) do
        ingredients[#ingredients + 1] = G.Ingredient(entry[1], entry[2])
    end
    AddRecipe2(id, ingredients, G.TECH.MAGIC_THREE, {
        atlas = def.icon, image = icon_name, no_deconstruction = true,
    }, {"WEAPONS", "MAGIC"})
end

-- Dispatch R through the same native parry state used by Solo Leveling.
local parry = G.Action({priority = 10, mount_valid = false})
parry.id = "TBC_SOLO_PARRY_R"
parry.str = "Đỡ đòn Hắc Ảnh"
parry.fn = function(act)
    local player, item = act.doer, act.invobject
    if player == nil or item == nil or item.prefab ~= "hh_daogam2"
        or player.components.inventory:GetEquippedItem(G.EQUIPSLOTS.HANDS) ~= item
        or item.TBCCast == nil then return false end
    item:TBCCast(player, act:GetActionPoint())
    return true
end
AddAction(parry)
AddStategraphActionHandler("wilson", G.ActionHandler(G.ACTIONS.TBC_SOLO_PARRY_R, "parry_pre"))
AddStategraphActionHandler("wilson_client", G.ActionHandler(G.ACTIONS.TBC_SOLO_PARRY_R, "parry_pre"))

-- Only the equipped weapon can receive this request. No mouse action is
-- registered, so the game's right-click action picker never sees these skills.
AddModRPCHandler(modname, "tbc_solo_skill", function(player, x, z, target)
    if player == nil or player.components == nil or player.components.inventory == nil
        or player.components.health == nil or player.components.health:IsDead()
        or player:HasTag("playerghost") then return end
    local item = player.components.inventory:GetEquippedItem(G.EQUIPSLOTS.HANDS)
    if item == nil or defs[item.prefab] == nil or item.components == nil
        or item.components.finiteuses == nil
        or item.components.finiteuses:GetUses() <= 0 then return end
    if type(x) ~= "number" or type(z) ~= "number"
        or x ~= x or z ~= z or math.abs(x) == math.huge or math.abs(z) == math.huge then return end
    local px, _, pz = player.Transform:GetWorldPosition()
    local dx, dz = x - px, z - pz
    if item.prefab == "hh_daogam6" then
        if target ~= nil and target.IsValid ~= nil and target:IsValid() then
            local tx, _, tz = target.Transform:GetWorldPosition()
            if (tx - px) ^ 2 + (tz - pz) ^ 2 <= 14 * 14 then
                if target.prefab == "farm_soil" then item:TBCMorphMode("hoe") return end
                local workable = target.components ~= nil and target.components.workable or nil
                local work = workable ~= nil and workable:GetWorkAction() or nil
                if work == G.ACTIONS.CHOP then item:TBCMorphMode("axe") return end
                if work == G.ACTIONS.MINE then item:TBCMorphMode("pickaxe") return end
                if work == G.ACTIONS.DIG then item:TBCMorphMode("shovel") return end
                if work == G.ACTIONS.TILL then item:TBCMorphMode("hoe") return end
            end
        end
        if G.TheWorld.Map:GetTileAtPoint(x, 0, z) == G.WORLD_TILES.FARMING_SOIL then
            item:TBCMorphMode("hoe")
        else
            item:TBCMorphNext()
        end
        return
    end
    if dx * dx + dz * dz > 14 * 14 then return end
    if item.components.rechargeable == nil or not item.components.rechargeable:IsCharged()
        or item.TBCCast == nil then return end
    if item.prefab == "hh_daogam5" and (dx * dx + dz * dz > 12 * 12
        or not G.TheWorld.Map:IsPassableAtPoint(x, 0, z)) then return end
    if item.prefab == "hh_daogam2" then
        player:PushBufferedAction(G.BufferedAction(player, nil,
            G.ACTIONS.TBC_SOLO_PARRY_R, item, G.Vector3(x, 0, z)))
        return
    end
    item:TBCCast(player, G.Vector3(x, 0, z))
end)

if not G.TheNet:IsDedicated() then
    G.TheInput:AddKeyDownHandler(G.KEY_R, function()
        local player = G.ThePlayer
        local screen = G.TheFrontEnd:GetActiveScreen()
        if player == nil or player.replica == nil or player.replica.inventory == nil
            or player:HasTag("playerghost") or screen == nil or screen.name ~= "HUD" then return end
        local item = player.replica.inventory:GetEquippedItem(G.EQUIPSLOTS.HANDS)
        if item == nil or defs[item.prefab] == nil then return end
        local pos = G.TheInput:GetWorldPosition()
        if pos == nil then return end
        G.SendModRPCToServer(G.MOD_RPC[modname].tbc_solo_skill,
            pos.x, pos.z, G.TheInput:GetWorldEntityUnderMouse())
    end)
end

local repair = G.Action({priority = 5, mount_valid = true})
repair.id = "TBC_SOLO_REPAIR"
repair.str = "Sửa chữa"
repair.fn = function(act)
    local fuel, weapon, doer = act.invobject, act.target, act.doer
    if fuel == nil or weapon == nil or doer == nil
        or fuel.prefab ~= "nightmarefuel" or defs[weapon.prefab] == nil
        or weapon.components.finiteuses == nil
        or weapon.components.finiteuses:GetPercent() >= 1
        or fuel.components.inventoryitem == nil
        or fuel.components.inventoryitem.owner ~= doer then return false end
    local one = fuel.components.stackable ~= nil and fuel.components.stackable:Get(1) or fuel
    if one ~= nil then one:Remove() end
    weapon.components.finiteuses:Repair(36)
    return true
end
AddAction(repair)
AddComponentAction("USEITEM", "inventoryitem", function(inst, doer, target, actions)
    if inst.prefab == "nightmarefuel" and target ~= nil
        and defs[target.prefab] ~= nil and target:HasTag("hh_daogam_item") then
        actions[#actions + 1] = G.ACTIONS.TBC_SOLO_REPAIR
    end
end)
AddStategraphActionHandler("wilson", G.ActionHandler(G.ACTIONS.TBC_SOLO_REPAIR, "doshortaction"))
AddStategraphActionHandler("wilson_client", G.ActionHandler(G.ACTIONS.TBC_SOLO_REPAIR, "doshortaction"))
