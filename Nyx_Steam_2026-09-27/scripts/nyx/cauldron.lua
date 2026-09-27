-- Kim Dau has separate equip, deployment and owned-dais permissions.
local M={}
local TAG='nyx_cauldron_deployer'
local function AllowDeploy(inst)
    local deploy=inst.components.deployable
    if deploy and deploy.restrictedtag=='xd_yunxiao' then deploy.restrictedtag=TAG end
end
function M.Install(api)
    local function allow(inst) inst:AddTag(TAG) end
    api.AddPrefabPostInit('nyx',allow)
    api.AddPrefabPostInit('xd_yunxiao',allow)
    api.AddPrefabPostInit('xd_yunxiao_hyjditem',function(inst)
        if not TheWorld.ismastersim then return end
        AllowDeploy(inst)
        local recharge=inst.components.rechargeable
        if recharge and not inst._nyx_cauldron_hooked then
            inst._nyx_cauldron_hooked=true
            local old=recharge.onchargedfn
            recharge.onchargedfn=function(item,...)
                if old then old(item,...) end
                -- Source recreates deployable after each recharge.
                AllowDeploy(item)
            end
        end
    end)
    api.AddPrefabPostInit('xd_yunxiao_hyjdyqd',function(inst)
        if not TheWorld.ismastersim then return end
        local use=inst.components.xd_use_inventory
        if not use then return end
        local old=use.onusefn
        use.onusefn=function(item,doer,...)
            if not doer or doer.prefab~='nyx' then
                if old then return old(item,doer,...) end
                return
            end
            if not item._userid or item._userid~=doer.userid then return end
            if item.ismaster then item:SetMaster(false)
            else
                for other in pairs(XD_HYYQDTBL or {}) do
                    if other._userid==doer.userid and other.ismaster then other:SetMaster(false) end
                end
                item:SetMaster(true)
            end
        end
    end)
end
return M
