-- Nyx adapter for the native Shiji cloud recipe; source owns cloud save data.
local function spanwefx(inst,remove)
    local fx = SpawnPrefab("spawn_fx_medium_static")
    if fx ~= nil then
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end
    inst.AnimState:SetMultColour(1, 1, 1, remove and 1 or 0)
    inst.components.colourtweener:StartTween({1, 1, 1, 1}, 0.5, function()
    end)
end

local function builder_onbuilt(inst, builder)
    if builder.prefab == "nyx" then
        if not builder.components.timer:TimerExists("summmon_by_cd") and not builder.components.xd_skillcd:HasCd("nyx_shiji_cloud")  then
            local theta = math.random() * TWOPI
            local pt = builder:GetPosition()
            local radius = 1
            local offset = FindWalkableOffset(pt, theta, radius, 6, true)
            if offset ~= nil then
                pt.x = pt.x + offset.x
                pt.z = pt.z + offset.z
            end
            local pet = SpawnPrefab("xd_sj_by", inst.linked_skinname, nil, builder.userid)
            if pet.Physics ~= nil then
                pet.Physics:Teleport(pt.x, pt.y, pt.z)
            elseif pet.Transform ~= nil then
                pet.Transform:SetPosition(pt.x, pt.y, pt.z)
            end
            
            builder.components.xd_skillcd:Start("nyx_shiji_cloud",TUNING.XD_BY_LIFETIME)
            pet._ownerame = builder.name
            pet._ownerid = builder.userid
            spanwefx(pet)

            if TheWorld.components.xd_by_container  then
                local old = TheWorld.components.xd_by_container:GetSave(builder.userid)
                if old then
                    pet.components.container:OnLoad(old)
                end
                TheWorld.components.xd_by_container:ClearSave(builder.userid)
            end
            
        else
            builder.components.talker:Say(STRINGS.XD_BY_INCD)
        end
    end

    inst:Remove()
end


local M={}
function M.Install(api)
    api.AddPrefabPostInit('xd_sj_by_builder',function(inst)
        if not TheWorld.ismastersim then return end
        local old=inst.OnBuiltFn
        inst.OnBuiltFn=function(item,owner,...)
            if owner and owner.prefab=='nyx' then return builder_onbuilt(item,owner) end
            if old then return old(item,owner,...) end
        end
    end)
end
return M
