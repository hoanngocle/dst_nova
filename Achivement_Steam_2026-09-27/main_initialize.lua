GLOBAL.setmetatable(env,{__index=function(_,k) return GLOBAL.rawget(GLOBAL,k) end})
local ShardGameIndex = ShardIndex()
local removedperks = require "constants/removedperks"

local function RemoveRetiredGlobalPerks(perkdata)
    perkdata.bosshp = nil
    perkdata.bossdmg = nil
    perkdata.mermbuff = nil
    perkdata.spiderbuff = nil
end

local function Chasni_CreateJSON()
    local savefile = { chasni_ganteng = 0 }
    for perkname, perk in pairs(perk_lists) do
        if perk.global then
            if savefile[perkname] then else
                savefile[perkname] = 0
            end
        end
    end
    removedperks.clearGlobal(savefile)
    TUNING.ACH = savefile
    TheSim:SetPersistentString("chasni_perk_global.json", json.encode(savefile), false)
end

local function Chasni_LoadJSON(load_success, data)
    print("CZ-INFO : Loading save files")
    if load_success == true and data then
        local status, perkdata = pcall(function() return json.decode(data) end)
        if status and perkdata then
            RemoveRetiredGlobalPerks(perkdata)
            for perkname, perk in pairs(perk_lists) do
                if perk.global then
                    if perkdata[perkname] then else
                        perkdata[perkname] = 0
                    end
                end
            end
            removedperks.clearGlobal(perkdata)
            TheSim:SetPersistentString("chasni_perk_global.json", json.encode(perkdata), false)
            TUNING.ACH = perkdata
        else
            print("CZ-ERROR : Faild to load global perk!", status, perkdata)
            Chasni_CreateJSON()
        end
    else
        Chasni_CreateJSON()
    end
end

if TheWorld and TheWorld.ismastersim then
    if not TheNet:IsDedicated() and not ShardGameIndex:GetServerData().use_legacy_session_path then
        TheSim:GetPersistentStringInClusterSlot(ShardGameIndex:GetSlot(), "Master", "chasni_perk_global.json", Chasni_LoadJSON)
    else
        TheSim:GetPersistentString("chasni_perk_global.json", Chasni_LoadJSON)
    end
end

TheSim:GetPersistentString("chasni_perk_global.json", Chasni_LoadJSON)
