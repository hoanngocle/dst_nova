local BuffAura = require "prefabs/buffaura_common"

local assets =
{
    Asset("ANIM", "anim/chasni_shadow_channeler.zip"),
}

local DURATION = chasni_getitemconfig("healingward", "SPD") or 60
local AURA_RADIUS = 6

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("shadow_channeler")
    inst.AnimState:SetBuild("chasni_shadow_channeler")
    inst.AnimState:PlayAnimation("appear")
    inst.AnimState:PushAnimation("idle", true)

    inst:AddTag("buffaura")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("buffaura")
    inst.components.buffaura:AddAura("shadowrealm_buff", "shadowrealm_buff", AURA_RADIUS)
    inst:DoTaskInTime(0, function()
        inst.components.buffaura:StartAura()
    end)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:DoTaskInTime(DURATION,function()
        inst.AnimState:PushAnimation("disappear")
        inst:ListenForEvent("animover", function()
            if inst.AnimState:IsCurrentAnimation("disappear") then
                inst:Remove()
            end
        end)
    end)

    inst.persists = false

    return inst
end

local function bufffn()
    local inst = BuffAura.common_fn({})

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return
Prefab("shadowrealm", fn, assets),
Prefab("shadowrealm_buff", bufffn)