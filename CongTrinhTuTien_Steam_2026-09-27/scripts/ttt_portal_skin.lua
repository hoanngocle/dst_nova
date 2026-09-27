-- Only the Cổ Trận skin. Do not import Phàm Nhân's other skin families.
local M = {}
local SKIN = "ttt_portal_gcsz"
local BASE = "homesign"

local function IsPortal(inst)
    return inst ~= nil and (inst.prefab == BASE or inst.prefab == BASE .. "_placer")
end

function M.Apply(inst, skin_name)
    if not IsPortal(inst) or skin_name ~= SKIN then return false end
    require("ttt_portal_visuals").ApplySkin(inst, SKIN)
    return true
end

function M.Clear(inst)
    if not IsPortal(inst) then return false end
    require("ttt_portal_visuals").ApplySkin(inst, nil)
    return true
end

local function AddUnique(list, value)
    for _, item in ipairs(list) do
        if item == value then return end
    end
    table.insert(list, value)
end

function M.Install(env)
    local G = env.GLOBAL
    local skins = G.PREFAB_SKINS[BASE] or {}
    local ids = G.PREFAB_SKINS_IDS[BASE] or {}
    G.PREFAB_SKINS[BASE] = skins
    G.PREFAB_SKINS_IDS[BASE] = ids
    AddUnique(skins, SKIN)
    for index, name in ipairs(skins) do ids[name] = index end
    G.STRINGS.SKIN_NAMES[SKIN] = "Cổ Trận"
    G.STRINGS.SKIN_DESCRIPTIONS[SKIN] = "Mẫu cổ trận dành cho Truyền Tống Trận."
    env.RegisterInventoryItemAtlas(
        "images/inventoryimages/ttt_portal_gcsz.xml", "ttt_portal_gcsz.tex")
    rawset(G, BASE .. "_clear_fn", M.Clear)

    if rawget(G, "__TTT_PORTAL_SKIN_ADAPTERS_INSTALLED") then return end
    rawset(G, "__TTT_PORTAL_SKIN_ADAPTERS_INSTALLED", true)

    local inventory = G.TheInventory
    local mt = inventory ~= nil and getmetatable(inventory) or nil
    local index = mt ~= nil and mt.__index or nil
    if type(index) == "table" then
        local old_ownership = index.CheckOwnership
        local old_latest = index.CheckOwnershipGetLatest
        local old_client = index.CheckClientOwnership
        if type(old_ownership) == "function" then
            index.CheckOwnership = function(self, name, ...)
                if name == SKIN then return true end
                return old_ownership(self, name, ...)
            end
        end
        if type(old_latest) == "function" then
            index.CheckOwnershipGetLatest = function(self, name, ...)
                if name == SKIN then return true, 0 end
                return old_latest(self, name, ...)
            end
        end
        if type(old_client) == "function" then
            index.CheckClientOwnership = function(self, userid, name, ...)
                if name == SKIN then return true end
                return old_client(self, userid, name, ...)
            end
        end
    end

    local old_icon = G.GetSkinInvIconName
    if type(old_icon) == "function" then
        G.GetSkinInvIconName = function(name, ...)
            if name == SKIN then return SKIN end
            return old_icon(name, ...)
        end
    end

    local old_spawn = G.SpawnPrefab
    G.SpawnPrefab = function(prefab, skin, skin_id, creator, ...)
        if skin == SKIN and (prefab == BASE or prefab == BASE .. "_placer") then
            skin_id = 0
        end
        return old_spawn(prefab, skin, skin_id, creator, ...)
    end
end

return M
