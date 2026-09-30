-- Item-use gates shared only by Nyx and the item's original character.
local M={}
-- Thien Nghich Chau integration is owned by Cong Trinh Tu Tien.
local uses={xd_htz_sjcx='xd_hantianzun',xd_htz_qzxy='xd_hantianzun',xd_htz_fjfb='xd_hantianzun',xd_luoshen_yin='xd_luoshen'}
function M.Install(api)
    for _,family in ipairs({'xd_hantianzun','xd_luoshen'}) do
        local tag='nyx_use_'..family
        api.AddPrefabPostInit(family,function(inst) inst:AddTag(tag) end)
        api.AddPrefabPostInit('nyx',function(inst) inst:AddTag(tag) end)
    end
    for prefab,family in pairs(uses) do
        local expected=family
        api.AddPrefabPostInit(prefab,function(inst)
            if inst.xd_use_needtag==expected then inst.xd_use_needtag='nyx_use_'..expected end
        end)
    end
    api.AddPrefabPostInit('nyx',function(inst)
        if not TheWorld.ismastersim then return end
        if not inst.components.xd_allpetleash then
            inst:AddComponent('xd_allpetleash')
            inst.components.xd_allpetleash:SetMaxPetsForPrefab('xd_htz_sjc',5)
            inst.components.xd_allpetleash:SetMaxPetsForPrefab('xd_htz_xyzz',1)
        end
        if not inst.components.xd_binglingqi then inst:AddComponent('xd_binglingqi') end
    end)
end
return M
