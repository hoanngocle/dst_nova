GLOBAL.setmetatable(env,{__index=function(_,k) return GLOBAL.rawget(GLOBAL,k) end})
local State = require "functions/globalperkstate"
State.Initialize()

-- modmain runs before TheWorld exists. Read legacy data once in the server world.
-- Clients must never create or overwrite a default global Perk file.
AddPrefabPostInit("world", function(inst)
    if not inst.ismastersim then return end
    inst:AddComponent("chasni_globalperks")
    local component = inst.components.chasni_globalperks
    local function loaded(success, data)
        component:LoadLegacy(success, data)
    end
    -- ShardIndex() creates an unloaded index whose slot is nil. The active
    -- ShardGameIndex is populated by the game before the world is spawned.
    local index = ShardGameIndex
    local slot = index and index:GetSlot()
    local serverdata = index and index:GetServerData()
    if not TheNet:IsDedicated() and type(slot) == "number" and slot >= 1 and slot % 1 == 0
        and serverdata and not serverdata.use_legacy_session_path then
        TheSim:GetPersistentStringInClusterSlot(slot, "Master", "chasni_perk_global.json", loaded)
    else
        TheSim:GetPersistentString("chasni_perk_global.json", loaded)
    end
end)
