local assets =
{
    Asset("ANIM", "anim/pig_shop.zip"),
    Asset("ANIM", "anim/pig_shop_tinker.zip"),
    Asset("ATLAS", "images/inventoryimages/tinker_tower.xml"),
}

local prefabs =
{
    "collapse_small",
}

local function onhammered(inst, worker)
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("stone")

    inst.components.lootdropper:DropLoot()
    inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
    inst:Remove()
end

local function onhit(inst)
    inst.AnimState:PlayAnimation("hit")
    if inst.lightson then
        inst.AnimState:PushAnimation("lit")
    else
        inst.AnimState:PushAnimation("idle")
    end
end

local function onturnoff(inst)
    inst.components.prototyper.on = false
    inst.Light:Enable(false)
    inst.AnimState:PlayAnimation("idle", true)
    inst.SoundEmitter:PlaySound("dontstarve/pig/pighut_lightoff")
    inst.lightson = false
end

local function onturnon(inst)
    inst.components.prototyper.on = true
    inst.Light:Enable(true)
    inst.AnimState:PlayAnimation("lit", true)
    inst.SoundEmitter:PlaySound("dontstarve/pig/pighut_lighton")
    inst.lightson = true
end

local function onactivate(inst)
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:PushAnimation("lit", true)
    inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pighouse/open")
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", false)
    inst.SoundEmitter:PlaySound("DLChasni/DLChasni/chasni_pighouse/built")
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    inst.AnimState:SetBank("pig_shop")
    inst.AnimState:SetBuild("pig_shop_tinker")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:Hide("YOTP")

    inst.Light:SetColour(180/255, 195/255, 50/255)
    inst.Light:SetFalloff(1)
    inst.Light:SetRadius(1)
    inst.Light:SetIntensity(.5)
    inst.Light:Enable(false)

    inst:AddTag("structure")
    inst:AddTag("prototyper")

    MakeSnowCoveredPristine(inst)
    MakeObstaclePhysics(inst, .8)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("prototyper")
    inst.components.prototyper.onturnon = onturnon
    inst.components.prototyper.onturnoff = onturnoff
    inst.components.prototyper.onactivate = onactivate
    inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.CZROG

    inst:ListenForEvent("onbuilt", onbuilt)

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)
    MakeSnowCovered(inst)


    return inst
end

return Prefab("tinkertower", fn, assets, prefabs),
    MakePlacer("tinkertower_placer", "pig_shop", "pig_shop_tinker", "idle")
