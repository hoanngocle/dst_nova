local assets=
{
    Asset("ANIM", "anim/metal_hulk_merge.zip"),
    Asset("MINIMAP_IMAGE", "metal_spider"),
}

local prefabs =
{
    "sparks_green_fx",
}

local function spawnpart(inst, prefab, x,y,z,rotation)
    local part = SpawnPrefab(prefab)
    part.Transform:SetPosition(x,y,z)
    part.Transform:SetRotation(rotation)
    part.sg:GoToState("separate")
end

local function breakpart(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local down = TheCamera:GetDownVec()
    local angle = math.atan2(down.z, down.x) / DEGREES

    local function singlebreak(inst, part)
        if inst[part] == 1 then
            spawnpart(inst, "chasni_hulk_"..part,x+down.x, y, z+down.z, math.random()*360)
        end
    end
    local function doublebreak(inst, part, mult)
        for i = 1, inst[part] do
            local sx = i == 2 and x + down.x or x - down.x * (mult or 1)
            local sz = i == 2 and z - down.z * (mult or 1) or z + down.z
            local sy = y
            local rotation = i == 2 and angle - 90 or angle + 90
            spawnpart(inst, "chasni_hulk_"..part, sx, sy, sz, rotation)
        end
    end
    singlebreak(inst, "head")
    singlebreak(inst, "spider")
    doublebreak(inst, "claw", 1)
    doublebreak(inst, "leg", 2)
end

local function onmerge(inst)
    inst.refreshanim(inst)
    inst.AnimState:PlayAnimation("merge")
    inst.AnimState:PushAnimation("idle",true)
    local pos = Vector3(inst.Transform:GetWorldPosition())
    TheWorld:PushEvent("ms_sendlightningstrike", pos)
    SpawnPrefab("chasni_laserhit"):SetTarget(inst)

    if inst.head == 1 and inst.claw == 2 and inst.leg == 2 and inst.spider == 1 then
        local hulk = SpawnPrefab("chasni_ancient_hulk")
        local x,y,z = inst.Transform:GetWorldPosition()
        hulk.Transform:SetPosition(x,y,z)
        hulk:PushEvent("activate")
        inst:Remove()
    end
end

local function canmerge(inst, part)
    return (part == "leg" or part == "claw") and inst[part] < 2 or inst[part] < 1
end

local function refreshanim(inst)
    local anim = inst.AnimState
    anim:Hide("leg01")
    anim:Hide("leg02")
    if inst.leg == 2 then
        anim:Show("leg01")
        anim:Show("leg02")
    elseif inst.leg == 1 then
        anim:Show("leg01")
    end
    anim:Hide("arm01")
    anim:Hide("arm02")
    if inst.claw == 2 then
        anim:Show("arm01")
        anim:Show("arm02")
    elseif inst.claw == 1 then
        anim:Show("arm01")
    end
    anim:Hide("head")
    if inst.head == 1 then
        anim:Show("head")
    end
    anim:Hide("spine")
    if inst.spider == 1 then
        anim:Show("spine")
    end
    anim:Hide("spine_head")
    if inst.spider == 1 and inst.head == 1 then
        anim:Show("spine_head")
    end
end

local function OnMined(inst)
    if math.random() < 0.6 then
        inst.breakpart(inst)
        inst:Remove()
        return
    end

    inst.AnimState:PlayAnimation("merge")
    inst.AnimState:PushAnimation("idle",true)
end

local function OnSave(inst,data)
    data.head = inst.head
    data.spine = inst.spider
    data.arms = inst.claw
    data.legs = inst.leg
end

local function OnLoad(inst,data)
    if data then
        inst.head = data.head
        inst.spider = data.spine
        inst.claw = data.arms
        inst.leg = data.legs

        inst.refreshanim(inst)
    end
end

local function commonfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()
    inst.entity:AddLight()
    inst.Transform:SetFourFaced()

    MakeObstaclePhysics(inst, 2)

    inst:AddTag("lightningrod")
    inst:AddTag("laser_immune")
    inst:AddTag("ancient_robot")
    inst:AddTag("monster")
    inst:AddTag("chasni_hulk_assembly")

    inst.AnimState:SetBank("metal_hulk_merge")
    inst.AnimState:SetBuild("metal_hulk_merge")
    inst.AnimState:PlayAnimation("idle", true)

    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(5)
    inst.Light:SetFalloff(3)
    inst.Light:SetColour(1, 0, 0)
    inst.Light:Enable(false)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnWorkCallback(function(inst, worker, workleft)
        local strongworker = worker:HasTag("toughworker")
        if not strongworker then
            local tool = worker.components.inventory and worker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
            strongworker = tool and tool.components.tool and tool.components.tool:CanDoToughWork()
        end
        if strongworker then
            local pos = chasni_getMiddlePos(inst, worker)
            chasni_spawnprefab("sparks_green_fx", pos.x,pos.y + 1,pos.z)
            inst.components.workable:SetWorkLeft(1)
            OnMined(inst, {attacker=worker})
        else
            inst.components.workable:SetWorkLeft(1)
            worker:PushEvent("tooltooweak", { workaction = ACTIONS.MINE })
        end
    end)

    inst:AddComponent("timer")
    inst:AddComponent("inspectable")
    inst:AddComponent("knownlocations")
    inst:AddComponent("lootdropper")

    inst.leg = 0
    inst.head = 0
    inst.claw = 0
    inst.spider = 0
    inst.lightningpriority = 1
    inst.onmerge = onmerge
    inst.canmerge = canmerge
    inst.refreshanim = refreshanim
    inst.breakpart = breakpart
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    refreshanim(inst)

    return inst
end

return Prefab("chasni_hulk_assembly", commonfn, assets, prefabs)
