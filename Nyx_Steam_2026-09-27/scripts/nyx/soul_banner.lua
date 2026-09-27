-- Tôn Hồn Phiên is deployable, not equippable. Keep its original soul system.
local M={}
local TAG='nyx_soul_banner_deployer'
function M.Install(api)
    local function allow(inst) inst:AddTag(TAG) end
    api.AddPrefabPostInit('nyx',allow)
    api.AddPrefabPostInit('xd_wangmazi',allow)
    api.AddPrefabPostInit('xd_wmz_zhf',function(inst)
        if not TheWorld.ismastersim then return end
        local deploy=inst.components.deployable
        if deploy and deploy.restrictedtag=='xd_wangmazi' then deploy.restrictedtag=TAG end
    end)
end
return M
