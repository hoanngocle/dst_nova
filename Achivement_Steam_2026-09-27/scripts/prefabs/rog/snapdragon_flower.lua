local assets =
{
    Asset("ANIM", "anim/snapdragon_flower.zip"),
}

local prefabs =
{
    "petals",
}

local function onpickedfn(inst, picker)
    if picker and picker.components.sanity and not picker:HasTag("plantkin") then
        picker.components.sanity:DoDelta(TUNING.SANITY_TINY)
    end

    local pos = inst:GetPosition()
    TheWorld:PushEvent("plantkilled", { doer = picker, pos = pos })
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBank("snapdragon_flower")
    inst.AnimState:SetBuild("snapdragon_flower")
    inst.AnimState:PlayAnimation("grow_seed")
    inst.AnimState:PushAnimation("idle", true)

    inst:AddTag("snapdragon_flower")
    inst:AddTag("flower")
    inst:AddTag("cattoy")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp("petals", 10)
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.remove_when_picked = true
    inst.components.pickable.quickpick = true

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    return inst
end

return Prefab("chasni_snapdragon_flower", fn, assets, prefabs)
