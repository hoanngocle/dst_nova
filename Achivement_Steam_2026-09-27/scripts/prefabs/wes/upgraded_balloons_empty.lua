local assets =
{
    Asset("ANIM", "anim/chasni_sealloons.zip"),
    Asset("ATLAS", "images/inventoryimages/chasni_sealloons.xml"),
}

local prefabs =
{
    "chasni_seal_fur",
    "balloons_empty",
    "waterballoon_splash",
}

local function dodecay(inst)
    if inst.components.lootdropper == nil then
        inst:AddComponent("lootdropper")
    end
    inst.components.lootdropper:SpawnLootPrefab("balloons_empty")
    inst.components.lootdropper:SpawnLootPrefab("chasni_seal_fur")
    SpawnPrefab("small_puff").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end

local function startdecay(inst)
    if inst._decaytask == nil then
        inst._decaytask = inst:DoTaskInTime(TUNING.BALLOON_PILE_DECAY_TIME, dodecay)
        inst._decaystart = GetTime()
    end
end

local function stopdecay(inst)
    if inst._decaytask ~= nil then
        inst._decaytask:Cancel()
        inst._decaytask = nil
        inst._decaystart = nil
    end
end

local function onsave(inst, data)
    if inst._decaystart ~= nil then
        local time = GetTime() - inst._decaystart
        if time > 0 then
            data.decaytime = time
        end
    end
end

local function onload(inst, data)
    if inst._decaytask ~= nil and data ~= nil and data.decaytime ~= nil then
        local remaining = math.max(0, TUNING.BALLOON_PILE_DECAY_TIME - data.decaytime)
        inst._decaytask:Cancel()
        inst._decaytask = inst:DoTaskInTime(remaining, dodecay)
        inst._decaystart = GetTime() + remaining - TUNING.BALLOON_PILE_DECAY_TIME
    end
end

local function onbuilt(inst, builder)
    SpawnPrefab("waterballoon_splash").Transform:SetPosition(inst.Transform:GetWorldPosition())
    if builder.components.moisture ~= nil then
        local waterproofness = builder.components.moisture:GetWaterproofness()
        builder.components.moisture:DoDelta(20 * (1 - waterproofness))
    end
end

local function OnHaunt(inst)
    if inst.components.balloonmaker ~= nil and math.random() < TUNING.HAUNT_CHANCE_OFTEN then
        inst.components.balloonmaker:MakeBalloon(inst.Transform:GetWorldPosition())
        return true
    end
    return false
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("chasni_sealloons")
    inst.AnimState:SetBuild("chasni_sealloons")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("cattoy")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "chasni_sealloons"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_sealloons.xml"
    
    inst:AddComponent("inspectable")
    inst:AddComponent("balloonmaker") -- deprecated, but left here for mods
    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
    inst.components.hauntable:SetOnHauntFn(OnHaunt)

    startdecay(inst)

    inst:ListenForEvent("onputininventory", stopdecay)
    inst:ListenForEvent("ondropped", startdecay)

    inst._decaytask = nil
    inst._decaystart = nil
    inst.OnBuiltFn = onbuilt
    inst.OnLoad = onload
    inst.OnSave = onsave

    return inst
end

return Prefab("chasni_sealloons", fn, assets, prefabs)
