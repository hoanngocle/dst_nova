-- Extra deployable uniques; no global character tags are granted to Nyx.
local M={}
local items={xd_luoshen_huazhong='xd_luoshen',xd_luoshen_jihuaze='xd_luoshen',xd_sj_tlsq='xd_shiji'}
function M.Install(api)
    for _,family in ipairs({'xd_luoshen','xd_shiji'}) do
        local tag='nyx_deploy_'..family
        api.AddPrefabPostInit(family,function(inst)inst:AddTag(tag)end)
        api.AddPrefabPostInit('nyx',function(inst)inst:AddTag(tag)end)
    end
    for prefab,family in pairs(items) do
        local tag='nyx_deploy_'..family
        api.AddPrefabPostInit(prefab,function(inst)
            if not TheWorld.ismastersim then return end
            local d=inst.components.deployable
            if d and d.restrictedtag==family then d.restrictedtag=tag end
        end)
    end
    api.AddPrefabPostInit('xd_sj_tlsq',function(inst)
        if not TheWorld.ismastersim then return end
        local function transform(item,owner)
            if item.change_task then item.change_task:Cancel() end
            item.change_task=item:DoTaskInTime(2,function()
                item.change_task=nil
                if not owner:IsValid() then return end
                local pos=item:GetPosition();item:Remove()
                SpawnAt('rock_break_fx',pos)
                local fx=SpawnAt('collapse_small',pos);if fx then fx:SetMaterial('stone') end
                local pet=SpawnAt('rocky',pos)
                if pet and pet.components.follower then
                    pet.components.follower:SetLeader(owner)
                    pet.components.follower:AddLoyaltyTime(7*480)
                end
            end)
        end
        local inv=inst.components.inventoryitem
        if inv then
            -- Standard inventoryitem clears owner before invoking ondropfn.
            -- Capture the actual grand owner without changing the item's identity.
            local olddrop=inv.OnDropped
            if olddrop then
                inv.OnDropped=function(c,...)
                    inst._nyx_drop_owner=c:GetGrandOwner()
                    local ok,result=pcall(olddrop,c,...)
                    inst._nyx_drop_owner=nil
                    if not ok then error(result) end
                    return result
                end
            end
            local old=inv.ondropfn
            inv.ondropfn=function(item,owner,...)
                owner=owner or item._nyx_drop_owner
                if owner and owner.prefab=='nyx' then return transform(item,owner) end
                if old then return old(item,owner,...) end
            end
        end
        local deploy=inst.components.deployable
        if deploy then
            local old=deploy.ondeploy
            deploy.ondeploy=function(item,pt,owner,...)
                if owner and owner.prefab=='nyx' then
                    item.Transform:SetPosition(pt.x,0,pt.z);return transform(item,owner)
                end
                if old then return old(item,pt,owner,...) end
            end
        end
    end)
end
return M
