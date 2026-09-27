local assets =
{
    Asset("ANIM", "anim/willow_shield.zip"),
}

local DURATION = 20
local function OnAttached(inst, target)
    if not target.components.health:IsDead() and not target:HasTag("playerghost") then
        inst.entity:SetParent(target.entity)
        inst:ListenForEvent("death", function() inst.components.debuff:Stop() end, target)
        inst.SoundEmitter:PlaySound("ember_spirit/chasni_ember_spirit/ember_shield_set")
    else
        inst.components.debuff:Stop()
    end
end

local function OnDetached(inst, target)
    inst:Remove()
end

local function OnTimerDone(inst, data)
    if data.name == "decay" then
        inst.components.debuff:Stop()
    end
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("CLASSIFIED")

    inst.AnimState:SetBank("chasni_willow_shield")
    inst.AnimState:SetBuild("willow_shield")
    inst.AnimState:PlayAnimation("idle", true)

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetDetachedFn(OnDetached)
    inst.components.debuff.keepondespawn = false

    inst:AddComponent("timer")
    inst.components.timer:StartTimer("decay", DURATION)
    inst:ListenForEvent("timerdone", OnTimerDone)

    return inst
end

return Prefab("flame_guard_buff", fn, assets)