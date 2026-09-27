local assets =
{
    Asset("ANIM", "anim/hat_peagawkfeather.zip"),
    Asset("ATLAS", "images/inventoryimages/hat_peagawkfeather.xml"),
}

local MAX_BIRD = chasni_getitemconfig("upgraded_featherhat", "BRD") or 6
local MIN_BIRD_TIME = chasni_getitemconfig("upgraded_featherhat", "MINB") or -4
local MAX_BIRD_TIME = chasni_getitemconfig("upgraded_featherhat", "MAXB") or -12
local SPEED = chasni_getitemconfig("upgraded_featherhat", "SPD") or 1.4
local PERISHTIME = TUNING.TOTAL_DAY_TIME * (chasni_getitemconfig("upgraded_featherhat", "DUR") or 10)
local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "hat_peagawkfeather", "swap_hat")
    chasni_hatswapequip(owner)
    inst.components.fueled:StartConsuming()

    owner:AddTag("upgraded_featherhat")

    local attractor = owner.components.birdattractor
    if attractor then
        attractor.spawnmodifier:SetModifier(inst, MAX_BIRD, "maxbirds")
        attractor.spawnmodifier:SetModifier(inst, MIN_BIRD_TIME, "mindelay")
        attractor.spawnmodifier:SetModifier(inst, MAX_BIRD_TIME, "maxdelay")
        local birdspawner = TheWorld.components.birdspawner
        if birdspawner then
            birdspawner:ToggleUpdate(true)
        end
    end
end

local function onunequip(inst, owner)
    chasni_hatswapunequip(owner)
    inst.components.fueled:StopConsuming()

    owner:RemoveTag("upgraded_featherhat")

    local attractor = owner.components.birdattractor
    if attractor then
        attractor.spawnmodifier:RemoveModifier(inst)
        local birdspawner = TheWorld.components.birdspawner
        if birdspawner then
            birdspawner:ToggleUpdate(true)
        end
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
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("peagawkfeatherhat")
    inst.AnimState:SetBuild("hat_peagawkfeather")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("waterproofer")

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
    inst.components.equippable.dapperness = TUNING.DAPPERNESS_SUPERHUGE

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "hat_peagawkfeather"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/hat_peagawkfeather.xml"

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.USAGE
    inst.components.fueled:InitializeFuelLevel(PERISHTIME)
    inst.components.fueled:SetDepletedFn(inst.Remove)

    return inst
end

return Prefab("upgraded_featherhat", fn, assets)