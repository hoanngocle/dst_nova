local BuffAura = require "prefabs/buffaura_common"

local assets =
{
    Asset("ANIM", "anim/chasni_scoutbadges.zip"),
    Asset("ATLAS", "images/inventoryimages/chasni_scoutbadges_attack.xml"),
}

local prefabs =
{
    "chasni_scoutbadges_attack_buff",
}

local AURA_RADIUS = 6
local ATTACK_MULT = 1.25
local function OnPutInInventory(inst, owner)
    if owner and owner:IsValid() and owner.components.container and owner.components.locomotor then
        inst.components.buffaura:StartAura()
    else
        inst.components.buffaura:StopAura()
    end
end

local function OnDropped(inst)
    inst.components.buffaura:StopAura()
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBank("chasni_scoutbadges")
    inst.AnimState:SetBuild("chasni_scoutbadges")
    inst.AnimState:PlayAnimation("badge_attack")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", 0.2, 0.8)

    inst:AddTag("buffaura")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "chasni_scoutbadges_attack"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/chasni_scoutbadges_attack.xml"

    inst:AddComponent("buffaura")
    inst.components.buffaura:AddAura("chasni_scoutbadges_attack_buff", "chasni_scoutbadges_attack_buff", AURA_RADIUS)

    inst:ListenForEvent("onputininventory", OnPutInInventory)
    inst:ListenForEvent("ondropped", OnDropped)

    return inst
end

local function bufffn()
    local buffdata =
    {
        ONATTACH = function(inst, target)
            if target.components.combat then
                target.components.combat.externaldamagemultipliers:SetModifier(inst, ATTACK_MULT)
            end
        end,
        ONDETACH = function(inst, target)
            if target.components.combat then
                target.components.combat.externaldamagemultipliers:RemoveModifier(inst)
            end
        end,
        ATTACH_FX = "chasni_scoutbadges_attack_onfx",
        DETACH_FX = "chasni_scoutbadges_attack_offfx",
        fxscale = 2.5,
        yoffset = 3,
    }
    local inst = BuffAura.common_fn(buffdata)

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

return
Prefab("chasni_scoutbadges_attack", fn, assets, prefabs),
Prefab("chasni_scoutbadges_attack_buff", bufffn)