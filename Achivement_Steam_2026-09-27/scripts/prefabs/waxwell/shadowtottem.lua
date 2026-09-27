local BuffAura = require "prefabs/buffaura_common"

local assets =
{
    Asset("ANIM", "anim/chasni_ghostbanner.zip"),
}

local DURATION = chasni_getitemconfig("healingward", "SPD") or 30
local AURA_RADIUS = 6

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("ghostbanner")
    inst.AnimState:SetBuild("chasni_ghostbanner")
    inst.AnimState:PlayAnimation("pre")
    inst.AnimState:PushAnimation("loop", true)

    inst:AddTag("buffaura")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("buffaura")
    inst.components.buffaura:AddAura("shadowtottem_buff", "shadowtottem_buff", AURA_RADIUS)
    inst:DoTaskInTime(0, function()
        inst.components.buffaura:StartAura()
    end)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:DoTaskInTime(DURATION,function()
        inst.AnimState:PlayAnimation("pst")
        inst:ListenForEvent("animover", function()
            if inst.AnimState:IsCurrentAnimation("pst") then
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
Prefab("shadowtottem", fn, assets),
Prefab("shadowtottem_buff", bufffn)
