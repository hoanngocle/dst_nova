local assets =
{
    Asset("ANIM", "anim/oar_stopper.zip"),
    Asset("ANIM", "anim/swap_oar_stopper.zip"),
    Asset("ATLAS", "images/inventoryimages/oar_stopper.xml"),
}

local FORCE = 0.3
local DAMAGE = 10
local MAX_VELOCITY = 2
local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_oar_stopper", "swap_oar")

    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("allow_action_on_impassable")
    inst:AddTag("waterproofer")

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "small", 0.2, 0.65)

    inst.AnimState:SetBank("pitchfork")
    inst.AnimState:SetBuild("oar_stopper")
    inst.AnimState:PlayAnimation("idle")

    inst.Transform:SetScale(1.3,1.3,1.3)
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "oar_stopper"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/oar_stopper.xml"

    inst:AddComponent("oar")
    inst.components.oar.force = FORCE
    inst.components.oar.max_velocity = MAX_VELOCITY
    inst.components.oar.stopper = true

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(DAMAGE)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    MakeHauntableLaunch(inst)

    return inst
end

return  Prefab("oar_stopper", fn, assets)
