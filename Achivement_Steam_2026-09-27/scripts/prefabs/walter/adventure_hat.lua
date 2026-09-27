require "functions/helperfunctions"

local assets =
{
    Asset("ANIM", "anim/hat_pith.zip"),
    Asset("ATLAS", "images/inventoryimages/hat_pith.xml"),
}

local WATERPROOF = 1
local SPEED = chasni_getitemconfig("adventure_hat", "SPD") or 1.35
local HUNGER = 0.3
local PERISHTIME = TUNING.TOTAL_DAY_TIME * (chasni_getitemconfig("adventure_hat", "DUR") or 3)
local function onequip(inst, owner)
    chasni_unquiprestrictedtag(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "hat_pith", "swap_hat")
    chasni_hatswapequip(owner)

    if inst._task then
        inst._task:Cancel()
        inst._task = nil
    end
    inst._task = inst:DoPeriodicTask(1, function()
        if owner and chasni_hastag(inst, owner) then
            if owner.components.locomotor and owner.components.locomotor.wantstomoveforward then
                inst.components.waterproofer:SetEffectiveness(WATERPROOF)
                inst.components.fueled:StopConsuming()
                owner.components.hunger.burnratemodifiers:SetModifier(inst, HUNGER)
            else
                inst.components.waterproofer:SetEffectiveness(0)
                inst.components.fueled:StartConsuming()
                owner.components.hunger.burnratemodifiers:RemoveModifier(inst)
            end
        else
            inst.components.fueled:StartConsuming()
        end
    end)
end

local function onunequip(inst, owner)
    chasni_hatswapunequip(owner)
    owner.components.hunger.burnratemodifiers:RemoveModifier(inst)
    inst.components.fueled:StopConsuming()

    if inst._task then
        inst._task:Cancel()
        inst._task = nil
    end
end

local function onequiptomodel(inst)
    inst.components.fueled:StopConsuming()
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "med", 0.2, 0.8)

    inst.AnimState:SetBank("pithhat")
    inst.AnimState:SetBuild("hat_pith")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("waterproofer")
    inst:AddTag("adventure_hat")

    inst._restrictedtag = "expertwalter3"

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable:SetOnEquipToModel(onequiptomodel)
    inst.components.equippable.walkspeedmult = SPEED

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "hat_pith"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/hat_pith.xml"

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(0)

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:InitializeFuelLevel(PERISHTIME)
    inst.components.fueled:SetDepletedFn(inst.Remove)

    inst._task = nil
    return inst
end

return Prefab("adventure_hat", fn, assets)